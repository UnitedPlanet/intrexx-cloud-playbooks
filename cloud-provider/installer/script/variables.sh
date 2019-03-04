##################################################################################

# 'aws' or 'azure'
# NOTE: the cloud provider is always validated via switch case, therefore the scripts should be easily extendable
CLOUD_PROVIDER=aws

# 'linux' or 'win'
OPERATING_SYSTEM=linux

# name of the portal, which is going to be deployed
PORTAL_NAME=test

# Dir which contains the intrexx related data (e.g. the trunk zip) 
DATA_DIR=./awsDeploy/data
# URL of the intrexx linux setup tarball
INTREXX_ZIP=https://download.unitedplanet.com/intrexx/90000/intrexx-18.09.1-linux-x86_64.tar.gz
# URL of the intrexx windows setup zip
#INTREXX_ZIP=https://download.unitedplanet.com/intrexx/90000/intrexx-18.09.1-windows-x86_64.zip

##################################################################################
#################################### ADVANCED ####################################
##################################################################################

## AZURE only ##
RESOURCE_GROUP_NAME=IxResourceGroup
AVAILABILITY_SET=IxAvailabilitySet
AZ_OUTPUT_FORMAT=table
########################

## AWS only ##
AWS_OUTPUT_FORMAT=table
# Security group which allows access to the wild world outside 
LB_SECURITY_GROUP="SG_LB"
LB_SECURITY_GROUP_DESC="Security group which allows the load balancer access to the wild world outside "
# Security group which allows access to the wild world outside 
EXTERNAL_SECURITY_GROUP_SSH="SG_EXT SSH"
EXTERNAL_SECURITY_GROUP_SSH_DESC="Security group which allows ssh access from the wild world outside"
EXTERNAL_SECURITY_GROUP_SOAP="SG_EXT SOAP"
EXTERNAL_SECURITY_GROUP_SOAP_DESC="Security group which allows SOAP access from the wild world outside"
# Secure all instances of the autoscaling group as well as every instance, which should not be accessed via the internet
INTERNAL_SECURITY_GROUP="SG_INT"
INTERNAL_SECURITY_GROUP_DESC="Secure all instances of the autoscaling group as well as every instance, which should not be accessed via the internet"
# Only allows specific database related access from inside the network
DB_SECURITY_GROUP="SG_DB"
DB_SECURITY_GROUP_DESC="Only allows specific database related access from inside the network"
# Only allows specific database related access from inside the network
DB_SECURITY_GROUP="SG_DB"
DB_SECURITY_GROUP_DESC="Only allows specific database related access from inside the network"
# Only allows specific filesystem related access from inside the network
EFS_SECURITY_GROUP="SG_EFS"
EFS_SECURITY_GROUP_DESC="Security Group for EFS"
########################

## Script related ##
TEMP_EXE_FOLDER=execConfigurations
WORK_DIR=./work
SSH_KEY=$WORK_DIR/id_rsa_vm
OUTPUT_FILE=output.log
########################

## Hardware default ##
AWS_INSTANCE_TYPE_SERVICES_WIN=t2.medium
AWS_INSTANCE_TYPE_SERVICES_LINUX=t2.medium
AWS_INSTANCE_TYPE_APPSERVER_WIN=t2.medium
AWS_INSTANCE_TYPE_APPSERVER_LINUX=t2.medium
AWS_INSTANCE_TYPE_PROVISIONING_LINUX=t2.medium

AZ_INSTANCE_TYPE_SERVICES_WIN=Standard_B2s
AZ_INSTANCE_TYPE_SERVICES_LINUX=Standard_B2s
AZ_INSTANCE_TYPE_APPSERVER_WIN=Standard_B2s
AZ_INSTANCE_TYPE_APPSERVER_LINUX=Standard_B2s
AZ_INSTANCE_TYPE_PROVISIONING_LINUX=Standard_B1s
########################

## Operating system default ##
AWS_OS_TYPE_WIN=ami-e61b4a9f
AWS_OS_TYPE_LINUX=ami-79c4de93

AZ_OS_TYPE_WIN=Win2016Datacenter
AZ_OS_TYPE_LINUX=UbuntuLTS
########################

## Disk size ##
AWS_DISK_SIZE_WIN=30
AWS_DISK_SIZE_LINUX=12
AZ_DISK_SIZE_WIN=30
AZ_DISK_SIZE_LINUX=12
######################## 

