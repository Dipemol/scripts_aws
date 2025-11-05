# Creamos un grupo de seguridad específico para las instancias
SG_ID=$(aws ec2 create-security-group --description balanceador \
    --group-name sgbalanceador \
    --vpc-id vpc-021530e9e2ce095c9 \
    --query GroupId \
    --output text)

echo sgid = $SG_ID

# Añadimos las reglas de salida HTTP y HTTPS al grupo de seguridad
aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

aws ec2 modify-instance-attribute --instance-id i-0f4fa4d5f4bdab506 \
    --groups $SG_ID
aws ec2 modify-instance-attribute --instance-id i-0d3f494bba5043a10 \
    --groups $SG_ID

TGA=$(aws elbv2 create-target-group --name tg-bg \
    --protocol HTTP \
    --port 80 \
    --vpc-id vpc-021530e9e2ce095c9 \
    --target-type instance \
    --query TargetGroups[0].TargetGroupArn \
    --output text)

echo arn del target type = $TGA

aws elbv2 register-targets \
    --target-group-arn $TGA \
    --targets Id=i-0f4fa4d5f4bdab506 Id=i-0d3f494bba5043a10

LBA=$(aws elbv2 create-load-balancer \
  --name lb-bg \
  --subnets subnet-0c4548021af8dbfb7 subnet-02269dce088fc3d3e \
  --security-groups $SG_ID \
  --query LoadBalancers[0].LoadBalancerArn \
  --output text)

echo load balancer arn = $LBA

aws elbv2 create-listener \
  --load-balancer-arn $LBA \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TGA
