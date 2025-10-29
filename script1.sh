#creo la vpc y devuelvo su id
VPC_ID=$(aws ec2 create-vpc --cidr-block 192.168.1.0/24 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=vpcdiego}]' \
    --query Vpc.VpcId --output text)

#muestro la vpcid que he creado
echo $VPC_ID

#habilitar dns en la vpc
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames "{\"Value\":true}"

#creo la subnet y devuelvo su id
SUB_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 192.168.1.0/28 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=mi-subred1-diego}]' \
    --query Subnet.SubnetId --output text)

#muestra el id de la subnet
echo $SUB_ID

#habilito la asignacion de ipv4 publica en la subred
#comprobar NO se habilita y tenemos que hacerlo a posteriori
aws ec2 modify-subnet-attribute --subnet-id $SUB_ID --map-public-ip-on-launch