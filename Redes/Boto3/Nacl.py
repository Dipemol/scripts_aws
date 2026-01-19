import boto3
import time

ec2 = boto3.client('ec2')
ec2r = boto3.resource('ec2')


def associate_nacl_to_subnet(ec2, subnet_id, nacl_id):
    response = ec2.describe_network_acls(
        Filters=[{'Name': 'association.subnet-id', 'Values': [subnet_id]}]
    )
    association_id = response['NetworkAcls'][0]['Associations'][0]['NetworkAclAssociationId']
    ec2.replace_network_acl_association(
        AssociationId=association_id,
        NetworkAclId=nacl_id
    )


def main():

    # 1) VPC
    print("Creando VPC...")
    vpc = ec2.create_vpc(CidrBlock='10.0.0.0/16')
    vpc_id = vpc['Vpc']['VpcId']

    ec2.modify_vpc_attribute(VpcId=vpc_id, EnableDnsSupport={'Value': True})
    ec2.modify_vpc_attribute(VpcId=vpc_id, EnableDnsHostnames={'Value': True})

    # 2) Subred pública y privada
    print("Creando subredes...")
    public_subnet = ec2.create_subnet(
        VpcId=vpc_id,
        CidrBlock='10.0.1.0/24'
    )
    private_subnet = ec2.create_subnet(
        VpcId=vpc_id,
        CidrBlock='10.0.2.0/24'
    )

    public_subnet_id = public_subnet['Subnet']['SubnetId']
    private_subnet_id = private_subnet['Subnet']['SubnetId']

    # 3) Internet Gateway
    print("Creando Internet Gateway...")
    igw = ec2.create_internet_gateway()
    igw_id = igw['InternetGateway']['InternetGatewayId']
    ec2.attach_internet_gateway(InternetGatewayId=igw_id, VpcId=vpc_id)

    # 4) Route table pública
    print("Configurando rutas públicas...")
    public_rt = ec2.create_route_table(VpcId=vpc_id)
    public_rt_id = public_rt['RouteTable']['RouteTableId']

    ec2.create_route(
        RouteTableId=public_rt_id,
        DestinationCidrBlock='0.0.0.0/0',
        GatewayId=igw_id
    )

    ec2.associate_route_table(
        RouteTableId=public_rt_id,
        SubnetId=public_subnet_id
    )

    # 5) NAT Gateway (en subred pública)
    print("Creando NAT Gateway...")
    eip = ec2.allocate_address(Domain='vpc')
    allocation_id = eip['AllocationId']

    nat = ec2.create_nat_gateway(
        SubnetId=public_subnet_id,
        AllocationId=allocation_id
    )
    nat_id = nat['NatGateway']['NatGatewayId']

    print("Esperando a que el NAT Gateway esté disponible...")
    waiter = ec2.get_waiter('nat_gateway_available')
    waiter.wait(NatGatewayIds=[nat_id])

    # 6) Route table privada → NAT Gateway
    print("Configurando rutas privadas...")
    private_rt = ec2.create_route_table(VpcId=vpc_id)
    private_rt_id = private_rt['RouteTable']['RouteTableId']

    ec2.create_route(
        RouteTableId=private_rt_id,
        DestinationCidrBlock='0.0.0.0/0',
        NatGatewayId=nat_id
    )

    ec2.associate_route_table(
        RouteTableId=private_rt_id,
        SubnetId=private_subnet_id
    )

    # 7) Network ACL
    print("Creando Network ACL...")
    nacl = ec2.create_network_acl(VpcId=vpc_id)
    nacl_id = nacl['NetworkAcl']['NetworkAclId']

    # ICMP entrante permitido
    ec2.create_network_acl_entry(
        NetworkAclId=nacl_id,
        RuleNumber=100,
        Protocol='1',
        RuleAction='allow',
        Egress=False,
        CidrBlock='0.0.0.0/0',
        IcmpTypeCode={'Type': -1, 'Code': -1}
    )

    # Bloquear ICMP saliente
    ec2.create_network_acl_entry(
        NetworkAclId=nacl_id,
        RuleNumber=100,
        Protocol='1',
        RuleAction='deny',
        Egress=True,
        CidrBlock='0.0.0.0/0'
        IcmpTypeCode={'Type': -1, 'Code': -1}
    )

    associate_nacl_to_subnet(ec2, public_subnet_id, nacl_id)
    associate_nacl_to_subnet(ec2, private_subnet_id, nacl_id)

    # 8) Security Group
    print("Creando Security Group...")
    sg = ec2.create_security_group(
        GroupName='SG-MiInstancia',
        Description='Allow SSH and HTTP',
        VpcId=vpc_id
    )
    sg_id = sg['GroupId']

    ec2.authorize_security_group_ingress(
        GroupId=sg_id,
        IpPermissions=[
            {'IpProtocol': 'tcp', 'FromPort': 22, 'ToPort': 22,
             'IpRanges': [{'CidrIp': '0.0.0.0/0'}]},
            {'IpProtocol': 'tcp', 'FromPort': 80, 'ToPort': 80,
             'IpRanges': [{'CidrIp': '0.0.0.0/0'}]},
        ]
    )

    # 9) EC2 (en subred privada)
    print("Lanzando instancia EC2...")
    instances = ec2r.create_instances(
        ImageId='ami-0c94855ba95c71c99',  # AJUSTAR REGIÓN
        InstanceType='t2.micro',
        MinCount=1,
        MaxCount=1,
        NetworkInterfaces=[{
            'SubnetId': private_subnet_id,
            'DeviceIndex': 0,
            'AssociatePublicIpAddress': False,
            'Groups': [sg_id]
        }],
        TagSpecifications=[{
            'ResourceType': 'instance',
            'Tags': [{'Key': 'Name', 'Value': 'MiInstanciaPrivada'}]
        }]
    )

    instance = instances[0]
    instance.wait_until_running()
    instance.load()

    print(f"Instancia creada: {instance.id}")


if __name__ == "__main__":
    main()
