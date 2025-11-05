set -euo pipefail

# --- Parámetros ---
REGION_ORIGEN=$1
INSTANCE_ID=$2
REGION_DESTINO=$3

# --- Validación de parámetros ---
if [ $# -ne 3 ]; then
  echo "Uso: $0 <region_origen> <id_instancia_origen> <region_destino>"
  exit 1
fi

echo "=== Comprobando existencia de la instancia $INSTANCE_ID en $REGION_ORIGEN ==="
INSTANCE_EXISTS=$(aws ec2 describe-instances \
  --region "$REGION_ORIGEN" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text 2>/dev/null || true)

if [ -z "$INSTANCE_EXISTS" ]; then
  echo "❌ La instancia $INSTANCE_ID no existe en la región $REGION_ORIGEN"
  exit 1
fi

# --- Obtener información de la instancia ---
echo "=== Obteniendo información de la instancia origen ==="
INSTANCE_TYPE=$(aws ec2 describe-instances \
  --region "$REGION_ORIGEN" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].InstanceType' \
  --output text)

VOLUME_SIZE=$(aws ec2 describe-instances \
  --region "$REGION_ORIGEN" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' \
  --output text | \
  xargs -I{} aws ec2 describe-volumes \
  --region "$REGION_ORIGEN" \
  --volume-ids {} \
  --query 'Volumes[0].Size' \
  --output text)

# --- Crear imagen AMI de la instancia origen ---
AMI_NAME="copy-${INSTANCE_ID}-$(date +%Y%m%d%H%M%S)"
echo "=== Creando imagen AMI de la instancia origen ($AMI_NAME) ==="
AMI_ID=$(aws ec2 create-image \
  --region "$REGION_ORIGEN" \
  --instance-id "$INSTANCE_ID" \
  --name "$AMI_NAME" \
  --no-reboot \
  --query 'ImageId' \
  --output text)

echo "Esperando a que la imagen $AMI_ID esté disponible..."
aws ec2 wait image-available --region "$REGION_ORIGEN" --image-ids "$AMI_ID"
echo "✅ Imagen $AMI_ID disponible en $REGION_ORIGEN"

# --- Copiar imagen a la región destino ---
echo "=== Copiando imagen a la región destino $REGION_DESTINO ==="
AMI_COPY_ID=$(aws ec2 copy-image \
  --source-region "$REGION_ORIGEN" \
  --source-image-id "$AMI_ID" \
  --region "$REGION_DESTINO" \
  --name "${AMI_NAME}-copy" \
  --query 'ImageId' \
  --output text)

echo "Esperando a que la imagen copiada $AMI_COPY_ID esté disponible..."
aws ec2 wait image-available --region "$REGION_DESTINO" --image-ids "$AMI_COPY_ID"
echo "✅ Imagen copiada $AMI_COPY_ID disponible en $REGION_DESTINO"

# --- Crear un nuevo par de claves en la región destino ---
KEY_NAME="keypair-${INSTANCE_ID}-$(date +%Y%m%d%H%M%S)"
echo "=== Creando par de claves $KEY_NAME en $REGION_DESTINO ==="
aws ec2 create-key-pair \
  --region "$REGION_DESTINO" \
  --key-name "$KEY_NAME" \
  --query 'KeyMaterial' \
  --output text > "${KEY_NAME}.pem"
chmod 400 "${KEY_NAME}.pem"
echo "✅ Par de claves creado y guardado como ${KEY_NAME}.pem"

# --- Obtener la VPC, subred y SG por defecto ---
VPC_ID=$(aws ec2 describe-vpcs --region "$REGION_DESTINO" --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
SUBNET_ID=$(aws ec2 describe-subnets --region "$REGION_DESTINO" --filters "Name=vpc-id,Values=$VPC_ID" "Name=default-for-az,Values=true" --query 'Subnets[0].SubnetId' --output text)
SG_ID=$(aws ec2 describe-security-groups --region "$REGION_DESTINO" --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" --query 'SecurityGroups[0].GroupId' --output text)

# --- Lanzar nueva instancia en la región destino ---
echo "=== Lanzando nueva instancia en $REGION_DESTINO ==="
NEW_INSTANCE_ID=$(aws ec2 run-instances \
  --region "$REGION_DESTINO" \
  --image-id "$AMI_COPY_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SG_ID" \
  --block-device-mappings "[{\"DeviceName\":\"/dev/xvda\",\"Ebs\":{\"VolumeSize\":${VOLUME_SIZE},\"DeleteOnTermination\":true}}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Esperando a que la nueva instancia ($NEW_INSTANCE_ID) esté en estado 'running'..."
aws ec2 wait instance-running --region "$REGION_DESTINO" --instance-ids "$NEW_INSTANCE_ID"
echo "✅ Nueva instancia creada exitosamente: $NEW_INSTANCE_ID en $REGION_DESTINO"

# --- Eliminar AMIs creadas ---
echo "=== Eliminando AMIs temporales ==="
aws ec2 deregister-image --region "$REGION_ORIGEN" --image-id "$AMI_ID"
aws ec2 deregister-image --region "$REGION_DESTINO" --image-id "$AMI_COPY_ID"
echo "✅ AMIs eliminadas correctamente."

echo "=== Proceso completado exitosamente ==="
echo "Nueva instancia: $NEW_INSTANCE_ID"
echo "Clave privada: ${KEY_NAME}.pem"
