# Intrexx Cloud Installation Guide for Amazon Web Services and Microsoft Azure (Virtual Machines)

## Topics

1. [Infrastructure provisioning](#1)
2. [Intrexx cluster installation](#2)
3. [Intrexx cluster operation](#3)

## Infrastructure provisioning

### Introduction

United Planet provides CLI scripts to setup an Intrexx cluster on Amazon AWS or Microsoft Azure. The scripts can be executed on a local Linux machine (or Windows 10 with Linux subsystem service enabled) and provisions the required cloud infrastructure. When the infrastructure is available, Intrexx can be installed with the provided Ansible playbooks. These will be executed on a dedicated Linux provisioning VM created by the script.

### Requirements

- Linux machine with Azure CLI or AWS CLI installed.
- Windows 10 machine with Linux subsystem enabled and Azure/AWS CLI installed on the Linux subsystem.

#### Azure CLI

Install Azure CLI for Linux as desribed here: (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

Then login to your Azure account with `az login`.

#### Amazon Web Services CLI

Install AWS CLI for Linux as desribed here: https://docs.aws.amazon.com/cli/latest/userguide/install-linux.html

Then configure your AWS account:

```bash
$ aws configure
AWS Access Key ID [None]: ...
AWS Secret Access Key [None]: ...
Default region name [None]: ...
Default output format [None]: json
```

### Cluster architecture

The cluster architecture is independent of the chosen cloud provider. An Intrexx cluster consists of several static VM instances for specific services and an autoscale group behind a load balancer, serving Intrexx to the public internet. You can edit the installer scripts to extend the infrastructure for your needs.

#### Default cloud infrastructure components

1. IxProvisioning
      The provisioning instance is used for running the Ansible playbooks to install the Intrexx cluster on the infrastructure. It can be stopped after installation but should not be terminated as it will be used for managing tasks and installing updates on the cluster.
2. IxServices
      The service instance runs the SOLR search server, the filesystem server (NFS for Linux, SMB for Windows, if not using AWS EFS) for the portal server instances to access the shared portal folder and provides the portal manager SOAP interface, which can be accessed from outside the internal virtual private cloud. This instance must be reachable by all portal server instances.
3. IxAppServer
      The app server instance is the template for the portal server VM image used in the autoscale group. At the end of the installation, it will be stopped and can be terminated and removed when the VM image and scale set has been created.
4. Database server
      The installer creates a Postgresql (AWS)- or MS SQL Server (Azure)-database as a service instance for the portal database. During Intrexx setup, the portal setup routine will create and populate the Intrexx database.
5. Automatic horizontal scaling
      The autoscale portal server instances will be created by the cloud provider automatically based on the rules in the autoscale set. They serve the Intrexx portal client requests.
6. Load balancer
      A load balancer is required as single entry point for external clients and to distribute client requests between the portal server instances in the autoscale group. The installer will create a Azure or AWS load balancer service.

#### Supported databases

##### AWS RDS

* Postgresql database

An AWS RDS database service will be provisioned automatically by the installer.

##### Azure SQL Server

* Microsoft SQLServer 

An Azure SQLServer database service will be provisioned automatically by the installer.

#### Shared file system

##### AWS EFS

An AWS EFS service will be provisioned automatically by the installer.

##### Azure NFS

For Azure setups a local NFS (Linux) or SMB server will be installed on the IxServices instance. You are responsible managing backups and replications of the file system.

#### Load balancer

* Application load balancer

The load balancer distributes load on the instances in an autoscale group, which is responsible for providing enough instances and start/stopping instances when neccessary. Those instances are based on the IxAppServer VM image.

### Infrastructure configuration

Before starting the installation, you have to define your preferred cloud infrastructure settings. You can achieve this by editing the parameters in file `variables.sh`. But be careful when overriding network/subnetwork IP range settings. You have to check that the private IP addresses of the app server intances are in the same range as defined in *VIRTUAL_SUBNETWORK_EXTERNAL_ONE_PREFIXES*. Otherwise, you have to adapt the IP addresses in the Ansible host files before starting the Ansible playbooks.

Generally, the parameters in `variables.sh` are divided in basic and advanced sections. Usually, it should only be necessary to edit the settings in the basic section:

1. CLOUD_PROVIDER
  The cloud provider (*aws* or *azure* for now).
2. OPERATING_SYSTEM
  The instance OS (*linux* or *win*).
3. PORTAL_NAME
  Name of the portal to be created.
4. DATA_DIR
  Folder of the Intrexx setup package.
5. INTREXX_ZIP
* Name of the Intrexx setup zip.
* Intrexx download: `wget https://download.unitedplanet.com/intrexx/90000/intrexx-18.09.1-linux-x86_64.tar.gz`
* Copy the file to awsDeploy/data.

Additional settings:

1. [AWS|AZ]_INSTANCE_TYPE_*
  Flavor of the instances.
2. [AWS|AZ]_OS_TYPE_*
  Operating system for the instances.
  Note: For Windows setups the chosen OS language should be English. Otherwise, the Ansible scripts must be adapted (check the Windows group name when creating the Windows services).

3. [AWS|AZ]_ADMIN_PW_WIN
  The Windows administrator user password.

### Infrastructure scripts

The tasks of the scripts in the script folder are:

- `variables.sh`

  First of all you want to edit the general settings in this file to match your infrastructure requirements. Most options can be left as is.

- `createInfrastructure.sh`

  This script creates the general cloud infrastructure (network, vm instances...). When finished, you should be able to connect to the provisioning VM  (check console output at the end of the script execution). On this instance are all files required to install Intrexx. So when the instance is available, you will connect to it via SSH and start the Ansible playbooks to install the Intrexx services.

- `createScaleSet.sh`

  After Intrexx has been installed successfully and the IxAppServer VM was generalized (in case of Azure this needs to be done manually), this script will create the app server VM base image snapshot for the portal server scaling instances, an autoscaling group and a load balancer.

- `deleteAll.sh`

  This script deletes all created cloud resources. You can use it to clean up and start a new installation. Unfortunately, it is not always possible for the script to clean up the resource group completely in case of AWS. So check with the AWS console whether all resources have been deleted properly.

- `deleteAppServerVM.sh`

  After creating the base image from the IxAppServer VM, this instance and its dependencies become obsolete and can be deleted with this script.

### Provision infrastructure with `createInfrastructure.sh`

After having defined all settings in the variables.sh and when you are logged in to your cloud provider, you can start creating the infrastructure by executing `bash createInfrastructure.sh` on the command line.

#### Execution steps

The script executes the following steps, which differ only in some aspects between Azure and AWS:

1. Creates RSA keys for SSH connections between your local computer and the created instances.
2. Creates the VPC (Virtual Private Cloud). This includes several subnets the runtime services.
3. Creates SGs (Security Groups) to defince firewall rules between the subnets and the internet. During installation all instances get a public IP to allow direct connections for configuration tasks. Afterwards all these public access will be removed and only the load balancer, the IxServices (for portal manager) and the provisiong VM can be reached from outside the VPC.
4. Creates the database as well as VMs for IxServices and IxAppServer.
5. If AWS: Creates the AWS Elastic File System mountpoints.
6. Copies the Ansible playbook and installation files to the provisioning VM.
7. Restarts all created instances.
8. Prepares installation of Intrexx via the provisioning instance.
    
### Installing Intrexx cluster

When the infrastructure scripts finished successfully, it prints the ssh command to connect to the provisioning VM on the console. Use that to connect to the VM and start the Intrexx installation. Intrexx and its services (shared file system and SOLR on the IxServices instance as well as the portal server on the IxAppServer instance) need to be installed by starting Ansible playbooks on the provisioning VM.

Follow these steps to install Intrexx:

1. First of all, edit the configuration files hosts_azure/aws.yml and vars.yml (see below for a description of the settings).
2. Install the file server instance (Azure Linux only!): `ansible-playbook -v -i hosts_azure/aws fileserver.yml`
3. Install the SOLR (Solr, SMB fileserver for Windows) node -> `ansible-playbook -v -i hosts_azure/aws appserver_services.yml`
4. Install the portal server instance -> `ansible-playbook -v -i hosts_azure/aws appserver_portal.yml`

After all steps have been executed successfully, you can exit the provisioning VM and go back to your local script folder.

### Creating the autoscale set

To create the auto scale set and load balancer, you can execute `bash createScaleSet.sh` on your local command line.

*ATTENTION:* When using Windows Server as OS for your cluster instances on Azure, you have to generalize the IxAppServer VM before calling this script. You can do that by connecting to the IxAppServer instance with RDP (get the public IP from the Azure portal) and follow the guide here:(https://docs.microsoft.com/de-de/azure/virtual-machines/windows/capture-image-resource). Before starting the generalization, check that the local Windows firewall is disabled for all profiles. Otherwise the load balancer cannot reach the portal server instances and you have to create a new IxAppServer instance and image.

#### Execution steps

The script executes the following steps, which differ only in some aspects between Azure and AWS:

1. Creates a snapshot and image of the IxAppServer VM as master for the scale set instances.
2. Creates the autoscale set/group. This will create and remove portal server instances automatically based on rules defined in the scaling configuration. These rules must be defined manually. At the beginning the script creates a rule to start one instance.
3. Creates the load balancer and connects it with the scale set.

#### Auto scale set settings
If you want your auto scale set react dynamically on the CPU consumption in your cluster, you have to define a policy. Use the CLI or the web console of your cloud provider to define rules and policies. Here is an example for AWS:

![alt text](images/aws/01.01.png)

## Description of Ansible playbooks and resources

### Ansible playbooks

* hosts => Defines the IP address of all hosts in the cluster.
* vars.yml => Hier werden die Variablen für die andern Playbooks definiert. z.B.: Postgres Zugangsdaten, NginX Settings
* files => Contains files required for Intrexx installation.
* appserver_services.yml => Playbook creates IxServices instance (NFS, SMB, SOLR).
* appserver_portal.yml => Playbook creates the IxAppServer instance (portal server).
* appserver_restart.yml => Restarts all app server instances.
* dbserver.yml => Playbook creates a Postgresql database instance (only required for non database as a service setups)
* loadbalancer.yml => Playbook creates a Nginx reverse proxy (only required for non load balancer as a service setups).

### hosts

Defines on which instances which services will be installed:

```bash
[fileserver]
10.0.0.5 hostname=IxServices ipaddr=10.0.0.5

[loadbalancer]
10.0.0.5 hostname=IxServices ipaddr=10.0.0.5

[appserver_services]
10.0.0.5 hostname=IxServices ipaddr=10.0.0.5

[appserver_portal]
10.0.0.6 hostname=IxAppServer ipaddr=10.0.0.6
```

### vars.yml

Linux:
```yaml
---
#
# intrexx cloud
#

#ix_cloud_provider: either vagrant|azure|aws
ix_cloud_provider: aws

#ix_filesystem_type: type of shared filesystem, either nfs, efs (AWS EFS) or glusterfs
ix_filesystem_type: efs

#ix_shared_folder: path to the shared folder
ix_shared_folder: /share

# URI of nfs share
#ix_nfs_share: 192.168.55.11:{{ ix_shared_folder }}
ix_nfs_share: 10.0.0.5:/share

# URI of GlusterFs share
#ix_gluterfs_share: 192.168.55.11:/gv0
ix_glusterfs_share: 10.0.0.5:/gv0

# User used to connect to remote machines
#ix_remote_user: root
ix_remote_user: ubuntu

# Home folder used on remote machines
#ix_remote_home: /root
ix_remote_home: /home/ubuntu

#
# Portal configuration
#
ix_home: /opt/intrexx
ix_portal_name: test
ix_portal_path: /share/test
ix_portal_logpath: /var/log/intrexx
ix_portal_template_path: /opt/intrexx/orgtempl/blank

#
# Database configuration
#

# AWS
#ix_db_type: postgresql
#ix_db_create: true
#ix_db_hostname: 10.0.0.5
#ix_db_port: 5432
#ix_db_database_name: ixtest
#ix_db_admin_login: intrexx
#ix_db_admin_password: 1MyIxCloud!
#ix_db_user_login: intrexx
#ix_db_user_password: 1MyIxCloud!

# Azure
#ix_db_type: mssql
#ix_db_create: true
#ix_db_hostname: ixcloudvmtestsql123.database.windows.net
#ix_db_port: 1433
#ix_db_database_name: ixtest
#ix_db_admin_login: intrexx
#ix_db_admin_password: 1MyIxCloud!
#ix_db_user_login: intrexx
#ix_db_user_password: 1MyIxCloud!

# Vagrant
#ix_db_type: postgresql
#ix_db_create: true
#ix_db_hostname: 192.168.55.11
#ix_db_port: 5432
#ix_db_database_name: ixtest
#ix_db_admin_login: intrexx
#ix_db_admin_password: 1MyIxCloud!
#ix_db_user_login: intrexx
#ix_db_user_password: 1MyIxCloud!

#
# Tomcat configuration
#
ix_tomcat_context: test
ix_tomcat_http_port: 1337
ix_tomcat_https_port: 8443

#
# Solr configuration
#
#ix_solr_url: http://192.168.55.12:8983/solr
ix_solr_url: http://10.0.0.5:8983/solr
ix_solr_cfg_base_dir: /solr

#
# Cluster configuration
#

# IP finder mode: static|multicast|sharedfs
ix_cluster_ipfinder_mode: static

# List of IP addresses of the cluster instances
#ix_cluster_static_addresses: 192.168.55.12,192.168.55.13,192.168.55.14
ix_cluster_static_addresses: 10.0.0.5,10.0.0.6,10.0.0.7,10.0.0.8,10.0.0.9,10.0.0.10
#ix_cluster_ipfinder_sharedfs: "/share/cluster/addresses"

#()
# postgresql
#
postgresql_global_config_options:
  - option: listen_addresses
    value: '*'

postgresql_locales: 
  - 'en_US.UTF-8'

postgresql_databases:
  - name: intrexx

postgresql_hba_entries:
  - { type: local, database: all, user: postgres, auth_method: peer }
  - { type: local, database: all, user: all, auth_method: peer }
  - { type: host, database: all, user: all, address: '127.0.0.1/32', auth_method: md5 }
  - { type: host, database: all, user: all, address: '192.168.55.0/24', auth_method: md5 }
  - { type: host, database: all, user: all, address: '::1/128', auth_method: md5 }

postgresql_users:
  - name: intrexx
    password: 1MyIxCloud!
    role_attr_flags: CREATEDB

#
# nfs exports
#
nfs_exports:  { "/share *(rw,sync,no_root_squash,subtree_check)" }

#
# nginx
#
nginx_remove_default_vhost: true

nginx_upstreams:
  - name: ixcloud
    #strategy: "ip_hash" # "least_conn", etc.
    servers: {
      "192.168.55.12:1337",
      "192.168.55.13:1337",
      "192.168.55.14:1337",
    }

nginx_vhosts:
# Example vhost below, showing all available options:
  - listen: "80"
    server_name: "dbserver"
    extra_parameters: |
     location / {
         proxy_pass http://ixcloud;
     }


#
# GlusterFs
#
glusterfs_default_release: ""
glusterfs_ppa_use: yes
glusterfs_ppa_version: "3.11"

```

Windows:

```yaml
---

ws_username: ixadmin
aws_services_pw: awsWin2019pw!!
aws_portal_pw: awsWin2019pw!!
aws_services_hostname: IxServices
aws_appserver_hostname: IxAppServer

ix_db_hostname: ixcloudvmtestsqldb.database.windows.net
ix_db_port: 1433
ix_db_type: mssql
ix_db_database_name: ixtest
ix_db_create: true
ix_db_admin_login: intrexx
ix_db_admin_password: 1MyIxCloud!
ix_db_user_login: intrexx
ix_db_user_password: 1MyIxCloud!

ix_home: C:\intrexx
ix_portal_name: test
ix_portal_path: C:\share\test
ix_portal_logpath: C:\intrexx\log\portal
ix_share_unc_path: \\10.0.0.5\share

ix_tomcat_context: test
ix_tomcat_http_port: 1337
ix_tomcat_https_port: 8443

ix_solr_url: http://10.0.0.5:8983/solr
ix_solr_cfg_base_dir: C:\intrexx\solr\server\solr

ix_cluster_ipfinder_mode: sharedfs
ix_cluster_static_addresses: 10.0.0.6,10.0.0.7,10.0.0.8
ix_cluster_ipfinder_sharedfs: \\10.0.0.5\share\cluster\addresses
```
