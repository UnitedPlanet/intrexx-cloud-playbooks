#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
#This line is importat, otherwise pip installs with errors
export LC_ALL=C

IP_ADDRESS=$1
VM_USER=$2
DB_ENDPOINT=$3


touch ~/ip-address.txt
echo "$IP_ADDRESS" > ~/ip-address.txt
echo "$DB_ENDPOINT" > ~/dbEndpoint.txt

echo "[PROVISIONING_VM] - Updating and upgrading apt-get" > aptgetoutput.log
apt-get --yes update >> aptgetoutput.log && apt-get --yes upgrade >> aptgetoutput.log

echo "[PROVISIONING_VM] - Installing needed packages" >> aptgetoutput.log
apt-get --yes install python-pip p7zip-full unzip >> aptgetoutput.log
#pip install --upgrade pip >> aptgetoutput.log
pip install pywinrm >> aptgetoutput.log

echo "[PROVISIONING_VM] - Installing ansible" >> aptgetoutput.log
apt-get --yes install software-properties-common  >> aptgetoutput.log
apt-add-repository ppa:ansible/ansible --yes  >> aptgetoutput.log
apt-get --yes update  >> aptgetoutput.log
apt-get --yes install ansible  >> aptgetoutput.log

echo "[PROVISIONING_VM] - Installing NFS module" >> aptgetoutput.log
chown $VM_USER:$VM_USER aptgetoutput.log
su -c "ansible-galaxy install geerlingguy.nfs >> aptgetoutput.log" $VM_USER

su -c "mkdir /home/$VM_USER/cloud-playbooks" $VM_USER

# No annoying ssh key accept messages
sed -i -e 's/#host_key_checking/host_key_checking/g' /etc/ansible/ansible.cfg
