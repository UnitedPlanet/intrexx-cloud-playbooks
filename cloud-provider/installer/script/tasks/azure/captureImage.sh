#!/usr/bin/env bash

#Importing configuration variables
source variables.sh

APPSERVER_PUBLIC_IP=$( \
az vm list-ip-addresses \
  --name $APPSERVER_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" \
  --output tsv)

echo "[APPSERVER] - Deprovisioning"
if    [ $OPERATING_SYSTEM == "linux" ]; then
    ssh -o "StrictHostKeyChecking no" -i $SSH_KEY $AZ_ADMIN_USER_LINUX@$APPSERVER_PUBLIC_IP 'sudo waagent -deprovision+user -force'
fi

echo "[APPSERVER] - Stopping and deallocating"
az vm deallocate \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $APPSERVER_NAME \
  --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE
  
echo "[APPSERVER] - Generalizing"
az vm generalize \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $APPSERVER_NAME \
  --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE

echo "[VMSS_IMAGE] - Creating image: $IMG_NAME"
az image create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $IMG_NAME \
  --source $APPSERVER_NAME \
  --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE
