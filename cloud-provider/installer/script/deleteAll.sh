#!/bin/bash

#Importing configuration variables
source variables.sh

LOG_PREFIX="[CLOUD_RESET] -"
read -p "$LOG_PREFIX About to delete everything created, this can't be reverted. Are you sure you want to continue [ENTER]..."

case "$CLOUD_PROVIDER" in
    "azure")
        az group delete --name $RESOURCE_GROUP_NAME       
        ;;
    "aws")
        source ./tasks/aws/deleteAll.sh
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac

rm -rf $TEMP_EXE_FOLDER