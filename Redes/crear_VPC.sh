VPC_ID=$(aws ec2 create-vpc --cidr-block 192.168.0.0/24 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=entorno,Value=prueba}]' \
    --query Vpc.VpcId --output text)

SUB_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block  192.168.0.0/28 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=entorno,Value=prueba}]' \
    --query Subnet.SubnetId --output text)

aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block  192.168.0.16/28 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=entorno,Value=prueba}]' \
    --query Subnet.SubnetId --output text

EC2_ID=$(aws ec2 run-instances \
    --image-id ami-0360c520857e3138f \
    --instance-type t2.micro \
    --key-name vockey \
    --subnet-id $SUB_ID \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=pruebas}]' \
    --query Instances.InstanceId --output text)