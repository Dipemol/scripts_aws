# Nombre de la instancia (Reemplaza por tu ID de instancia o nombre)
EC2_ID="i-0d4c0829fd370e4ab"

# Verificar si la instancia existe
echo "Comprobando si la instancia $EC2_ID existe..."
EC2_EXISTE=$(aws ec2 describe-instances --instance-ids $EC2_ID --query "Reservations[].Instances[].InstanceId" --output text)

if [[ "$EC2_EXISTE" == "None" ]]; then
    echo "La instancia $EC2_ID no existe. Abortando el proceso."
    exit 1
fi

# Obtener el estado de la instancia
EC2_ESTADO=$(aws ec2 describe-instances --instance-ids $EC2_ID --query "Reservations[].Instances[].State.Name" --output text)

# Si la instancia está en ejecución, la detenemos
if [[ "$EC2_ESTADO" == "running" ]]; then
    echo "La instancia $EC2_ID está en ejecución. ¿Deseas detenerla? (s/n)"
    read -p "Opción: " user_input

    if [[ "$user_input" == "s" || "$user_input" == "S" ]]; then
        # Parar la instancia
        echo "Deteniendo la instancia $EC2_ID..."
        aws ec2 stop-instances --instance-ids $EC2_ID
        
        # Esperar a que la instancia se detenga
        aws ec2 wait instance-stopped --instance-ids $EC2_ID
        echo "La instancia $EC2_ID ha sido detenida."
    else
        echo "Proceso abortado por el usuario."
        exit 0
    fi
else
    echo "La instancia no está en ejecución, procediendo con el cambio de tipo."
fi

# Obtener el tipo actual de la instancia
EC2_TYPE=$(aws ec2 describe-instances --instance-ids $EC2_ID --query "Reservations[].Instances[].InstanceType" --output text)
NUEVO_EC2_TYPE="t2.micro"

# Comprobar si el tipo de instancia es el mismo
if [[ "$EC2_TYPE" == "$NUEVO_EC2_TYPE" ]]; then
    echo "El tipo de instancia actual ya es $NUEVO_EC2_TYPE. No se realizará ningún cambio."
    exit 0
fi

# Cambiar el tipo de instancia
echo "Cambiando el tipo de la instancia $EC2_ID a $NUEVO_EC2_TYPE..."
aws ec2 modify-instance-attribute --instance-id $EC2_ID --instance-type "{\"Value\":\"$NUEVO_EC2_TYPE\"}"

# Arrancar la instancia
echo "Arrancando la instancia $EC2_ID..."
aws ec2 start-instances --instance-ids $EC2_ID

# Esperar a que la instancia se arranque
aws ec2 wait instance-running --instance-ids $EC2_ID
echo "La instancia $EC2_ID está ahora en ejecución con el nuevo tipo $NUEVO_EC2_TYPE."

# Confirmación final
echo "Proceso completado exitosamente. La instancia $EC2_ID ahora está ejecutándose con el tipo $NUEVO_EC2_TYPE."
