#!/usr/bin/env bash

#Importing configuration variables
source variables.sh    

LOG_PREFIX="[CREATE MACHINE - $1 ] -"

## This script creates a vm used to deploy intrexx on it. The following are the parameters:
## $1 = name of the instance
## $2 = machine type 
## $3 = private ip of the instance

echo "$LOG_PREFIX Creating machine $1"
if      [ $OPERATING_SYSTEM == "win" ]; then 
    az vm create                                \
        --resource-group $RESOURCE_GROUP_NAME   \
        --name $1                               \
        --image $AZ_OS_TYPE_WIN                 \
        --admin-username $AZ_ADMIN_USER_WIN     \
        --admin-password $AZ_ADMIN_PW_WIN       \
        --authentication-type password          \
        --location $AZ_AVAILABILITY_ZONE        \
        --size $2                               \
        --nsg-rule rdp                          \
        --vnet-name $VIRTUAL_NETWORK_NAME       \
        --subnet $VIRTUAL_SUBNETWORK_NAME       \
        --public-ip-address-allocation static   \
        --private-ip-address $3                 \
        --data-disk-sizes-gb $AZ_DISK_SIZE_WIN  \
        --data-disk-caching ReadWrite           \
        --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE
    #az vm disk attach 
    #    --vm-name $1                            \
    #    --name "$1"DataDisk                     \
    #    --new                                   \
    #    --resource-group $RESOURCE_GROUP_NAME   \
    #    --size-gb $AZ_DISK_SIZE_WIN             \
    #    --sku Premium_LRS
elif    [ $OPERATING_SYSTEM == "linux" ]; then
    az vm create                                \
        --resource-group $RESOURCE_GROUP_NAME   \
        --name $1                               \
        --image $AZ_OS_TYPE_LINUX               \
        --location $AZ_AVAILABILITY_ZONE        \
        --size $2                               \
        --availability-set $AVAILABILITY_SET    \
        --authentication-type ssh               \
        --admin-username $AZ_ADMIN_USER_LINUX   \
        --ssh-key-value $SSH_KEY".pub"          \
        --nsg-rule ssh                          \
        --vnet-name $VIRTUAL_NETWORK_NAME       \
        --subnet $VIRTUAL_SUBNETWORK_NAME       \
        --public-ip-address-allocation static   \
        --private-ip-address $3                 \
        --data-disk-sizes-gb $AZ_DISK_SIZE_LINUX \
        --data-disk-caching ReadWrite           \
        --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE
fi
              
echo "$LOG_PREFIX Machine $1 created. Waiting until the instance is running."
# For some reason it sometimes failes when no pause is added before the wait operation
sleep 5
az vm wait --name $1 --resource-group $RESOURCE_GROUP_NAME --created

MACHINE_PUBLIC_IP=$(az vm list-ip-addresses --resource-group $RESOURCE_GROUP_NAME --name $1 --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" -o tsv)
#AZ needs some time to build everything up...
sleep 10
echo "$LOG_PREFIX Public ip of the machine $1 vm is $MACHINE_PUBLIC_IP ."