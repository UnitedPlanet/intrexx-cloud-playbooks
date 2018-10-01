#!/usr/bin/env bash

DEBIAN_FRONTEND=noninteractive

#Importing configuration variables
source variables.sh


FILEPATH=$1
RECOVERY_FILE=$SCRIPT_BASE_PATH/$1
if [ -e $RECOVERY_FILE ]; then
    source $RECOVERY_FILE
else
    echo "#!/bin/bash" > $RECOVERY_FILE
    echo "" >> $RECOVERY_FILE
fi

APPSERVER_PUBLIC_IP=$(aws ec2 describe-instances                             \
            --instance-ids $APPSERVER_INSTANCE_ID                            \
            --output text                                                       \
            --query 'Reservations[0].Instances[0].[PublicIpAddress]')

aws ec2 stop-instances --instance-ids $APPSERVER_INSTANCE_ID > '/dev/null'
    
            
echo "[AUTOSCALING] - APPSERVER machine has been shutdown"

#Wait until APPSERVER has been shutdown
aws ec2 wait instance-stopped --instance-ids $APPSERVER_INSTANCE_ID


if [ -z ${APPSERVER_VOLUME_ID+"x"} ]; then
    #Create Snapshot (this only works as long as there are only one block device)
    APPSERVER_VOLUME_ID=$(aws ec2 describe-instances --instance-id $APPSERVER_INSTANCE_ID --query "Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.[VolumeId]" --output text)
    echo "APPSERVER_VOLUME_ID=$APPSERVER_VOLUME_ID" >> $RECOVERY_FILE
fi


if [ -z ${APPSERVER_SNAPSHOT_ID+"x"} ]; then
    APPSERVER_SNAPSHOT_ID=$(aws ec2 create-snapshot --volume-id $APPSERVER_VOLUME_ID --query "[SnapshotId]" --output text)
    echo "APPSERVER_SNAPSHOT_ID=$APPSERVER_SNAPSHOT_ID" >> $RECOVERY_FILE
    echo "[AUTOSCALING] - Creating the image of the appserver, this can take a bit..." 
else
    echo "[AUTOSCALING] - Snapshot creation skipped" 
fi

sleep 2

exit_status=1
while [ "${exit_status}" != "0" ]
do
    aws ec2 wait snapshot-completed --snapshot-ids $APPSERVER_SNAPSHOT_ID
    exit_status="$?"

done

if [ -z ${AUTOSCALE_IMAGE+"x"} ]; then
    #Create ami from APPSERVER
    AUTOSCALE_IMAGE=$(aws ec2 register-image --architecture x86_64 --block-device-mappings "[{\"DeviceName\": \"/dev/sda1\",\"Ebs\":{\"SnapshotId\":\"$APPSERVER_SNAPSHOT_ID\"}}]" --name $IMG_NAME --root-device-name "/dev/sda1" --virtualization-type hvm --output text)
    echo "AUTOSCALE_IMAGE=$AUTOSCALE_IMAGE" >> $RECOVERY_FILE
fi

echo "[AUTOSCALING] - Creating the load balancer"
if [ -z ${TARGET_GROUP_ARN+"x"} ]; then
    #Create the load balancer
    TARGET_GROUP_ARN=$(aws elbv2 create-target-group                    \
            --name "ForwardTargetGroup"                                 \
            --protocol HTTP                                             \
            --port $INTREXX_WEB_BACKEND_PORT                            \
            --vpc-id $VIRTUAL_NETWORK_ID                                \
            --health-check-protocol HTTP                                \
            --health-check-path $HEALTH_PROBE_PATH                      \
            --health-check-interval-seconds $HEALTH_PROBE_INTERVAL      \
            --output text                                               \
            --query "TargetGroups[0].[TargetGroupArn]")
    echo "TARGET_GROUP_ARN=$TARGET_GROUP_ARN" >> $RECOVERY_FILE
else
    echo "[AUTOSCALING] - Target group creation skipped"
fi


if [ -z ${LB_ARN+"x"} ]; then
    LB_ARN=$(aws elbv2 create-load-balancer                                                             \
        --name $LOAD_BALANCER_NAME                                                                      \
        --subnets $VIRTUAL_SUBNETWORK_EXTERNAL_ONE_ID $VIRTUAL_SUBNETWORK_EXTERNAL_TWO_ID               \
        --security-groups $LB_SECURITY_GROUP_ID                                                         \
        --scheme "internet-facing"                                                                      \
        --tags Key=RSG,Value=$RESOURCE_GROUP_NAME                                                       \
        --query "LoadBalancers[0].[LoadBalancerArn]"                          \
        --output text)

    #Add the listeners to forward requests through the LB
    aws elbv2 create-listener --load-balancer-arn $LB_ARN --protocol HTTP --port $INTREXX_WEB_FRONTEND_PORT --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN  >/dev/null
    
    #TODO TO ENABLE HTTPS
    if $INTREXX_HTTPS_ENABLE; then
        if [ -z $INTREXX_HTTPS_CERTIFICATE_PEM ] || [ -z $INTREXX_HTTPS_CERTIFICATE_CHAIN_PEM ] || \
           [ -z $INTREXX_HTTPS_CERTIFICATE_PRIVATE_KEY_PEM ] || [ -z $INTREXX_HTTPS_CERTIFICATE_SECURITY_POLICY ]; then
            echo "[AUTOSCALING] - One or more variables regarding the HTTS certificate is/are not set, therefore HTTPS can not be deployed. Please check the values of the variables INTREXX_HTTPS_CERTIFICATE*_PEM in the variables.sh file!"
        else 
            CERT_ARN=$(aws acm import-certificate --certificate file://$INTREXX_HTTPS_CERTIFICATE_PEM \
                            --certificate-chain file://$INTREXX_HTTPS_CERTIFICATE_CHAIN_PEM \
                            --private-key file://$INTREXX_HTTPS_CERTIFICATE_PRIVATE_KEY_PEM --output text)
            aws elbv2 create-listener   --load-balancer-arn $LB_ARN \
                                        --protocol HTTPS --port $INTREXX_WEB_FRONTEND_PORT_SSL \
                                        --ssl-policy $INTREXX_HTTPS_CERTIFICATE_SECURITY_POLICY --certificates CertificateArn=$CERT_ARN \
                                        --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN  >/dev/null
        fi
    fi
    
else
    echo "[AUTOSCALING] - Load balancer creation skipped"
fi

echo "LB_ARN=$LB_ARN" >> $RECOVERY_FILE

echo "[AUTOSCALING] - Load balancer with the arn $LB_ARN has been created"



if      [ $OPERATING_SYSTEM == "win" ]; then 
    APPSERVER_INSTANCE_TYPE=$AWS_INSTANCE_TYPE_APPSERVER_WIN
elif    [ $OPERATING_SYSTEM == "linux" ]; then
    APPSERVER_INSTANCE_TYPE=$AWS_INSTANCE_TYPE_APPSERVER_LINUX
fi


#Create the lauch configuration based on the APPSERVER ami
LAUNCH_CONFIG_EXISTS=$(aws autoscaling describe-launch-configurations --launch-configuration-names $LAUNCH_CONFIG_NAME --query "LaunchConfigurations[*]" --output text)
if [ -z "$LAUNCH_CONFIG_EXISTS" ]; then
    aws autoscaling create-launch-configuration                     \
        --launch-configuration-name $LAUNCH_CONFIG_NAME             \
        --image-id $AUTOSCALE_IMAGE                                 \
        --instance-type $APPSERVER_INSTANCE_TYPE                        \
        --key-name $SERVICES_KEY_NAME                                 \
        --security-groups $INTERNAL_SECURITY_GROUP_ID                     \
        --no-associate-public-ip-address  >/dev/null
fi

#Create the actual launch configuration
AUTO_SCALE_GROUP_EXISTS=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $SCALE_SET_NAME --output text)
if [ -z "$AUTO_SCALE_GROUP_EXISTS" ]; then
    aws autoscaling create-auto-scaling-group                                   \
        --auto-scaling-group-name $SCALE_SET_NAME                               \
        --launch-configuration-name $LAUNCH_CONFIG_NAME                         \
        --min-size $SCALE_SET_MIN                                               \
        --max-size $SCALE_SET_MAX                                               \
        --desired-capacity $SCALE_SET_DESIRED_SIZE                              \
        --target-group-arns $TARGET_GROUP_ARN                                   \
        --vpc-zone-identifier $VIRTUAL_SUBNETWORK_DB_ONE_ID                     \
        --tags Key=RSG,Value=$RESOURCE_GROUP_NAME      >/dev/null
fi

echo "[AUTOSCALING] - The auto scaling group has been created"

aws ec2 modify-instance-attribute --instance-id $SERVICES_INSTANCE_ID  --groups $INTERNAL_SECURITY_GROUP_ID $EXTERNAL_SECURITY_GROUP_SOAP_ID
echo "[AUTOSCALING] - The services instance $SERVICES_INSTANCE_ID is no longer reachable via ssh"

LB_DNS=$(aws elbv2 describe-load-balancers --names $LOAD_BALANCER_NAME --query "LoadBalancers[0].[DNSName]" --output text)

echo "[AUTOSCALING] - The instance $APPSERVER_NAME can now be terminated, the autoscaling group is based on the snapshot $APPSERVER_SNAPSHOT_ID."
echo "[AUTOSCALING] - DON'T FORGET to STOP the provisioning instance (DO NOT TERMINATE THIS INSTANCE, it might be needed to deploy patches)."
echo "[AUTOSCALING] - The load balancer $LOAD_BALANCER_NAME can be reached via $LB_DNS"