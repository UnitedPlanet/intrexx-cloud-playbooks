#!/bin/bash

#Importing configuration variables
source variables.sh

case "$CLOUD_PROVIDER" in
    "azure")
        az vm wait --name $SERVICES_NAME --resource-group $RESOURCE_GROUP_NAME --created
        echo "[FINALIZING] - Services vm is ready"

        az vm wait --name $PROVISIONING_NAME --resource-group $RESOURCE_GROUP_NAME --created
        echo "[FINALIZING] - Provisioning vm is ready"
        
        az vm wait --name $APPSERVER_NAME --resource-group $RESOURCE_GROUP_NAME --created
        echo "[FINALIZING] - App server vm is ready"   
        ;;
    "aws")
        aws ec2 wait instance-running                   \
            --instance-ids $SERVICES_INSTANCE_ID
        echo "[FINALIZING] - Services vm is ready"

        aws ec2 wait instance-running                   \
            --instance-ids $PROVISIONING_INSTANCE_ID
        echo "[FINALIZING] - Provisioning vm is ready"

        aws ec2 wait instance-running                   \
            --instance-ids $APPSERVER_INSTANCE_ID
echo "[FINALIZING] - App server vm is ready"
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac