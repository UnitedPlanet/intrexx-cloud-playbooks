#!/usr/bin/env bash

#Importing configuration variables
source variables.sh

echo "[RESOURCE_GROUP] - Checking if resource group $RESOURCE_GROUP_NAME already exists"
GROUP_EXISTS=$(az group exists --name $RESOURCE_GROUP_NAME --output tsv)

if [ $GROUP_EXISTS == 'true' ]; then
    read -r -p "[RESOURCE_GROUP] - A group named $RESOURCE_GROUP_NAME already exists. Deleting it cannot be reversed. Are you sure you want to go ahead? [y/N] " response
    response=${response,,} # tolower

    if [[ "$response" =~ ^(yes|y)$ ]]; then
        echo "[RESOURCE_GROUP] - Deleting group $RESOURCE_GROUP_NAME. This may take a while"
        az group delete \
          --name $RESOURCE_GROUP_NAME \
          --yes \
          --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE

        echo "[RESOURCE_GROUP] - Resource group $RESOURCE_GROUP_NAME deleted"
    else
        echo "[RESOURCE_GROUP] - Please define another resource group name instead of $RESOURCE_GROUP_NAME and retry"
        exit 1
    fi
else
    echo "[RESOURCE_GROUP] - Resource group $RESOURCE_GROUP_NAME does not exist"
fi
