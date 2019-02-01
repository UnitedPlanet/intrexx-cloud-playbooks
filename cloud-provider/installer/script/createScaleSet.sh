#!/bin/bash

#Importing configuration variables
source variables.sh

LOG_PREFIX="[INTREXX_CLOUD] -"
export SCRIPT_BASE_PATH="$(pwd)"

source ./tasks/general/executionMethods.sh

echo "$LOG_PREFIX Converting machine $APPSERVER_NAME to scale set $SCALE_SET_NAME. This operation will render $APPSERVER_NAME unusable, as it will remove all personal information."
case "$CLOUD_PROVIDER" in
    "azure")
        if    [ $OPERATING_SYSTEM == "win" ]; then
            read -p "$LOG_PREFIX Make sure that you have generalized the AppServer VM before, otherwise Azure won't be able to create an image [ENTER]."
        fi
        checkAndRun "/tasks/azure/captureImage.sh"
        checkAndRun "/tasks/azure/createScaleSet.sh"
        #source ./tasks/azure/deleteAppServerVM.sh    
        ;;
    "aws")
        loadScript "createVirtualNetwork.sh"
        loadScript "generalConfiguration.sh"
        loadScript "createIntrexxVM.sh" "APPSERVER"
        loadScript "createServicesVM.sh" "SERVICES"
        checkLoadAndRun "/tasks/aws/createScaleSet.sh"
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac

