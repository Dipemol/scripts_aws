#Creo la VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 172.16.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=EjercicioCli}]' \
    --query Vpc.VpcId --output text)

echo ID de la VPC: $VPC_ID

#Habilito los nombres del host DNS y la resolucion de DNS en la VPC
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames "{\"Value\":true}"

#Creo la subnet pública
SUBPU_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block  172.16.0.0/24 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=EjercicioCliPublica}]' \
    --query Subnet.SubnetId --output text)

echo ID de la subnet pública: $SUBPU_ID

#Creo un Internet Gateway para la subnet pública
IG_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=igw-EjercicioCLI}]' \
    --query InternetGateway.InternetGatewayId --output text)

echo ID de la Internet Gateway: $IG_ID

#Le asigno el internet gateway a la vpc
aws ec2 attach-internet-gateway \
    --internet-gateway-id $IG_ID \
    --vpc-id $VPC_ID

#Creo una tabla de rutas
RTPU_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID \
    --query RouteTable.RouteTableId --output text)

#Creo una ruta desde la subnet publica a la internet gateway
aws ec2 create-route --route-table-id $RTPU_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IG_ID

aws ec2 modify-subnet-attribute --subnet-id $SUBPU_ID --map-public-ip-on-launch

aws ec2 associate-route-table --route-table-id $RTPU_ID --subnet-id $SUBPU_ID

#Creo la subnet privada
SUBPR_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block  172.16.128.0/24 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=EjercicioCliPrivada}]' \
    --query Subnet.SubnetId --output text)

#Creo una Allocation address para la Nat Gateway que crearemos
ALLO_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)

echo id de la address allocation: $ALLO_ID

#Creo una Nat Gateway
NG_ID=$(aws ec2 create-nat-gateway --subnet-id $SUBPU_ID --allocation-id $ALLO_ID --query NatGateway.NatGatewayId --output text)

#Espero a que se cree la Nat Gateway
aws ec2 wait nat-gateway-available --nat-gateway-ids $NG_ID

echo Espera unos segundos hasta que finalice la creación del Nat Gateway...
echo Nat Gateway ID: $NG_ID

#Creo una tabla de rutas para la subnet privada
RTPR_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID \
    --query RouteTable.RouteTableId --output text)

#Creo una ruta desde la subnet privada a la Nat Gateway
aws ec2 create-route --route-table-id $RTPR_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NG_ID

aws ec2 associate-route-table --route-table-id $RTPR_ID --subnet-id $SUBPR_ID

#Creo el grupo de seguridad
SG_ID=$(aws ec2 create-security-group --vpc-id $VPC_ID \
    --group-name sgpractica \
    --description "sgEjerciciocli" \
    --query GroupId \
    --output text)

#Agrego reglas de entrada SSH y ICMP al grupo de seguridad
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --ip-permissions '[{"IpProtocol":"tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "AllowSSH"}]}]'

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol icmp \
    --port 0 \
    --cidr 0.0.0.0/0

#Creo 2 instancias, 1 en la subnet privada y otra en la subnet pública
EC2_ID=$(aws ec2 run-instances \
    --image-id ami-0360c520857e3138f \
    --instance-type t2.micro \
    --key-name vockey \
    --subnet-id $SUBPU_ID \
    --security-group-ids $SG_ID \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EJERCICIOCLIPublica}]' \
    --query Instances.InstanceId --output text)

EC2_ID2=$(aws ec2 run-instances \
    --image-id ami-0360c520857e3138f \
    --instance-type t2.micro \
    --key-name vockey \
    --subnet-id $SUBPR_ID \
    --security-group-ids $SG_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EJERCICIOCLIPrivada}]' \
    --query Instances.InstanceId --output text)
