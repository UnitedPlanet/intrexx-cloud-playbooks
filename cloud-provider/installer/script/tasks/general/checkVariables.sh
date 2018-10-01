#!/bin/bash

#Importing configuration variables
source variables.sh

# Check the configured cloud provider
if ! [ $CLOUD_PROVIDER == "aws" ] && ! [ $CLOUD_PROVIDER == "azure" ]; then
    echo "[VALIDATOR] - The cloud provider can only be aws or azure. $CLOUD_PROVIDER is not supported."
    exit 1
fi

# Check the configured operating system
if ! [ $OPERATING_SYSTEM == "win" ] && ! [ $OPERATING_SYSTEM == "linux" ]; then
    echo "[VALIDATOR] - The operating system can only be win or linux. $OPERATING_SYSTEM is not supported."
    exit 1
fi

# Check whether the intrexx trunk file exists 
if [ ! -f $DATA_DIR/$INTREXX_ZIP ]; then
    echo "[VALIDATOR] - Either the 'data dir' or the name of the intrexx zip is not valid. Can't find file $DATA_DIR/$INTREXX_ZIP ."
    exit 1
fi