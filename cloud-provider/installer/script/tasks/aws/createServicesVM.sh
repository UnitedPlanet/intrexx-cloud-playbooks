#!/usr/bin/env bash

#Importing configuration variables
source variables.sh    

LOG_PREFIX="[CREATE MACHINE - $3 ] -"

## This script creates a vm used to deploy intrexx on it. The following are the parameters:
## $1 = script to write the variables to
## $2 = name of the instance variable to be used in later scripts
## $3 = name shown in the aws interface
## $4 = machine type 
## $5 = private ip of the instance
## $6 = win init script (only when windows instance)
## WIN:
## $7..X = SG's of the instance
## LINUX:
## $6..X = SG's of the instance

parameters=( "$@" )

echo "$LOG_PREFIX Creating machine $3"
if      [ $OPERATING_SYSTEM == "win" ]; then
    LAUNCH_SCRIPT=$(cat $SCRIPT_BASE_PATH/$6 | sed 's/__HOSTNAME__/'$3'/g'| sed 's/__ADMINPW__/'$AWS_ADMIN_PW_WIN'/g')
    INSTANCE_ID=$(aws ec2 run-instances                                                                                         \
        --image-id $AWS_OS_TYPE_WIN                                                                                             \
        --instance-type $4                                                                                                      \
        --key-name $SERVICES_KEY_NAME                                                                                           \
        --monitoring Enabled=false                                                                                              \
        --security-group-ids "${parameters[@]:6:$#}"                                                                            \
        --subnet-id $VIRTUAL_SUBNETWORK_EXTERNAL_ONE_ID                                                                         \
        --user-data  "<powershell>$LAUNCH_SCRIPT</powershell>"                                                                  \
        --enable-api-termination                                                                                                \
        --no-dry-run                                                                                                            \
        --no-ebs-optimized                                                                                                      \
        --private-ip-address $5                                                                                                 \
        --count 1:1                                                                                                             \
        --associate-public-ip-address                                                                                           \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$3'},{Key=RSG,Value='$RESOURCE_GROUP_NAME'}]'        \
        --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":30,"DeleteOnTermination":true,"VolumeType":"standard"}},{"DeviceName":"/dev/sdb1","Ebs":{"VolumeSize":50,"DeleteOnTermination":true,"VolumeType":"standard"}}]' \
        --output text                                                                                                           \
        --query 'Instances[0].[InstanceId]' | tr -d '\r')
elif    [ $OPERATING_SYSTEM == "linux" ]; then
    INSTANCE_ID=$(aws ec2 run-instances                                                                                         \
        --image-id $AWS_OS_TYPE_LINUX                                                                                           \
        --instance-type $4                                                                                                      \
        --key-name $SERVICES_KEY_NAME                                                                                           \
        --monitoring Enabled=false                                                                                              \
        --security-group-ids "${parameters[@]:5:$#}"                                                                            \
        --subnet-id $VIRTUAL_SUBNETWORK_EXTERNAL_ONE_ID                                                                         \
        --enable-api-termination                                                                                                \
        --no-dry-run                                                                                                            \
        --no-ebs-optimized                                                                                                      \
        --private-ip-address $5                                                                                                 \
        --count 1:1                                                                                                             \
        --associate-public-ip-address                                                                                           \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$3'},{Key=RSG,Value='$RESOURCE_GROUP_NAME'}]'        \
        --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":30,"DeleteOnTermination":true,"VolumeType":"standard"}},{"DeviceName":"/dev/sdb","Ebs":{"VolumeSize":50,"DeleteOnTermination":false,"VolumeType":"gp2"}}]' \
        --output text                                                                                                           \
        --query 'Instances[0].[InstanceId]' | tr -d '\r')
fi

echo "$LOG_PREFIX  Machine $3 created. Waiting until the instance is running."
# For some reason it sometimes failes when no pause is added before the wait operation
sleep 5
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

#create file to start over if scripts fail at a later point
mkdir -p $TEMP_EXE_FOLDER
THIS_FILE_NAME="${BASH_SOURCE[0]}"
echo "#!/bin/bash" > $SCRIPT_BASE_PATH/$1
echo "" >> $SCRIPT_BASE_PATH/$1
echo "$2_INSTANCE_ID=$INSTANCE_ID" >> $SCRIPT_BASE_PATH/$1
echo "$2_PUBLIC_IP=\$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text --query 'Reservations[0].Instances[0].[PublicIpAddress]')" >> $SCRIPT_BASE_PATH/$1

