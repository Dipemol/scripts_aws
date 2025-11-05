import boto3

def crear_vpc():
    ec2 = boto3.client('ec2')

    vpc = ec2.create_vpc(CidrBlock='192.168.1.0/24')
    vpc_id = vpc['Vpc']['VpcId']
    print('VPC creada con ID: {vpc_id}')

    ec2.modify_vpc_attribute(
        VpcId=vpc_id,
        EnableDnsSupport={'Value': True}
    )

    ec2.modify_vpc_attribute(
        VpcId=vpc_id,
        EnableDnsHostnames={'Value': True}
    )

    ec2.create_tags(
        Resources=[vpc_id],
        Tags[{'Key': 'Name', 'Value': 'MiVPC-Boto3'}]
    )

    print("DNS habilitado y etiqueta 'MiVPC-Boto3' asignada")
    return vpc_id
if __name__ == "__main__":
    vpc_id = crear_vpc()
    print('Proceso completado. ID de la VPC: {vpc_id}')