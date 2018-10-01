#!/bin/bash

#Importing configuration variables
source variables.sh



echo "[NETWORK] - Creating VPC for prefixes $VIRTUAL_NETWORK_PREFIXES"
VIRTUAL_NETWORK_ID=$(aws ec2 create-vpc         \
    --cidr-block $VIRTUAL_NETWORK_PREFIXES      \
    --output text                               \
    --query 'Vpc.[VpcId]' | tr -d '\r')

#Tag the ressource for probably easier delete operation
aws ec2 create-tags --resources $VIRTUAL_NETWORK_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME

#Needed to avoid ssh error "unable to resolve host"
aws ec2 modify-vpc-attribute --enable-dns-hostname --vpc-id $VIRTUAL_NETWORK_ID

if [ $VIRTUAL_NETWORK_ID == "null" ]; then
    echo "[NETWORK] - A virtual network could not be created"
    exit 1
fi

#NOTE: the 2 subents have to be in different availability zones to allow a db subnet group, which is needed to create a db instance.
VIRTUAL_SUBNETWORK_ID=$(aws ec2 create-subnet       \
    --cidr-block $VIRTUAL_SUBNETWORK_PREFIXES       \
    --availability-zone $AWS_AVAILABILITY_ZONE"a"       \
    --vpc-id $VIRTUAL_NETWORK_ID                    \
    --output text                                   \
    --query 'Subnet.[SubnetId]' | tr -d '\r')

#Tag the ressource for probably easier delete operation
aws ec2 create-tags --resources $VIRTUAL_SUBNETWORK_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME


VIRTUAL_SUBNETWORK_DB_ONE_ID=$(aws ec2 create-subnet       \
    --cidr-block $VIRTUAL_SUBNETWORK_DB_ONE_PREFIXES       \
    --availability-zone $AWS_AVAILABILITY_ZONE"a"          \
    --vpc-id $VIRTUAL_NETWORK_ID                    \
    --output text                                   \
    --query 'Subnet.[SubnetId]' | tr -d '\r')

#Tag the ressource for probably easier delete operation
aws ec2 create-tags --resources $VIRTUAL_SUBNETWORK_DB_ONE_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME

VIRTUAL_SUBNETWORK_DB_TWO_ID=$(aws ec2 create-subnet       \
    --cidr-block $VIRTUAL_SUBNETWORK_DB_TWO_PREFIXES       \
    --availability-zone $AWS_AVAILABILITY_ZONE"b"          \
    --vpc-id $VIRTUAL_NETWORK_ID                    \
    --output text                                   \
    --query 'Subnet.[SubnetId]' | tr -d '\r')

#Tag the ressource for probably easier delete operation
aws ec2 create-tags --resources $VIRTUAL_SUBNETWORK_DB_TWO_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME

VIRTUAL_SUBNETWORK_EXTERNAL_ONE_ID=$(aws ec2 create-subnet       \
    --cidr-block $VIRTUAL_SUBNETWORK_EXTERNAL_ONE_PREFIXES       \
    --availability-zone $AWS_AVAILABILITY_ZONE"a"       \
    --vpc-id $VIRTUAL_NETWORK_ID                    \
    --output text                                   \
    --query 'Subnet.[SubnetId]' | tr -d '\r')

#Tag the ressource for probably easier delete operation
aws ec2 create-tags --resources $VIRTUAL_SUBNETWORK_EXTERNAL_ONE_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME

VIRTUAL_SUBNETWORK_EXTERNAL_TWO_ID=$(aws ec2 create-subnet       \
    --cidr-block $VIRTUAL_SUBNETWORK_EXTERNAL_TWO_PREFIXES       \
    --availability-zone $AWS_AVAILABILITY_ZONE"b"       \
    --vpc-id $VIRTUAL_NETWORK_ID                    \
    --output text                                   \
    --query 'Subnet.[SubnetId]' | tr -d '\r')

#Tag the ressource for probably easier delete operation
aws ec2 create-tags --resources $VIRTUAL_SUBNETWORK_EXTERNAL_TWO_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME

#Allow the access to the internet   
INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway --output text --query "InternetGateway.[InternetGatewayId]")

#Tag the ressource for probably easier delete operation
aws ec2 create-tags --resources $INTERNET_GATEWAY_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME  
#Connect the gateway to the VPC
aws ec2 attach-internet-gateway --internet-gateway-id $INTERNET_GATEWAY_ID --vpc-id $VIRTUAL_NETWORK_ID     >/dev/null
echo "[NETWORK] - The internet gateway $INTERNET_GATEWAY_ID has been created and attached to the vpc $VIRTUAL_NETWORK_ID"

########################### ROUTE TABLE INTERN
ROUTE_TABLE_ID=$(aws ec2 create-route-table     \
    --vpc-id $VIRTUAL_NETWORK_ID                \
    --output text                               \
    --query "RouteTable.[RouteTableId]") 
#Tag the ressource for probably easier delete operation
aws ec2 create-tags --resources $ROUTE_TABLE_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME    
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $VIRTUAL_SUBNETWORK_ID   >/dev/null 
echo "[NETWORK] - Route table with the id $ROUTE_TABLE_ID has been created and added to the vpc with id $VIRTUAL_SUBNETWORK_ID"


########################### ROUTE TABLES DB
ROUTE_TABLE_DB_ONE_ID=$(aws ec2 create-route-table     \
    --vpc-id $VIRTUAL_NETWORK_ID                \
    --output text                               \
    --query "RouteTable.[RouteTableId]")      
#Tag the ressource for probably easier delete operation
aws ec2 create-tags --resources $ROUTE_TABLE_DB_ONE_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME       
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_DB_ONE_ID --subnet-id $VIRTUAL_SUBNETWORK_DB_ONE_ID >/dev/null 
echo "[NETWORK] - Route table with the id $ROUTE_TABLE_DB_ONE_ID has been created and added to the vpc with id $VIRTUAL_SUBNETWORK_DB_ONE_ID"

ROUTE_TABLE_DB_TWO_ID=$(aws ec2 create-route-table     \
    --vpc-id $VIRTUAL_NETWORK_ID                \
    --output text                               \
    --query "RouteTable.[RouteTableId]")      
#Tag the ressource for probably easier delete operation
aws ec2 create-tags --resources $ROUTE_TABLE_DB_TWO_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME       
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_DB_TWO_ID --subnet-id $VIRTUAL_SUBNETWORK_DB_TWO_ID >/dev/null 
echo "[NETWORK] - Route table with the id $ROUTE_TABLE_DB_TWO_ID has been created and added to the vpc with id $VIRTUAL_SUBNETWORK_DB_TWO_ID"


########################### ROUTE TABLES DB
ROUTE_TABLE_EXTERNAL_ONE_ID=$(aws ec2 create-route-table     \
    --vpc-id $VIRTUAL_NETWORK_ID                \
    --output text                               \
    --query "RouteTable.[RouteTableId]")      
#Tag the ressource for probably easier delete operation
aws ec2 create-tags --resources $ROUTE_TABLE_EXTERNAL_ONE_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME       
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_EXTERNAL_ONE_ID --subnet-id $VIRTUAL_SUBNETWORK_EXTERNAL_ONE_ID >/dev/null 
echo "[NETWORK] - Route table with the id $ROUTE_TABLE_EXTERNAL_ONE_ID has been created and added to the vpc with id $VIRTUAL_SUBNETWORK_EXTERNAL_ONE_PREFIXES"

ROUTE_TABLE_EXTERNAL_TWO_ID=$(aws ec2 create-route-table     \
    --vpc-id $VIRTUAL_NETWORK_ID                \
    --output text                               \
    --query "RouteTable.[RouteTableId]")      
#Tag the ressource for probably easier delete operation
aws ec2 create-tags --resources $ROUTE_TABLE_EXTERNAL_TWO_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME       
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_EXTERNAL_TWO_ID --subnet-id $VIRTUAL_SUBNETWORK_EXTERNAL_TWO_ID >/dev/null 
echo "[NETWORK] - Route table with the id $ROUTE_TABLE_EXTERNAL_TWO_ID has been created and added to the vpc with id $VIRTUAL_SUBNETWORK_EXTERNAL_TWO_PREFIXES"

#Enable access to the VPC from outside
aws ec2 create-route --destination-cidr-block 0.0.0.0/0 --route-table-id $ROUTE_TABLE_EXTERNAL_ONE_ID --gateway-id $INTERNET_GATEWAY_ID      >/dev/null
aws ec2 create-route --destination-cidr-block 0.0.0.0/0 --route-table-id $ROUTE_TABLE_EXTERNAL_TWO_ID --gateway-id $INTERNET_GATEWAY_ID      >/dev/null
echo "[NETWORK] - Route to access the VPC from outside has been added to the vpc with id $VIRTUAL_NETWORK_ID"

#create file to start over if scripts fail at a later point
mkdir -p $TEMP_EXE_FOLDER
THIS_FILE_NAME="${BASH_SOURCE[0]}"
echo "#!/bin/bash" > $SCRIPT_BASE_PATH/$1
echo "" >> $SCRIPT_BASE_PATH/$1
echo "VIRTUAL_NETWORK_ID=$VIRTUAL_NETWORK_ID" >> $SCRIPT_BASE_PATH/$1
echo "VIRTUAL_SUBNETWORK_ID=$VIRTUAL_SUBNETWORK_ID" >> $SCRIPT_BASE_PATH/$1
echo "VIRTUAL_SUBNETWORK_DB_ONE_ID=$VIRTUAL_SUBNETWORK_DB_ONE_ID" >> $SCRIPT_BASE_PATH/$1
echo "VIRTUAL_SUBNETWORK_DB_TWO_ID=$VIRTUAL_SUBNETWORK_DB_TWO_ID" >> $SCRIPT_BASE_PATH/$1
echo "VIRTUAL_SUBNETWORK_EXTERNAL_ONE_ID=$VIRTUAL_SUBNETWORK_EXTERNAL_ONE_ID" >> $SCRIPT_BASE_PATH/$1
echo "VIRTUAL_SUBNETWORK_EXTERNAL_TWO_ID=$VIRTUAL_SUBNETWORK_EXTERNAL_TWO_ID" >> $SCRIPT_BASE_PATH/$1

echo "[NETWORK] - Virtual network $VIRTUAL_NETWORK_ID created with subnets $VIRTUAL_SUBNETWORK_ID $VIRTUAL_SUBNETWORK_DB_ONE_ID $VIRTUAL_SUBNETWORK_DB_TWO_ID $VIRTUAL_SUBNETWORK_EXTERNAL_ONE_ID $VIRTUAL_SUBNETWORK_EXTERNAL_TWO_ID"
