import boto3
import time

ec2 = boto3.client("ec2", region_name="us-east-1")

vpc = ec2.create_vpc(
    CidrBlock="10.10.0.0/16",
    TagSpecifications=[{
        "ResourceType": "vpc",
        "Tags": [{"Key": "Name", "Value": "VpcExamen3"}]
    }]
)
VPC_ID = vpc["Vpc"]["VpcId"]
print("VPC ID:", VPC_ID)


ig = ec2.create_internet_gateway(
    TagSpecifications=[{
        "ResourceType": "internet-gateway",
        "Tags": [{"Key": "Name", "Value": "igw-Examen"}]
    }]
)
IG_ID = ig["InternetGateway"]["InternetGatewayId"]
print("Internet Gateway ID:", IG_ID)

ec2.attach_internet_gateway(
    InternetGatewayId=IG_ID,
    VpcId=VPC_ID
)


sub1 = ec2.create_subnet(
    VpcId=VPC_ID,
    CidrBlock="10.10.1.0/24",
    AvailabilityZone="us-east-1a",
    TagSpecifications=[{
        "ResourceType": "subnet",
        "Tags": [{"Key": "Name", "Value": "Publica1"}]
    }]
)
SUBPU_ID = sub1["Subnet"]["SubnetId"]
print("Subred pública 1:", SUBPU_ID)

sub2 = ec2.create_subnet(
    VpcId=VPC_ID,
    CidrBlock="10.10.2.0/24",
    AvailabilityZone="us-east-1d",
    TagSpecifications=[{
        "ResourceType": "subnet",
        "Tags": [{"Key": "Name", "Value": "Publica2"}]
    }]
)
SUBPU2_ID = sub2["Subnet"]["SubnetId"]
print("Subred pública 2:", SUBPU2_ID)


rt1 = ec2.create_route_table(VpcId=VPC_ID)
RTPU_ID = rt1["RouteTable"]["RouteTableId"]

ec2.create_route(
    RouteTableId=RTPU_ID,
    DestinationCidrBlock="0.0.0.0/0",
    GatewayId=IG_ID
)
ec2.modify_subnet_attribute(
    SubnetId=SUBPU_ID,
    MapPublicIpOnLaunch={"Value": True}
)
ec2.associate_route_table(
    RouteTableId=RTPU_ID,
    SubnetId=SUBPU_ID
)

rt2 = ec2.create_route_table(VpcId=VPC_ID)
RTPU2_ID = rt2["RouteTable"]["RouteTableId"]

ec2.create_route(
    RouteTableId=RTPU2_ID,
    DestinationCidrBlock="0.0.0.0/0",
    GatewayId=IG_ID
)
ec2.modify_subnet_attribute(
    SubnetId=SUBPU2_ID,
    MapPublicIpOnLaunch={"Value": True}
)
ec2.associate_route_table(
    RouteTableId=RTPU2_ID,
    SubnetId=SUBPU2_ID
)


subpr1 = ec2.create_subnet(
    VpcId=VPC_ID,
    CidrBlock="10.10.3.0/24",
    AvailabilityZone="us-east-1a",
    TagSpecifications=[{
        "ResourceType": "subnet",
        "Tags": [{"Key": "Name", "Value": "Privada1"}]
    }]
)
SUBPR_ID = subpr1["Subnet"]["SubnetId"]
print("Subred privada 1:", SUBPR_ID)

subpr2 = ec2.create_subnet(
    VpcId=VPC_ID,
    CidrBlock="10.10.4.0/24",
    AvailabilityZone="us-east-1d",
    TagSpecifications=[{
        "ResourceType": "subnet",
        "Tags": [{"Key": "Name", "Value": "Privada2"}]
    }]
)
SUBPR2_ID = subpr2["Subnet"]["SubnetId"]
print("Subred privada 2:", SUBPR2_ID)


alloc = ec2.allocate_address(Domain="vpc")
ALLO_ID = alloc["AllocationId"]

print("Creando NAT Gateway, espera unos segundos...")

ng = ec2.create_nat_gateway(
    SubnetId=SUBPU_ID,
    AllocationId=ALLO_ID
)
NG_ID = ng["NatGateway"]["NatGatewayId"]


ec2.get_waiter("nat_gateway_available").wait(NatGatewayIds=[NG_ID])
print("Nat Gateway ID:", NG_ID)


rtp1 = ec2.create_route_table(VpcId=VPC_ID)
RTPR_ID = rtp1["RouteTable"]["RouteTableId"]

ec2.create_route(
    RouteTableId=RTPR_ID,
    DestinationCidrBlock="0.0.0.0/0",
    NatGatewayId=NG_ID
)
ec2.associate_route_table(
    RouteTableId=RTPR_ID,
    SubnetId=SUBPR_ID
)

rtp2 = ec2.create_route_table(VpcId=VPC_ID)
RTPR2_ID = rtp2["RouteTable"]["RouteTableId"]

ec2.create_route(
    RouteTableId=RTPR2_ID,
    DestinationCidrBlock="0.0.0.0/0",
    NatGatewayId=NG_ID
)
ec2.associate_route_table(
    RouteTableId=RTPR2_ID,
    SubnetId=SUBPR2_ID
)


sg = ec2.create_security_group(
    VpcId=VPC_ID,
    GroupName="sgExamen",
    Description="sgExamen"
)
SG_ID = sg["GroupId"]

ec2.authorize_security_group_ingress(
    GroupId=SG_ID,
    IpPermissions=[{
        "IpProtocol": "tcp",
        "FromPort": 22,
        "ToPort": 22,
        "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "AllowSSH"}]
    }]
)


public_nacl = ec2.create_network_acl(VpcId=VPC_ID)
PUBLIC_NACL_ID = public_nacl["NetworkAcl"]["NetworkAclId"]
print("NACL Pública:", PUBLIC_NACL_ID)


def get_assoc(subnet_id):
    # Espera hasta que aparezca la asociación (máx. 15 segundos)
    for _ in range(5):
        nacls = ec2.describe_network_acls(
            Filters=[{"Name": "association.subnet-id", "Values": [subnet_id]}]
        )

        if nacls["NetworkAcls"]:
            for assoc in nacls["NetworkAcls"][0]["Associations"]:
                if assoc["SubnetId"] == subnet_id:
                    return assoc["NetworkAclAssociationId"]

        time.sleep(3)

    raise Exception(f"No se encontró NetworkAclAssociationId para la subred {subnet_id}")

ASSOC_ID = get_assoc(SUBPU_ID)
ASSOC2_ID = get_assoc(SUBPU2_ID)

ec2.replace_network_acl_association(
    AssociationId=ASSOC_ID,
    NetworkAclId=PUBLIC_NACL_ID
)
ec2.replace_network_acl_association(
    AssociationId=ASSOC2_ID,
    NetworkAclId=PUBLIC_NACL_ID
)


private_nacl = ec2.create_network_acl(VpcId=VPC_ID)
PRIVATE_NACL_ID = private_nacl["NetworkAcl"]["NetworkAclId"]
print("NACL Privada:", PRIVATE_NACL_ID)

ASSOC3_ID = get_assoc(SUBPR_ID)
ASSOC4_ID = get_assoc(SUBPR2_ID)

ec2.replace_network_acl_association(
    AssociationId=ASSOC3_ID,
    NetworkAclId=PRIVATE_NACL_ID
)
ec2.replace_network_acl_association(
    AssociationId=ASSOC4_ID,
    NetworkAclId=PRIVATE_NACL_ID
)


ec2.create_network_acl_entry(
    NetworkAclId=PUBLIC_NACL_ID,
    RuleNumber=100,
    Protocol="6",
    RuleAction="allow",
    Egress=False,
    CidrBlock="0.0.0.0/0",
    PortRange={"From": 80, "To": 80}
)


ec2.create_network_acl_entry(
    NetworkAclId=PUBLIC_NACL_ID,
    RuleNumber=110,
    Protocol="6",
    RuleAction="allow",
    Egress=False,
    CidrBlock="0.0.0.0/0",
    PortRange={"From": 443, "To": 443}
)


ec2.create_network_acl_entry(
    NetworkAclId=PUBLIC_NACL_ID,
    RuleNumber=120,
    Protocol="6",
    RuleAction="allow",
    Egress=False,
    CidrBlock="0.0.0.0/0",
    PortRange={"From": 22, "To": 22}
)


ec2.create_network_acl_entry(
    NetworkAclId=PUBLIC_NACL_ID,
    RuleNumber=32766,
    Protocol="-1",
    RuleAction="deny",
    Egress=False,
    CidrBlock="0.0.0.0/0"
)


ec2.create_network_acl_entry(
    NetworkAclId=PRIVATE_NACL_ID,
    RuleNumber=100,
    Protocol="-1",
    RuleAction="allow",
    Egress=False,
    CidrBlock="10.10.0.0/16"
)


ec2.create_network_acl_entry(
    NetworkAclId=PRIVATE_NACL_ID,
    RuleNumber=32766,
    Protocol="-1",
    RuleAction="deny",
    Egress=False,
    CidrBlock="0.0.0.0/0"
)


def run_instance(name, subnet_id):
    instance = ec2.run_instances(
        ImageId="ami-0360c520857e3138f",
        InstanceType="t2.micro",
        KeyName="vockey",
        SubnetId=subnet_id,
        MaxCount=1,
        MinCount=1,
        TagSpecifications=[{
            "ResourceType": "instance",
            "Tags": [{"Key": "Name", "Value": name}]
        }]
    )
    return instance["Instances"][0]["InstanceId"]

EC2_ID_Publica = run_instance("Publica1", SUBPU_ID)
EC2_ID_Publica2 = run_instance("Publica2", SUBPU2_ID)
EC2_ID_Privada = run_instance("Privada", SUBPR_ID)
EC2_ID_Privada2 = run_instance("Privada2", SUBPR2_ID)

print("EC2 Públicas:", EC2_ID_Publica, EC2_ID_Publica2)
print("EC2 Privadas:", EC2_ID_Privada, EC2_ID_Privada2)