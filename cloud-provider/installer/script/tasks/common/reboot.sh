#!/usr/bin/env bash

#Importing configuration variables
source variables.sh

## Parameter
# AWS $1 = instance id,     $2 = name for logs
# AZ  $1 = name of instance

case "$CLOUD_PROVIDER" in
    "azure")
        echo "[SERVICES_VM] - Restarting services machine $1"
        az vm restart --resource-group $RESOURCE_GROUP_NAME --name $1
        ;;
    "aws")
        echo "[APPSERVER_VM] - Restarting app server machine $2"
        aws ec2 reboot-instances  --instance-ids $1  >> $OUTPUT_FILE
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac

