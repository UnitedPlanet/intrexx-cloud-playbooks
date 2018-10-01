#!/usr/bin/env bash

DEBIAN_FRONTEND=noninteractive

#Importing configuration variables
source variables.sh  

aws ec2 import-key-pair             \
    --key-name $SERVICES_KEY_NAME     \
    --public-key-material $(cat $SSH_KEY.pub)  >/dev/null   

echo "[GENERAL] - Creating security group $LB_SECURITY_GROUP."
LB_SECURITY_GROUP_ID=$(aws ec2 create-security-group        \
    --description  $LB_SECURITY_GROUP_DESC                  \
    --group-name $LB_SECURITY_GROUP                         \
    --output text                                               \
    --vpc-id $VIRTUAL_NETWORK_ID | tr -d '\r') 

echo "[GENERAL] - Creating security group $EXTERNAL_SECURITY_GROUP_SSH."
EXTERNAL_SECURITY_GROUP_SSH_ID=$(aws ec2 create-security-group        \
    --description  $EXTERNAL_SECURITY_GROUP_SSH_DESC                  \
    --group-name $EXTERNAL_SECURITY_GROUP_SSH                         \
    --output text                                               \
    --vpc-id $VIRTUAL_NETWORK_ID | tr -d '\r') 

echo "[GENERAL] - Creating security group $EXTERNAL_SECURITY_GROUP_SOAP."
EXTERNAL_SECURITY_GROUP_SOAP_ID=$(aws ec2 create-security-group        \
    --description  $EXTERNAL_SECURITY_GROUP_SOAP_DESC                  \
    --group-name $EXTERNAL_SECURITY_GROUP_SOAP                         \
    --output text                                               \
    --vpc-id $VIRTUAL_NETWORK_ID | tr -d '\r') 

echo "[GENERAL] - Creating security group $INTERNAL_SECURITY_GROUP."
INTERNAL_SECURITY_GROUP_ID=$(aws ec2 create-security-group        \
    --description  $INTERNAL_SECURITY_GROUP_DESC                  \
    --group-name $INTERNAL_SECURITY_GROUP                         \
    --output text                                               \
    --vpc-id $VIRTUAL_NETWORK_ID | tr -d '\r') 

echo "[GENERAL] - Creating security group $DB_SECURITY_GROUP."
DB_SECURITY_GROUP_ID=$(aws ec2 create-security-group        \
    --description  $DB_SECURITY_GROUP_DESC                  \
    --group-name $DB_SECURITY_GROUP                         \
    --output text                                               \
    --vpc-id $VIRTUAL_NETWORK_ID | tr -d '\r') 

echo "[GENERAL] - Creating security group $EFS_SECURITY_GROUP."
EFS_SECURITY_GROUP_ID=$(aws ec2 create-security-group        \
    --description  $EFS_SECURITY_GROUP_DESC                  \
    --group-name $EFS_SECURITY_GROUP                         \
    --output text                                               \
    --vpc-id $VIRTUAL_NETWORK_ID | tr -d '\r') 

#Tag the ressource for probably easier delete operation
aws ec2 create-tags --resources $LB_SECURITY_GROUP_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME   
aws ec2 create-tags --resources $EXTERNAL_SECURITY_GROUP_SSH_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME    
aws ec2 create-tags --resources $EXTERNAL_SECURITY_GROUP_SOAP_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME    
aws ec2 create-tags --resources $INTERNAL_SECURITY_GROUP_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME    
aws ec2 create-tags --resources $DB_SECURITY_GROUP_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME    
aws ec2 create-tags --resources $EFS_SECURITY_GROUP_ID --tags Key=RSG,Value=$RESOURCE_GROUP_NAME    

#### load balancer rules ####
echo "[GENERAL] - Opening ports in $LB_SECURITY_GROUP_ID"
aws ec2  authorize-security-group-ingress       \
    --group-id $LB_SECURITY_GROUP_ID         \
    --protocol tcp                              \
    --port $INTREXX_WEB_FRONTEND_PORT                    \
    --cidr 0.0.0.0/0   
echo "[GENERAL] - HTTP port are open now." 
aws ec2  authorize-security-group-ingress       \
    --group-id $LB_SECURITY_GROUP_ID         \
    --protocol tcp                              \
    --port $INTREXX_WEB_FRONTEND_PORT_SSL                    \
    --cidr 0.0.0.0/0   
