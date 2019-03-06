#!/bin/bash

#Importing configuration variables
source variables.sh

mkdir -p $TEMP_EXE_FOLDER
LOG_PREFIX="[INTREXX_CLOUD] -"

export SCRIPT_BASE_PATH="$(pwd)"

FILE_DIR_AZURE="tasks/azure"
FILE_DIR_AWS="tasks/aws"
FILE_DIR_COMMON="tasks/common"

echo "$LOG_PREFIX Recreating the entire infrastructure"
echo "$LOG_PREFIX Sending output to output file" > $OUTPUT_FILE

read -p "LOG_PREFIX About to create infraestrucutre to run Intrexx in $CLOUD_PROVIDER on the OS $OPERATING_SYSTEM. Before proceeding double-check your settings in variables.sh and press [ENTER] to continue..."

source ./tasks/general/executionMethods.sh

## Check some variables of the variables file ##
source ./tasks/general/checkVariables.sh

## Set base dir path to use for scripts which exist for all cloud providers
case "$CLOUD_PROVIDER" in
    "azure")
        BASE_DIR_PATH=$FILE_DIR_AZURE            
        ;;
    "aws")
        BASE_DIR_PATH=$FILE_DIR_AWS
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac

## Create the ssh keys ##
checkAndRun "$FILE_DIR_COMMON/createProvisioningKeys.sh"

## Preparation tasks ##
case "$CLOUD_PROVIDER" in
    "azure")
        checkAndRun "$BASE_DIR_PATH/deleteGroup.sh"
        checkAndRun "$BASE_DIR_PATH/createGroup.sh" 
        checkAndRun "$BASE_DIR_PATH/createAvailabilitySet.sh"      
        checkAndRun "$BASE_DIR_PATH/createVirtualNetwork.sh"
        ;;
    "aws")
        checkAndRunOrLoad "$BASE_DIR_PATH/createVirtualNetwork.sh"
        checkAndRunOrLoad "$BASE_DIR_PATH/generalConfiguration.sh"
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac

## Create all machines ##
case "$CLOUD_PROVIDER" in
    "azure")
        if      [ $OPERATING_SYSTEM == "win" ]; then 
            checkAndRunRenaming "$BASE_DIR_PATH/createIntrexxVM.sh" "SERVICES" $SERVICES_NAME $AZ_INSTANCE_TYPE_SERVICES_WIN $SERVICES_PRIVATE_IP       
            checkAndRunRenaming "$BASE_DIR_PATH/createIntrexxVM.sh" "APPSERVER" $APPSERVER_NAME $AZ_INSTANCE_TYPE_APPSERVER_WIN $APPSERVER_PRIVATE_IP       
        elif    [ $OPERATING_SYSTEM == "linux" ]; then
            checkAndRunRenaming "$BASE_DIR_PATH/createServicesVM.sh" "SERVICES" $SERVICES_NAME $AZ_INSTANCE_TYPE_SERVICES_LINUX $SERVICES_PRIVATE_IP   
            checkAndRunRenaming "$BASE_DIR_PATH/createIntrexxVM.sh" "APPSERVER" $APPSERVER_NAME $AZ_INSTANCE_TYPE_APPSERVER_LINUX $APPSERVER_PRIVATE_IP       
        fi
        checkAndRunRenaming "$BASE_DIR_PATH/createLinuxVM.sh" "PROVISIONING" $PROVISIONING_NAME $AZ_INSTANCE_TYPE_PROVISIONING_LINUX $PROVISIONING_PRIVATE_IP
        ;;
    "aws")
        if      [ $OPERATING_SYSTEM == "win" ]; then 
            checkAndRunOrLoad "$BASE_DIR_PATH/createIntrexxVM.sh" "SERVICES" $SERVICES_NAME $AWS_INSTANCE_TYPE_SERVICES_WIN $SERVICES_PRIVATE_IP                       "tasks/initScripts/launchScript.ps1"   $EXTERNAL_SECURITY_GROUP_SSH_ID  $EXTERNAL_SECURITY_GROUP_SOAP_ID $INTERNAL_SECURITY_GROUP_ID
            checkAndRunOrLoad "$BASE_DIR_PATH/createIntrexxVM.sh" "APPSERVER" $APPSERVER_NAME $AWS_INSTANCE_TYPE_APPSERVER_WIN $APPSERVER_PRIVATE_IP                           "tasks/initScripts/launchScript.ps1"   $INTERNAL_SECURITY_GROUP_ID $EXTERNAL_SECURITY_GROUP_SSH_ID      
        elif    [ $OPERATING_SYSTEM == "linux" ]; then
            checkAndRunOrLoad "$BASE_DIR_PATH/createServicesVM.sh" "SERVICES" $SERVICES_NAME $AWS_INSTANCE_TYPE_SERVICES_LINUX $SERVICES_PRIVATE_IP                                                $EXTERNAL_SECURITY_GROUP_SSH_ID $EXTERNAL_SECURITY_GROUP_SOAP_ID $INTERNAL_SECURITY_GROUP_ID
            checkAndRunOrLoad "$BASE_DIR_PATH/createIntrexxVM.sh" "APPSERVER" $APPSERVER_NAME $AWS_INSTANCE_TYPE_APPSERVER_LINUX $APPSERVER_PRIVATE_IP                                                    $INTERNAL_SECURITY_GROUP_ID $EXTERNAL_SECURITY_GROUP_SSH_ID
        fi 
        checkAndRunOrLoad "$BASE_DIR_PATH/createLinuxVM.sh" "PROVISIONING" $PROVISIONING_NAME $AWS_INSTANCE_TYPE_PROVISIONING_LINUX $PROVISIONING_PRIVATE_IP                              $EXTERNAL_SECURITY_GROUP_SSH_ID  $INTERNAL_SECURITY_GROUP_ID
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac

