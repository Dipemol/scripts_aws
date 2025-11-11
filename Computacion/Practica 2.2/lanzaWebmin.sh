SG_ID=$(aws ec2 create-security-group --vpc-id vpc-0c908259a25f18fd1 \
    --group-name sgwebmin2 \
    --description "Mi grupo de seguridad para webmin" \
    --query GroupId \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --ip-permissions '[{"IpProtocol":"tcp", "FromPort": 21, "ToPort": 21, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": ""}]}]'

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --ip-permissions '[{"IpProtocol":"tcp", "FromPort": 10000, "ToPort": 10000, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": ""}]}]'

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --ip-permissions '[{"IpProtocol":"tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": ""}]}]'

aws ec2 run-instances \
    --image-id ami-0360c520857e3138f \
    --instance-type t3.micro \
    --key-name vockey \
    --security-group-ids $SG_ID \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EC2Webmin}]' \
    --user-data file://installwebmin.txt \
    --query Instances[0].InstanceId --output text