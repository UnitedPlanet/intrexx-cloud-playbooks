#!/bin/bash

#Importing configuration variables
source variables.sh

echo "[SQL_SERVER] - Creating filesystem "

EFS_FILESYSTEM_ID=$(aws efs create-file-system --creation-token $EFS_CREATION_TOKEN --performance-mode generalPurpose --throughput-mode bursting --output text --query "FileSystemId")

aws efs create-tags --file-system-id $EFS_FILESYSTEM_ID --tags Key=RSG,Value=IxResourceGroup

echo "[FILESYSTEM] - AWS EFS has been created"

sleep 10

EFS_MOUNTTARGET_ID=$(aws efs create-mount-target --file-system-id $EFS_FILESYSTEM_ID --subnet-id $VIRTUAL_SUBNETWORK_ID --security-group $EFS_SECURITY_GROUP_ID --output text --query "MountTargetId")

echo "[FILESYSTEM] - EFS is accessible via $EFS_MOUNTTARGET_ID"

#create file to start over if scripts fail at a later point
mkdir -p $TEMP_EXE_FOLDER
THIS_FILE_NAME="${BASH_SOURCE[0]}"
echo "#!/bin/bash" > $SCRIPT_BASE_PATH/$1
echo "" >> $SCRIPT_BASE_PATH/$1
echo "EFS_DNS_ADDRESS=$EFS_FILESYSTEM_ID.efs.$EFS_AWS_REGION.amazonaws.com" >> $SCRIPT_BASE_PATH/$1