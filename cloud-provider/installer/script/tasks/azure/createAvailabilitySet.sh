#!/usr/bin/env bash

#Importing configuration variables
source variables.sh

echo "[AVAILABILITY_SET] - Creating availability set $AVAILABILITY_SET"
az vm availability-set create \
  --name $AVAILABILITY_SET \
  --resource-group $RESOURCE_GROUP_NAME \
  --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE

if [ $?  == 0 ]; then
    echo "[AVAILABILITY_SET] - Set $AVAILABILITY_SET created"
fi
