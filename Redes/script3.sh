#creo la vpc y devuelvo su id
VPC_ID=$(aws ec2 create-vpc --cidr-block 172.16.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=vpcdiego}]' \
    --query Vpc.VpcId --output text)

#Creo el Gateway https://docs.aws.amazon.com/cli/latest/reference/ec2/create-internet-gateway.html
IG_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=igw-vpcdiego}]' \
    --query InternetGateway.InternetGatewayId --output text)

#Asociamos el Gateway a la VPC https://docs.aws.amazon.com/es_es/ec2/latest/devguide/example_ec2_AttachInternetGateway_section.html
aws ec2 attach-internet-gateway \
    --internet-gateway-id $IG_ID \
    --vpc-id $VPC_ID


#muestro la vpcid que he creado
echo id de la vpc
echo $VPC_ID

#habilitar dns en la vpc
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames "{\"Value\":true}"

#creo la subnet y devuelvo su id
SUB_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block  172.16.0.0/20 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=mi-subred1-diego}]' \
    --query Subnet.SubnetId --output text)

#muestra el id de la subnet
echo Id de la subnet
echo $SUB_ID

#habilito la asignacion de ipv4 publica en la subred
aws ec2 modify-subnet-attribute --subnet-id $SUB_ID --map-public-ip-on-launch

#creo grupo de seguridad
SG_ID=$(aws ec2 create-security-group --vpc-id $VPC_ID \
    --group-name sgpractica \
    --description "Mi grupo de seguridad para abrir el puerto 22" \
    --query GroupId \
    --output text)

echo Id del grupo de seguridad
echo $SG_ID

#modifico las reglas de entrada del grupo de seguridad
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --ip-permissions '[{"IpProtocol":"tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "AllowSSH"}]}]'

#creo un ec2
EC2_ID=$(aws ec2 run-instances \
    --image-id ami-0360c520857e3138f \
    --instance-type t3.micro \
    --key-name vockey \
    --subnet-id $SUB_ID \
    --security-group-ids $SG_ID \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ec2gateway}]' \
    --query Instances.InstanceId --output text)