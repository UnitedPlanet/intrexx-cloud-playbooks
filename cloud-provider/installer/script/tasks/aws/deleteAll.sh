#!/usr/bin/env bash

source variables.sh

echo "[CLEANER] - Cleaning up aws."

VPC_ID=null
ITERATION_COUNTER=1
MAX_ITERATIONS=10


# Delete autoscaling group, this resource is also tagged but does not show up...
aws autoscaling  delete-auto-scaling-group --auto-scaling-group-name IxScaleSet || true


while true; do
    RESOURCE_LIST=$(aws  resourcegroupstaggingapi get-resources \
            --tag-filters Key=RSG,Values=$RESOURCE_GROUP_NAME \
            --query "ResourceTagMappingList[*].[ResourceARN]" \
            --output text)

    echo "Delete iteration number $ITERATION_COUNTER, $(echo "$RESOURCE_LIST" | wc -l ) resources still up."
    echo "$RESOURCE_LIST"

    if [ -z "$RESOURCE_LIST" ]; then
        break
    fi 

    while read -r arn; do
        line=$(echo "$arn" | sed 's/.*\///' | sed 's/.*://' )
        case $line in
            i-*         ) 
                aws ec2 terminate-instances --instance-ids $line --output $AWS_OUTPUT_FORMAT >/dev/null      || true
                echo "Waiting for instance $line to shut down"
                aws ec2 wait instance-terminated --instance-ids $line --output $AWS_OUTPUT_FORMAT >/dev/null    || true
                aws resourcegroupstaggingapi untag-resources --resource-arn-list $arn --tag-keys RSG        >/dev/null 
                ;;
            "$(echo "$DB_IDENTIFIER" | awk '{print tolower($0)}')")
                aws rds delete-db-instance --db-instance-identifier $line --skip-final-snapshot >/dev/null || true
                echo "Waiting for database $line to shut down"
                aws rds wait db-instance-deleted --db-instance-identifier $line >/dev/null    || true
                ;;
            igw-*       )   
                #TODO this might be buggy when multiple vpcs are created
                if [ ! $VPC_ID = null ]; then
                    aws ec2 detach-internet-gateway --internet-gateway-id $line --vpc-id $VPC_ID >/dev/null  || true
                    aws ec2 delete-internet-gateway --internet-gateway-id $line >/dev/null       || true
                fi
                ;;
            rtb-*       )   
                ROUTE_TABLE_ASSOCIATIONS=$(aws ec2 describe-route-tables --route-table-id $line --output text --query "RouteTables[0].Associations[*].[RouteTableAssociationId]")
                echo "$ROUTE_TABLE_ASSOCIATIONS"
                #All associations have to be removed
                while read -r assoc; do
                    if [ -z "$assoc" ]; then
                        continue
                    fi
                    aws ec2 disassociate-route-table --association-id $assoc     >/dev/null 
                done <<< "$ROUTE_TABLE_ASSOCIATIONS"

                #Finally delete the route table
                aws ec2 delete-route-table --route-table-id $line --output $AWS_OUTPUT_FORMAT >/dev/null || true
                ;;
            sg-*        )  
                aws ec2 delete-security-group --group-id $line --output $AWS_OUTPUT_FORMAT >/dev/null || true
                ;;
            subnet-*    )  
                aws ec2 delete-subnet --subnet-id $line --output $AWS_OUTPUT_FORMAT >/dev/null   || true
                ;;
            vpc-*       )   
                VPC_ID=$line
                aws ec2 delete-vpc --vpc-id $VPC_ID >/dev/null  || true
                ;;
            *_subnet    )   
                aws rds delete-db-subnet-group --db-subnet-group-name $line >/dev/null || true
                ;;
            *           )
                if [[ "$arn" == *":loadbalancer/"* ]]; then
                    aws elb delete-load-balancer --load-balancer-name $line >/dev/null || true
                    continue
                fi   
                echo "FOUND UNKNOWN RESSOURCE $line , pls add implementation to enable the delet operation"
                break 2
                ;;
        esac
    done <<< "$RESOURCE_LIST"
    let ITERATION_COUNTER=ITERATION_COUNTER+1 
    if [ $ITERATION_COUNTER -eq $MAX_ITERATIONS ]; then
        echo "Seems like not everything is tagged right, since there are still unresolved dependencies. $RESOURCE_LIST can't be deleted."
        break
    fi
done

aws ec2 delete-key-pair --key-name $SERVICES_KEY_NAME  --output $AWS_OUTPUT_FORMAT >/dev/null || true

echo "All resources of RSG $RESOURCE_GROUP_NAME have been deleted."

#remove the folder with the temporary variables
rm -rf $TEMP_EXE_FOLDER