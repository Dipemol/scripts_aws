aws ec2 create-vpc --cidr-block 192.168.0.0/24 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=vpcdiego}]' \
    --query Vpc.VpcId --output text