## Create the database ##
checkAndRunOrLoad "$BASE_DIR_PATH/createDatabase.sh"

## Create the filesystem ##
case "$CLOUD_PROVIDER" in
    "azure")
                
        ;;
    "aws")
        checkAndRunOrLoad "$BASE_DIR_PATH/createFilesystem.sh"
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac

## Provision all instances ##
case "$CLOUD_PROVIDER" in
    "azure")
        if      [ $OPERATING_SYSTEM == "win" ]; then 
            checkAndRunRenaming "$FILE_DIR_COMMON/initVM.sh" "SERVICES" $SERVICES_NAME "tasks/initScripts/launchScript.json" $OPERATING_SYSTEM
            checkAndRunRenaming "$FILE_DIR_COMMON/initVM.sh" "APPSERVER"  $APPSERVER_NAME  "tasks/initScripts/launchScript.json" $OPERATING_SYSTEM   
        elif    [ $OPERATING_SYSTEM == "linux" ]; then
            checkAndRunRenaming "$FILE_DIR_COMMON/initVM.sh" "SERVICES" $SERVICES_NAME "tasks/initScripts/allVM-init.sh" $OPERATING_SYSTEM
            checkAndRunRenaming "$FILE_DIR_COMMON/initVM.sh" "APPSERVER"  $APPSERVER_NAME  "tasks/initScripts/allVM-init.sh" $OPERATING_SYSTEM
        fi
        checkAndRunRenaming "$FILE_DIR_COMMON/initVM.sh" "PROVISIONING"  $PROVISIONING_NAME  "tasks/initScripts/provisioningVM-init.sh" "linux" $DB_DNS_ADDRESS    
        ;;
    "aws")
        if    [ $OPERATING_SYSTEM == "linux" ]; then
            checkAndRunRenaming "$FILE_DIR_COMMON/initVM.sh" "SERVICES" $SERVICES_NAME "tasks/initScripts/allVM-init.sh" $OPERATING_SYSTEM $SERVICES_INSTANCE_ID
            checkAndRunRenaming "$FILE_DIR_COMMON/initVM.sh" "APPSERVER"  $APPSERVER_NAME "tasks/initScripts/allVM-init.sh" $OPERATING_SYSTEM $APPSERVER_INSTANCE_ID
        fi
        checkAndRunRenaming "$FILE_DIR_COMMON/initVM.sh" "PROVISIONING"  $PROVISIONING_NAME "tasks/initScripts/provisioningVM-init.sh" "linux" $PROVISIONING_INSTANCE_ID $DB_DNS_ADDRESS
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac

## Copy the installation files to the provisioning machine ##
checkAndRun "$FILE_DIR_COMMON/copyFiles.sh"

## Reboot all instances ##
case "$CLOUD_PROVIDER" in
    "azure")
        checkAndRunRenaming "$FILE_DIR_COMMON/reboot.sh" "APPSERVER"  $APPSERVER_NAME
        checkAndRunRenaming "$FILE_DIR_COMMON/reboot.sh" "SERVICES"  $SERVICES_NAME 
        checkAndRunRenaming "$FILE_DIR_COMMON/reboot.sh" "PROVISIONING"  $PROVISIONING_NAME       
        ;;
    "aws")
        checkAndRunRenaming "$FILE_DIR_COMMON/reboot.sh" "APPSERVER"  $APPSERVER_INSTANCE_ID    "APPSERVER"
        checkAndRunRenaming "$FILE_DIR_COMMON/reboot.sh" "SERVICES"  $SERVICES_INSTANCE_ID      "SERVICES" 
        checkAndRunRenaming "$FILE_DIR_COMMON/reboot.sh" "PROVISIONING"  $PROVISIONING_INSTANCE_ID "PROVISIONING"
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac

 

case "$CLOUD_PROVIDER" in
    "azure")
        PROVISIONING_PUBLIC_IP=$(az vm list-ip-addresses --resource-group $RESOURCE_GROUP_NAME --name $PROVISIONING_NAME --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" -o tsv)
        echo "$LOG_PREFIX infrastructure ready. Please login to the provisioning machine by using ssh -i $SSH_KEY $AZ_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP and install INTREXX via Ansible."                
        ;;
    "aws")
        echo "$LOG_PREFIX infrastructure ready. Please login to the provisioning machine by using ssh -i $SSH_KEY $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP and install INTREXX via Ansible."
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac
echo "$LOG_PREFIX Then proceed to creating the ScaleSet via createScaleSet.sh"

exit 1

############################################################################# TO DELETE
case "$CLOUD_PROVIDER" in
    "azure")
                
        ;;
    "aws")
        
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac

if      [ $OPERATING_SYSTEM == "win" ]; then 

elif    [ $OPERATING_SYSTEM == "linux" ]; then
    
fi