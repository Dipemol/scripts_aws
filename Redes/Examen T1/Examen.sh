VPC_ID=$(aws ec2 create-vpc --cidr-block 10.10.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=VpcExamen}]' \
    --query Vpc.VpcId --output text)

echo VPC ID: $VPC_ID

IG_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=igw-Examen}]' \
    --query InternetGateway.InternetGatewayId --output text)

echo Internet Gateway ID: $IG_ID

aws ec2 attach-internet-gateway \
    --internet-gateway-id $IG_ID \
    --vpc-id $VPC_ID

SUBPU_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block  10.10.1.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Publica1}]' \
    --query Subnet.SubnetId --output text)

echo Subred pública 1: $SUBPU_ID

SUBPU2_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block  10.10.2.0/24 \
    --availability-zone us-east-1d \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Publica2}]' \
    --query Subnet.SubnetId --output text)

echo Subred pública 2: $SUBPU2_ID

RTPU_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID \
    --query RouteTable.RouteTableId --output text)

aws ec2 create-route --route-table-id $RTPU_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IG_ID

aws ec2 modify-subnet-attribute --subnet-id $SUBPU_ID --map-public-ip-on-launch

aws ec2 associate-route-table --route-table-id $RTPU_ID --subnet-id $SUBPU_ID

RTPU2_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID \
    --query RouteTable.RouteTableId --output text)

aws ec2 create-route --route-table-id $RTPU2_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IG_ID

aws ec2 modify-subnet-attribute --subnet-id $SUBPU2_ID --map-public-ip-on-launch

aws ec2 associate-route-table --route-table-id $RTPU2_ID --subnet-id $SUBPU2_ID

SUBPR_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block  10.10.3.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Privada1}]' \
    --query Subnet.SubnetId --output text)

echo Subred privada 1: $SUBPR_ID

SUBPR2_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block  10.10.4.0/24 \
    --availability-zone us-east-1d \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Privada2}]' \
    --query Subnet.SubnetId --output text)

echo Subred privada 2: $SUBPR2_ID

ALLO_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)

echo Espera unos segundos hasta que finalice la creación del Nat Gateway...
NG_ID=$(aws ec2 create-nat-gateway --subnet-id $SUBPU_ID --allocation-id $ALLO_ID --query NatGateway.NatGatewayId --output text)

aws ec2 wait nat-gateway-available --nat-gateway-ids $NG_ID

echo Nat Gateway ID: $NG_ID

RTPR_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID \
    --query RouteTable.RouteTableId --output text)

aws ec2 create-route --route-table-id $RTPR_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NG_ID

aws ec2 associate-route-table --route-table-id $RTPR_ID --subnet-id $SUBPR_ID

RTPR2_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID \
    --query RouteTable.RouteTableId --output text)

aws ec2 create-route --route-table-id $RTPR2_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NG_ID

aws ec2 associate-route-table --route-table-id $RTPR2_ID --subnet-id $SUBPR2_ID

SG_ID=$(aws ec2 create-security-group --vpc-id $VPC_ID \
    --group-name sgExamen \
    --description "sgExamen" \
    --query GroupId \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --ip-permissions '[{"IpProtocol":"tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "AllowSSH"}]}]'

PUBLIC_NACL_ID=$(aws ec2 create-network-acl \
  --vpc-id $VPC_ID \
  --query 'NetworkAcl.NetworkAclId' \
  --output text)

echo $PUBLIC_NACL_ID

ASSOC_ID=$(aws ec2 describe-network-acls \
  --filters Name=association.subnet-id,Values=$SUBPU_ID \
  --query 'NetworkAcls[0].Associations[0].NetworkAclAssociationId' \
  --output text)

ASSOC2_ID=$(aws ec2 describe-network-acls \
  --filters Name=association.subnet-id,Values=$SUBPU2_ID \
  --query 'NetworkAcls[0].Associations[0].NetworkAclAssociationId' \
  --output text)

aws ec2 replace-network-acl-association \
    --association-id $ASSOC_ID \
    --network-acl-id $PUBLIC_NACL_ID

aws ec2 replace-network-acl-association \
    --association-id $ASSOC2_ID \
    --network-acl-id $PUBLIC_NACL_ID


PRIVATE_NACL_ID=$(aws ec2 create-network-acl \
  --vpc-id $VPC_ID \
  --query 'NetworkAcl.NetworkAclId' \
  --output text)

echo $PRIVATE_NACL_ID

ASSOC3_ID=$(aws ec2 describe-network-acls \
  --filters Name=association.subnet-id,Values=$SUBPR_ID \
  --query 'NetworkAcls[0].Associations[0].NetworkAclAssociationId' \
  --output text)

ASSOC4_ID=$(aws ec2 describe-network-acls \
  --filters Name=association.subnet-id,Values=$SUBPR2_ID \
  --query 'NetworkAcls[0].Associations[0].NetworkAclAssociationId' \
  --output text)

aws ec2 replace-network-acl-association \
    --association-id $ASSOC3_ID \
    --network-acl-id $PRIVATE_NACL_ID

aws ec2 replace-network-acl-association \
    --association-id $ASSOC4_ID \
    --network-acl-id $PRIVATE_NACL_ID

aws ec2 delete-network-acl-entry \
  --network-acl-id $PUBLIC_NACL_ID \
  --ingress --rule-number 100

aws ec2 delete-network-acl-entry \
  --network-acl-id $PUBLIC_NACL_ID \
  --egress --rule-number 100

aws ec2 create-network-acl-entry \
  --network-acl-id $PUBLIC_NACL_ID \
  --rule-number 120 \
  --protocol tcp \
  --port-range From=22,To=22 \
  --egress false \
  --cidr-block 0.0.0.0/0 \
  --rule-action allow

aws ec2 create-network-acl-entry \
  --network-acl-id $PUBLIC_NACL_ID \
  --rule-number 110 \
  --protocol tcp \
  --port-range From=443,To=443 \
  --egress false \
  --cidr-block 0.0.0.0/0 \
  --rule-action allow

aws ec2 create-network-acl-entry \
  --network-acl-id $PUBLIC_NACL_ID \
  --rule-number 100 \
  --protocol tcp \
  --port-range From=80,To=80 \
  --egress false \
  --cidr-block 0.0.0.0/0 \
  --rule-action allow

aws ec2 create-network-acl-entry \
  --network-acl-id $PUBLIC_NACL_ID \
  --rule-number 32767 \
  --protocol -1 \
  --egress false \
  --cidr-block 0.0.0.0/0 \
  --rule-action deny

aws ec2 create-network-acl-entry \
  --network-acl-id $PRIVATE_NACL_ID \
  --rule-number 100 \
  --protocol -1 \
  --port-range From=0,To=65535 \
  --egress false \
  --cidr-block 10.10.0.0/16 \
  --rule-action allow

aws ec2 create-network-acl-entry \
  --network-acl-id $PRIVATE_NACL_ID \
  --rule-number 32767 \
  --protocol -1 \
  --egress false \
  --cidr-block 0.0.0.0/0 \
  --rule-action deny

EC2_ID_Publica=$(aws ec2 run-instances \
    --image-id ami-0360c520857e3138f \
    --instance-type t2.micro \
    --key-name vockey \
    --subnet-id $SUBPU_ID \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Publica1}]' \
    --query Instances.InstanceId --output text)

EC2_ID_Publica2=$(aws ec2 run-instances \
    --image-id ami-0360c520857e3138f \
    --instance-type t2.micro \
    --key-name vockey \
    --subnet-id $SUBPU2_ID \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Publica2}]' \
    --query Instances.InstanceId --output text)

EC2_ID_Privada=$(aws ec2 run-instances \
    --image-id ami-0360c520857e3138f \
    --instance-type t2.micro \
    --key-name vockey \
    --subnet-id $SUBPR_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Privada}]' \
    --query Instances.InstanceId --output text)

EC2_ID_Privada2=$(aws ec2 run-instances \
    --image-id ami-0360c520857e3138f \
    --instance-type t2.micro \
    --key-name vockey \
    --subnet-id $SUBPR2_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Privada2}]' \
    --query Instances.InstanceId --output text)