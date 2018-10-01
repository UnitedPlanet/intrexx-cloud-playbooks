#!/usr/bin/env bash
source variables.sh

GROUP_EXISTS=$(az group exists --name $RESOURCE_GROUP_NAME --output tsv)

if [ $GROUP_EXISTS == 'true' ]; then
    echo "[RESOURCE_GROUP] - A resource group named $RESOURCE_GROUP_NAME already exists. Please delete it or define a new group name and retry"
    exit 1
fi

echo "[RESOURCE_GROUP] - Creating group $RESOURCE_GROUP_NAME in location $AZ_AVAILABILITY_ZONE"

az group create \
  --name $RESOURCE_GROUP_NAME \
  --location $AZ_AVAILABILITY_ZONE \
  --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE

echo "[RESOURCE_GROUP] - Resource group $RESOURCE_GROUP_NAME created"
