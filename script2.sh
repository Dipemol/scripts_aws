aws ec2 create-vpc --cidr-block 192.168.0.0/24 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=vpcdiego}]'

aws ec2 modify-vpc-attribute --vpc-id "preview-vpc-1234" \
    --enable-dns-hostnames '{"value":true}'

aws ec2 describe-vpcs --vpc-ids "preview-vpc-1234"

aws ec2 create-subnet --vpc-id "preview-vpc-1234" \
    --cidr-block "192.168.0.0/28" \
    --availability-zone "us-east-1a" \
    --tag-specifications '{"resourceType":"subnet","tags":[{"key":"Name","value":"subred1vpcdiego"}]}'

aws ec2 attach-internet-gateway --internet-gateway-id "preview-igw-1234" \
    --vpc-id "preview-vpc-1234"

aws ec2 create-route-table --vpc-id "preview-vpc-1234" \
    --tag-specifications '{"resourceType":"route-table","tags":[{"key":"Name","value":"vpcdiego-rtb-public"}]}'

aws ec2 create-route --route-table-id "preview-rtb-public-0" \
    --destination-cidr-block "0.0.0.0/0" \
    --gateway-id "preview-igw-1234"

aws ec2 associate-route-table --route-table-id "preview-rtb-public-0" \
    --subnet-id "preview-subnet-public-0"

aws ec2 describe-route-tables