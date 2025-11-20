VPC_ID=$(aws ec2 create-vpc --cidr-block 172.16.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=EjercicioCli}]' \
    --query Vpc.VpcId --output text)

aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames "{\"Value\":true}"

SUBPU_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block  172.16.0.0/24 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=EjercicioCliPublica}]' \
    --query Subnet.SubnetId --output text)

IG_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=igw-EjercicioCLI}]' \
    --query InternetGateway.InternetGatewayId --output text)

aws ec2 attach-internet-gateway \
    --internet-gateway-id $IG_ID \
    --vpc-id $VPC_ID

RTPU_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID \
    --query RouteTable.RouteTableId --output text)

aws ec2 create-route --route-table-id $RTPU_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IG_ID

aws ec2 modify-subnet-attribute --subnet-id $SUBPU_ID --map-public-ip-on-launch

aws ec2 associate-route-table --route-table-id $RTPU_ID --subnet-id $SUBPU_ID

SUBPR_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block  172.16.128.0/24 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=EjercicioCliPrivada}]' \
    --query Subnet.SubnetId --output text)

aws ec2 create-nat-gateway --subnet-id $SUBPU_ID --allocation-id 

RTPR_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID \
    --query RouteTable.RouteTableId --output text)

aws ec2 create-route --route-table-id $RTPR_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGPR_ID

aws ec2 modify-subnet-attribute --subnet-id $SUBPR_ID --map-public-ip-on-launch

aws ec2 associate-route-table --route-table-id $RTPR_ID --subnet-id $SUBPR_ID

SG_ID=$(aws ec2 create-security-group --vpc-id $VPC_ID \
    --group-name sgpractica \
    --description "sgEjerciciocli" \
    --query GroupId \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --ip-permissions '[{"IpProtocol":"tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "AllowSSH"}]}]'

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol icmp \
    --port 0-65535 \
    --cidr 0.0.0.0/0


EC2_ID=$(aws ec2 run-instances \
    --image-id ami-0360c520857e3138f \
    --instance-type t2.micro \
    --key-name vockey \
    --subnet-id $SUBPU_ID \
    --security-group-ids $SG_ID \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EJERCICIOCLIPrivada}]' \
    --query Instances.InstanceId --output text)

EC2_ID2=$(aws ec2 run-instances \
    --image-id ami-0360c520857e3138f \
    --instance-type t2.micro \
    --key-name vockey \
    --subnet-id $SUBPR_ID \
    --security-group-ids $SG_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EJERCICIOCLIPublica}]' \
    --query Instances.InstanceId --output text)