echo "[GENERAL] - HTTPS port are open now." 

#### external rules ####
echo "[GENERAL] - Opening ports in $EXTERNAL_SECURITY_GROUP_SOAP_ID"
aws ec2  authorize-security-group-ingress       \
    --group-id $EXTERNAL_SECURITY_GROUP_SOAP_ID         \
    --protocol tcp                              \
    --port $SERVICES_SOAP_PORT                    \
    --cidr 0.0.0.0/0   
echo "[GENERAL] - SOAP port are open now." 

echo "[GENERAL] - Opening ports in $EXTERNAL_SECURITY_GROUP_SOAP_ID"
aws ec2  authorize-security-group-ingress       \
    --group-id $EXTERNAL_SECURITY_GROUP_SSH_ID         \
    --protocol tcp                              \
    --port 22                                   \
    --cidr 0.0.0.0/0  
echo "[GENERAL] - SSH port is open now."

#### internal rules ####
aws ec2  authorize-security-group-ingress       \
    --group-id $INTERNAL_SECURITY_GROUP_ID         \
    --protocol tcp                              \
    --port "0-65535"                    \
    --cidr $VIRTUAL_NETWORK_PREFIXES 
echo "[GENERAL] - TCP ports internal are open now." 
aws ec2  authorize-security-group-ingress       \
    --group-id $INTERNAL_SECURITY_GROUP_ID         \
    --protocol udp                              \
    --port "0-65535"                  \
    --cidr $VIRTUAL_NETWORK_PREFIXES 
echo "[GENERAL] - UDP ports internal are open now." 

aws ec2  authorize-security-group-ingress       \
    --group-id $DB_SECURITY_GROUP_ID         \
    --protocol tcp                              \
    --port 5432                  \
    --cidr $VIRTUAL_NETWORK_PREFIXES 

aws ec2  authorize-security-group-ingress       \
    --group-id $DB_SECURITY_GROUP_ID         \
    --protocol udp                              \
    --port 5432                 \
    --cidr $VIRTUAL_NETWORK_PREFIXES 
echo "[GENERAL] - DB ports are open now." 

aws ec2 authorize-security-group-ingress \
    --group-id $EFS_SECURITY_GROUP_ID         \
    --protocol tcp \
    --port 2049 \
    --source-group $INTERNAL_SECURITY_GROUP_ID 
echo "[GENERAL] - Filesystem ports are open now." 

## DB Environment
aws rds create-db-subnet-group                                      \
    --db-subnet-group-name $DB_SUBNET_GROUP                         \
    --db-subnet-group-description $DB_SUBNET_GROUP_DESC             \
    --subnet-ids $VIRTUAL_SUBNETWORK_DB_ONE_ID $VIRTUAL_SUBNETWORK_DB_TWO_ID   \
    --tags Key=RSG,Value=$RESOURCE_GROUP_NAME  >/dev/null    
echo "[GENERAL] - POSTGRES subnet group: $DB_SUBNET_GROUP"

#create file to start over if scripts fail at a later point
mkdir -p $TEMP_EXE_FOLDER
THIS_FILE_NAME="${BASH_SOURCE[0]}"
echo "#!/bin/bash" > $SCRIPT_BASE_PATH/$1
echo "" >> $SCRIPT_BASE_PATH/$1
echo "LB_SECURITY_GROUP_ID=$LB_SECURITY_GROUP_ID" >> $SCRIPT_BASE_PATH/$1
echo "EXTERNAL_SECURITY_GROUP_SOAP_ID=$EXTERNAL_SECURITY_GROUP_SOAP_ID" >> $SCRIPT_BASE_PATH/$1
echo "EXTERNAL_SECURITY_GROUP_SSH_ID=$EXTERNAL_SECURITY_GROUP_SSH_ID" >> $SCRIPT_BASE_PATH/$1
echo "INTERNAL_SECURITY_GROUP_ID=$INTERNAL_SECURITY_GROUP_ID" >> $SCRIPT_BASE_PATH/$1
echo "DB_SECURITY_GROUP_ID=$DB_SECURITY_GROUP_ID" >> $SCRIPT_BASE_PATH/$1
echo "EFS_SECURITY_GROUP_ID=$EFS_SECURITY_GROUP_ID" >> $SCRIPT_BASE_PATH/$1