## General user ##
# NOTE: Keep in mind, that the user is also used in the ansible scripts! Needs to be changed there as well!
AWS_ADMIN_USER_WIN=ixadmin
AWS_ADMIN_PW_WIN='awsWin2019pw!!'
AWS_ADMIN_USER_LINUX=ubuntu
# linux login via ssh
# AZ does not allow 'administrator' or 'admin'
AZ_ADMIN_USER_WIN=ixadmin
AZ_ADMIN_PW_WIN='awsWin2019pw!!'
AZ_ADMIN_USER_LINUX=ubuntu
# linux login via ssh
########################

## Database cloud provider related ##
AWS_DATABASE_DRIVER=postgresql
AWS_DATABASE_VERSION=9.6.5
AWS_DATABASE_TYPE=db.t2.micro 
AWS_DATABASE_PORT=5432

AZ_DATABASE_DRIVER=mssql # mssql | postgres
AZ_DATABASE_TYPE=S0
AZ_DATABASE_PORT=1433 # 1433 | 5432
########################

## AWS EFS related ##
EFS_CREATION_TOKEN=IxElasticFileSystem
EFS_AWS_REGION=eu-west-1
EFS_DNS_ADDRESS=
########################

## NETWORKING ##
VIRTUAL_NETWORK_NAME=IxNetwork        
VIRTUAL_NETWORK_PREFIXES=10.0.0.0/16
VIRTUAL_SUBNETWORK_NAME=IxNetworkSubnet
VIRTUAL_SUBNETWORK_PREFIXES=10.0.4.0/24
VIRTUAL_SUBNETWORK_DB_ONE_PREFIXES=10.0.1.0/24
VIRTUAL_SUBNETWORK_DB_TWO_PREFIXES=10.0.2.0/24
VIRTUAL_SUBNETWORK_EXTERNAL_ONE_PREFIXES=10.0.0.0/24
VIRTUAL_SUBNETWORK_EXTERNAL_TWO_PREFIXES=10.0.5.0/24
########################

## Deployment zone
#The availability zone of aws only, no "a","b" or "c"! This will be added automatically.
AWS_AVAILABILITY_ZONE=eu-west-1
AZ_AVAILABILITY_ZONE=westeurope
########################

## PROVISIONING VM ##
PROVISIONING_NAME=IxProvisioning                    
PROVISIONING_PRIVATE_IP=10.0.0.4
########################

## SERVICES VM ##
SERVICES_NAME=IxServices
SERVICES_KEY_NAME=IxSSHKey                   
SERVICES_PRIVATE_IP=10.0.0.5
SERVICES_SOAP_PORT=8101
SERVICES_SOLR_PORT=8983
SERVICES_DISK_NAME=IxServicesDisk
########################

## APPSERVER VM ##
APPSERVER_NAME=IxAppServer                  
APPSERVER_PRIVATE_IP=10.0.0.6
########################
  
## SCALE SET ##
IMG_NAME=IxVmssImage
LAUNCH_CONFIG_NAME=$IMG_NAME"_LAUNCH_CONFIG"
SCALE_SET_NAME=IxScaleSet
SCALE_SET_DESIRED_SIZE=1
SCALE_SET_MIN=1
SCALE_SET_MAX=3
########################

## LOAD BALANCER ##
LOAD_BALANCER_NAME=$SCALE_SET_NAME"LB"
HEALTH_PROBE_NAME="IxHealthProbe"
#Needs to be set to the correct portal otherwise azure LB wont forward requests 
HEALTH_PROBE_PATH=/default.ixsp?qs_service=services/ping/
#Interval in seconds
HEALTH_PROBE_INTERVAL=30
#Ports für Intrexx
INTREXX_WEB_FRONTEND_PORT=80
INTREXX_WEB_FRONTEND_PORT_SSL=443
INTREXX_WEB_BACKEND_PORT=1337
#Allowing HTTPS, make sure the files are correctly set
INTREXX_HTTPS_ENABLE=false
INTREXX_HTTPS_CERTIFICATE_PEM=
INTREXX_HTTPS_CERTIFICATE_CHAIN_PEM=
INTREXX_HTTPS_CERTIFICATE_PRIVATE_KEY_PEM=
INTREXX_HTTPS_CERTIFICATE_SECURITY_POLICY=
########################

## DATABASE ##
DB_SERVER_NAME=ixcloudvmtestsqldb   #Please specify a value only in lowercases
DB_SERVER_ADMIN_USER=intrexx
DB_SERVER_ADMIN_PASSWD='1MyIxCloud!'
DB_NAME=ixtest
DB_IDENTIFIER=POSTGRESDBINTREXX
DB_SUBNET_GROUP=$DB_SERVER_NAME"_SUBNET"
DB_SUBNET_GROUP_DESC=$DB_SERVER_NAME"_SUBNET_DESC"
########################


# Options to be loaded in all scripts
# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)
set -euo pipefail
IFS=$'\n\t'
