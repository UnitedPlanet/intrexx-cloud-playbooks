#!/bin/bash

LOG_PREFIX="[INIT-VM-$1] -"

## Parameters are defined as follows:
## AWS with LINUX : $1, name for logging,   $2 = init script,   $3 = operationSystem,   $4 = instance id
## AZ with WIN    : $1 = name of instance,  $2 = init script,   $3 = operationSystem,
## AZ with LINUX  : $1 = name of instance,  $2 = init script,   $3 = operationSystem,
OP_TO_INIT=$3
echo "$LOG_PREFIX provisioning the machine $1."
case "$CLOUD_PROVIDER" in
    "azure")
        if [ $OP_TO_INIT == "win" ]; then
            az vm extension set --resource-group $RESOURCE_GROUP_NAME --vm-name $1 --name CustomScriptExtension --publisher Microsoft.Compute --version 1.9 --settings $SCRIPT_BASE_PATH/$2 >> $OUTPUT_FILE 
        elif    [ $OP_TO_INIT == "linux" ]; then
            MACHINE_PUBLIC_IP=$(az vm list-ip-addresses --resource-group $RESOURCE_GROUP_NAME --name $1 --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" -o tsv)
            USERNAME=$AZ_ADMIN_USER_LINUX
        fi
        ;;
    "aws")
        if    [ $OP_TO_INIT == "linux" ]; then
            MACHINE_PUBLIC_IP="$(aws ec2 describe-instances                 \
            --instance-ids $4                                               \
            --output text                                                   \
            --query 'Reservations[0].Instances[0].[PublicIpAddress]')"
            USERNAME=$AWS_ADMIN_USER_LINUX
        fi
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac

if    [ $OP_TO_INIT == "linux" ]; then
    echo "$LOG_PREFIX run bash init script on $1."
    cat $WORK_DIR/id_rsa.pub | ssh -o "StrictHostKeyChecking no" -i $SSH_KEY $USERNAME@$MACHINE_PUBLIC_IP 'cat >> .ssh/authorized_keys'
    sleep 2
  
    ssh -o "StrictHostKeyChecking no"  -i $SSH_KEY  $USERNAME@$MACHINE_PUBLIC_IP 'sudo -H bash -s' < $SCRIPT_BASE_PATH/$2 $MACHINE_PUBLIC_IP $USERNAME "${@: -1}"
fi
  
