#!/usr/bin/env bash

#Importing configuration variables
source variables.sh

TEMP_HOSTS_FILE="~/cloud-playbooks/hosts_temp"

case "$CLOUD_PROVIDER" in
    "azure")
        PROVISIONING_PUBLIC_IP=$(az vm list-ip-addresses --resource-group $RESOURCE_GROUP_NAME --name $PROVISIONING_NAME --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" -o tsv)                 
        ;;
    "aws")
        
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac

echo "[PROVISIONING_MACHINE] - Copying installation files to $PROVISIONING_PUBLIC_IP"

ssh -o "StrictHostKeyChecking no" -i $SSH_KEY $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP "mkdir -p /home/$AWS_ADMIN_USER_LINUX/cloud-playbooks $AWS_ADMIN_USER_LINUX"

if      [ $OPERATING_SYSTEM == "linux" ]; then 
    echo "[PROVISIONING_MACHINE] - Copying files for the ansible linux installation"
    scp -C -r -o "StrictHostKeyChecking no" -i $SSH_KEY ../../../linux/* $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP:~/cloud-playbooks/ 
    #Add the hostname of the db to the hosts file
    ssh -o "StrictHostKeyChecking no" -i $SSH_KEY $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP "echo '[dbserver]' > $TEMP_HOSTS_FILE && echo $DB_DNS_ADDRESS >> $TEMP_HOSTS_FILE && echo "" >> $TEMP_HOSTS_FILE && cat ~/cloud-playbooks/hosts_azure >> $TEMP_HOSTS_FILE"
    ssh -o "StrictHostKeyChecking no" -i $SSH_KEY $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP "mv $TEMP_HOSTS_FILE ~/cloud-playbooks/hosts_$CLOUD_PROVIDER"
    echo "[PROVISIONING_MACHINE] - Download Intrexx setup"
    ssh -o "StrictHostKeyChecking no" -i $SSH_KEY $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP "wget -O ~/cloud-playbooks/files/$INTREXX_SETUP_LINUX https://download.unitedplanet.com/intrexx/90000/$INTREXX_SETUP_LINUX >> /dev/null"
    echo "[PROVISIONING_MACHINE] - Download Intrexx setup finished"
elif    [ $OPERATING_SYSTEM == "win" ]; then
    echo "[PROVISIONING_MACHINE] - Copying files for the ansible windows installation"
    scp -C -r -o "StrictHostKeyChecking no" -i $SSH_KEY ../../../windows/* $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP:~/cloud-playbooks/ 
    #Add the hostname of the db to the hosts file
    ssh -o "StrictHostKeyChecking no" -i $SSH_KEY $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP "echo '[dbserver]' > $TEMP_HOSTS_FILE && echo $DB_DNS_ADDRESS >> $TEMP_HOSTS_FILE && echo "" >> $TEMP_HOSTS_FILE && cat ~/cloud-playbooks/hosts >> $TEMP_HOSTS_FILE"
    ssh -o "StrictHostKeyChecking no" -i $SSH_KEY $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP "mv $TEMP_HOSTS_FILE ~/cloud-playbooks/hosts_$CLOUD_PROVIDER"
    echo "[PROVISIONING_MACHINE] - Download Intrexx setup"
    ssh -o "StrictHostKeyChecking no" -i $SSH_KEY $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP "wget -O ~/cloud-playbooks/files/$INTREXX_SETUP_WIN https://download.unitedplanet.com/intrexx/90000/$INTREXX_SETUP_WIN >> /dev/null" 
    echo "[PROVISIONING_MACHINE] - Download Intrexx setup finished"
fi

#create db config file and send to provisioning instance
TEMP_DB_CONFIG_FILE=~/temp_db_config_file.yml
echo "ix_db_hostname: $DB_DNS_ADDRESS" > $TEMP_DB_CONFIG_FILE  
case "$CLOUD_PROVIDER" in
    "azure")
        echo "ix_db_port: $AZ_DATABASE_PORT"  >> $TEMP_DB_CONFIG_FILE
        echo "ix_db_type: $AZ_DATABASE_DRIVER"  >> $TEMP_DB_CONFIG_FILE
        ;;
    "aws")
        echo "ix_db_port: $AWS_DATABASE_PORT"  >> $TEMP_DB_CONFIG_FILE
        echo "ix_db_type: $AWS_DATABASE_DRIVER"  >> $TEMP_DB_CONFIG_FILE
        ;;        
    *)
        echo "$LOG_PREFIX The specified cloud provider \"$CLOUD_PROVIDER\" is not valid."
        exit 1
esac

echo "ix_db_database_name: $DB_NAME" >> $TEMP_DB_CONFIG_FILE  
echo "ix_db_create: true" >> $TEMP_DB_CONFIG_FILE  
echo "ix_db_admin_login: $DB_SERVER_ADMIN_USER" >> $TEMP_DB_CONFIG_FILE  
echo "ix_db_admin_password: $DB_SERVER_ADMIN_PASSWD" >> $TEMP_DB_CONFIG_FILE  
echo "ix_db_user_login: $DB_SERVER_ADMIN_USER" >> $TEMP_DB_CONFIG_FILE  
echo "ix_db_user_password: $DB_SERVER_ADMIN_PASSWD" >> $TEMP_DB_CONFIG_FILE
echo "ix_portal_name: $PORTAL_NAME" >> $TEMP_DB_CONFIG_FILE
echo "ix_efs_dns_address: $EFS_DNS_ADDRESS" >> $TEMP_DB_CONFIG_FILE

scp -C -o "StrictHostKeyChecking no" -i $SSH_KEY $TEMP_DB_CONFIG_FILE $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP:~/cloud-playbooks/dbVars.yml 
rm $TEMP_DB_CONFIG_FILE

ZIP=$DATA_DIR/$INTREXX_ZIP

if    [ -f $ZIP ]; then
   scp -C -o "StrictHostKeyChecking no" -i $SSH_KEY $ZIP $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP:~/cloud-playbooks/files/$INTREXX_ZIP
fi

echo "[PROVISIONING_MACHINE] - Copying keys to $PROVISIONING_PUBLIC_IP"
scp -o "StrictHostKeyChecking no" -i $SSH_KEY $WORK_DIR/id_rsa* $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP:~/.ssh/           
ssh -o "StrictHostKeyChecking no" -i $SSH_KEY $AWS_ADMIN_USER_LINUX@$PROVISIONING_PUBLIC_IP chmod 600 /home/$AWS_ADMIN_USER_LINUX/.ssh/id_rsa*