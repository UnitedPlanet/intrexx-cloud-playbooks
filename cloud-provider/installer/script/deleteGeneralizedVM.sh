#!/usr/bin/env bash

#Importing configuration variables
source variables.sh
source ./tasks/general/executionMethods.sh

case "$CLOUD_PROVIDER" in
    "azure")
        checkAndRun "/tasks/azure/deleteGeneralizedVM.sh"
        ;;
    "aws")
        loadScript "createIntrexxVM.sh" "APPSERVER"
        aws ec2 terminate-instances --instance-ids $APPSERVER_INSTANCE_ID
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac