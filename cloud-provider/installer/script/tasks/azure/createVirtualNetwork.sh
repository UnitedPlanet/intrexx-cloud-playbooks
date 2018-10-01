#!/usr/bin/env bash

#Importing configuration variables
source variables.sh

echo "[NETWORK] - Creating virtual network $VIRTUAL_NETWORK_NAME for prefixes $VIRTUAL_NETWORK_PREFIXES"
az network vnet create \
    --name $VIRTUAL_NETWORK_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --address-prefixes $VIRTUAL_NETWORK_PREFIXES \
    --subnet-name $VIRTUAL_SUBNETWORK_NAME \
    --subnet-prefix $VIRTUAL_SUBNETWORK_EXTERNAL_ONE_PREFIXES \
    --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE

if [ $?  == 0 ]; then
    echo "[NETWORK] - Virtual network $VIRTUAL_NETWORK_NAME created with subnet $VIRTUAL_SUBNETWORK_NAME"
fi    
