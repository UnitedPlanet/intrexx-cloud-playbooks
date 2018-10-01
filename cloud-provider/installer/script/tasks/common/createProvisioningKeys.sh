#!/usr/bin/env bash

#Importing configuration variables
source variables.sh

mkdir -p $WORK_DIR

echo "[KEYS] - Deleting old SSH keys if present"
rm -f $WORK_DIR/id_rsa*

echo "[KEYS] - Create new key pair under $SSH_KEY"
ssh-keygen \
    -t rsa \
    -b 2048 \
    -f $SSH_KEY \
    -N '' \
    -q

echo "[KEYS] - Creating new key pair to enable communication between provisioning and SERVICES/APPSERVER"
ssh-keygen \
    -t rsa \
    -b 2048 \
    -C "Provisioning key" \
    -f $WORK_DIR/id_rsa \
    -N '' \
    -q
