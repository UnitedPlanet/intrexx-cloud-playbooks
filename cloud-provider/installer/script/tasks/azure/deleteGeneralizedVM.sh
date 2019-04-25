#!/usr/bin/env bash

#Importing configuration variables
source variables.sh

GENERALIZED_STATE_COUNT=$(az vm get-instance-view --resource-group $RESOURCE_GROUP_NAME --name $APPSERVER_NAME --query "length(instanceView.statuses[?code=='OSState/generalized'])" --output tsv)

if [ "$GENERALIZED_STATE_COUNT" != '1' ]; then
    echo "[APPSERVER_VM] - The $APPSERVER_NAME machine is either not generalized or does not exist"
    exit 1
else
    echo "[APPSERVER_VM] - Deleting machine $APPSERVER_NAME"

    az vm delete \
        --resource-group $RESOURCE_GROUP_NAME \
        --name $APPSERVER_NAME \
        
#    echo "[APPSERVER_VM] - Deleting resources linked to $APPSERVER_NAME"
#    az resource delete \
#        --ids $(az resource list --tag $APPSERVER_RESOURCES_TAG --query "[].id" -o tsv) \
#        --output $OUTPUT_FORMAT >> $OUTPUT_FILE
#
#    az configure --defaults group=$RESOURCE_GROUP_NAME
    
    echo "[APPSERVER_VM] - All resources deleted"
fi