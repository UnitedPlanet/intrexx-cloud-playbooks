#!/bin/bash

#Importing configuration variables
source variables.sh

echo "[SQL_SERVER] - Creating sql server $DB_SERVER_NAME"

aws rds create-db-instance                        \
  --db-name $DB_SERVER_NAME                       \
  --db-instance-identifier $DB_IDENTIFIER         \
  --db-instance-class $AWS_DATABASE_TYPE          \
  --engine postgres                               \
  --master-username $DB_SERVER_ADMIN_USER         \
  --master-user-password $DB_SERVER_ADMIN_PASSWD  \
  --vpc-security-group-ids $DB_SECURITY_GROUP_ID  \
  --engine-version $AWS_DATABASE_VERSION          \
  --no-publicly-accessible                        \
  --allocated-storage 5                           \
  --db-subnet-group-name $DB_SUBNET_GROUP         \
  --tag Key=RSG,Value="$RESOURCE_GROUP_NAME"      \
  --output json                             >/dev/null

echo "[SQL_SERVER] - DB has been created, waiting for the db to be set up"

sleep 5

aws rds wait db-instance-available --db-instance-identifier $DB_IDENTIFIER

DB_DNS_ADDRESS=$(aws rds describe-db-instances --db-instance-identifier $DB_IDENTIFIER --output text --query "DBInstances[0].Endpoint.[Address]") 

echo "[SQL_SERVER] - DB is accessible via $DB_DNS_ADDRESS"


#create file to start over if scripts fail at a later point
mkdir -p $TEMP_EXE_FOLDER
THIS_FILE_NAME="${BASH_SOURCE[0]}"
echo "#!/bin/bash" > $SCRIPT_BASE_PATH/$1
echo "" >> $SCRIPT_BASE_PATH/$1
echo "DB_DNS_ADDRESS=\$(aws rds describe-db-instances --db-instance-identifier $DB_IDENTIFIER --output text --query "DBInstances[0].Endpoint.[Address]") " >> $SCRIPT_BASE_PATH/$1