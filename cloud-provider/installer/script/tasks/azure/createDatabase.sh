#!/bin/bash

#Importing configuration variables
source variables.sh

# $1 = path to script

echo "[SQL_SERVER] - Creating sql server $DB_SERVER_NAME in location $AZ_AVAILABILITY_ZONE"
az $AZ_DATABASE_DRIVER server create \
  --name $DB_SERVER_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --sku-name $AZ_DATABASE_TYPE \
  --admin-user $DB_SERVER_ADMIN_USER \
  --admin-password $DB_SERVER_ADMIN_PASSWD \
  --location $AZ_AVAILABILITY_ZONE \
  --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE

echo "[SQL_SERVER] - Opening ports in firewall"
# The rule below can be ignored since the rule 'allow_azure_clients' is already allowing all internal traffic, which got the ip range 10.0.0.0/16
az $AZ_DATABASE_DRIVER server firewall-rule create \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0 \
  --server $DB_SERVER_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --name intrexx_access \
  --output $AZ_OUTPUT_FORMAT >> $OUTPUT_FILE


DB_DNS_ADDRESS=$(az $AZ_DATABASE_DRIVER server show --name $DB_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME --query "fullyQualifiedDomainName" --output tsv)

#create file to start over if scripts fail at a later point
mkdir -p $TEMP_EXE_FOLDER
THIS_FILE_NAME="${BASH_SOURCE[0]}"
echo "#!/bin/bash" > $SCRIPT_BASE_PATH/$1
echo  ""  >> $SCRIPT_BASE_PATH/$1
echo "DB_DNS_ADDRESS=\$(az $AZ_DATABASE_DRIVER server show --name $DB_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME --query \"fullyQualifiedDomainName\" --output tsv)"  >> $SCRIPT_BASE_PATH/$1
