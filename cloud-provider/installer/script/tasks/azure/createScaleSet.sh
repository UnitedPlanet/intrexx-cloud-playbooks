#!/bin/bash

#Importing configuration variables
source variables.sh

echo "[SCALE_SET] - Creating ScaleSet $SCALE_SET_NAME based on image $IMG_NAME with $SCALE_SET_DESIRED_SIZE instances"

if      [ $OPERATING_SYSTEM == "win" ]; then 
    az vmss create                                  \
        --resource-group $RESOURCE_GROUP_NAME       \
        --name $SCALE_SET_NAME                      \
        --image $IMG_NAME                           \
        --instance-count $SCALE_SET_DESIRED_SIZE    \
        --admin-username $AZ_ADMIN_USER_WIN         \
        --admin-password $AZ_ADMIN_PW_WIN           \
        --authentication-type password              \
        --vnet-name $VIRTUAL_NETWORK_NAME           \
        --subnet $VIRTUAL_SUBNETWORK_NAME           \
        --location $AZ_AVAILABILITY_ZONE            \
        --public-ip-address lbPublicIp              \
        --public-ip-address-allocation static       \
        --vm-sku $AZ_INSTANCE_TYPE_APPSERVER_WIN        \
        --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE
elif    [ $OPERATING_SYSTEM == "linux" ]; then
    az vmss create                                  \
        --resource-group $RESOURCE_GROUP_NAME       \
        --name $SCALE_SET_NAME                      \
        --image $IMG_NAME                           \
        --instance-count $SCALE_SET_DESIRED_SIZE    \
        --authentication-type ssh                   \
        --admin-username $AZ_ADMIN_USER_LINUX       \
        --vnet-name $VIRTUAL_NETWORK_NAME           \
        --subnet $VIRTUAL_SUBNETWORK_NAME           \
        --location $AZ_AVAILABILITY_ZONE            \
        --public-ip-address lbPublicIp              \
        --public-ip-address-allocation static       \
        --vm-sku $AZ_INSTANCE_TYPE_APPSERVER_LINUX      \
        --ssh-key-value $WORK_DIR/id_rsa.pub        \
        --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE
fi
echo "[SCALE_SET] - ScaleSet $SCALE_SET_NAME created with fixed size. Please customize it manually if you want to react to usage peaks"


echo "[SCALE_SET] - Adding probe to LoadBalancer $LOAD_BALANCER_NAME. Checking path $HEALTH_PROBE_PATH"
az network lb probe create \
  --resource-group $RESOURCE_GROUP_NAME \
  --lb-name $LOAD_BALANCER_NAME \
  --name $HEALTH_PROBE_NAME \
  --protocol Http \
  --port $INTREXX_WEB_BACKEND_PORT \
  --path $HEALTH_PROBE_PATH \
  --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE

echo "[SCALE_SET] - Creating rule on load balancer $LOAD_BALANCER_NAME from port $INTREXX_WEB_FRONTEND_PORT(Frontend) to $INTREXX_WEB_BACKEND_PORT(Backend)"
az network lb rule create \
  --resource-group $RESOURCE_GROUP_NAME \
  --lb-name $LOAD_BALANCER_NAME \
  --name HTTP_RULE \
  --protocol Tcp \
  --frontend-port $INTREXX_WEB_FRONTEND_PORT \
  --backend-port $INTREXX_WEB_BACKEND_PORT \
  --frontend-ip-name loadBalancerFrontEnd \
  --backend-pool-name $LOAD_BALANCER_NAME"BEPool" \
  --probe-name $HEALTH_PROBE_NAME
  --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE

echo "[SCALE_SET] - Executing extension"
if      [ $OPERATING_SYSTEM == "win" ]; then 
    echo "[SCALE_SET] - Executing extension"
    #az vmss extension set --resource-group $RESOURCE_GROUP_NAME --vmss-name $SCALE_SET_NAME --name CustomScriptextension --publisher Microsoft.Compute --settings $SCRIPT_BASE_PATH/tasks/initScripts/scaleSetExtension.json  >> $OUTPUT_FILE
fi
