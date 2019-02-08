# Intrexx 18.09 Cloud Setup

This repository contains setup scripts and resources for manual and automatic Intrexx Cloud deployments.

__Warning__:
The following guides and examples should not be used as is for production deployments. Security and reliability of your cluster is out of scope of this documentation. Use this only for test and demonstration environments.

## Introduction

A clustered Intrexx installation does not differ very much from a standalone Intrexx setup. Actually, you could install Intrexx as usual on one machine (VM, physical machines) and enable cluster mode afterwards by activating cluster configuration and sharing or mounting the portal folder on the other machines. While this is possible but cumbersome, the preferred way of setting up an Intrexx cluster is to prepare the required infrastructure (on premise, datacenter or cloud) and then use the setup scripts provided in this repository to install the Intrexx instances and required dependencies automatically.

As Intrexx uses internally a thin data grid layer to enable communication and data structure sharing between cluster instances, it is very flexible in the way a cluster can be designed, deployed and operated. There are only a few requirements and things you have to consider when migrating from Intrexx standalone to Intrexx distributed. In particular, these points are

- One portal per Intrexx cluster: An Intrexx cluster can only operate one portal. It is not possible to create multiple portals as it is with a Intrexx standalone server.
- Database: You can use a database as a service offer from your cloud provider or setup one of the supported databases on a dedicated machine in your cluster.
- Shared portal folder: A distributed network file system is required in order to share the portal folder between the portal servers. Currently Intrexx works with AWS EFS, NFS, SMB, GlusterFS and Ceph.
- Workflows: You can decide whether timer jobs and workflows will run on a randomly chosen portal server instance in your cluster or on dedicated job scheduler instances. The latter option is recommended if you have many long running jobs or workflows.
- Search engine: Only one Solr instance is required for the whole cluster. It is possible to cluster Solr as well.

Please keep in mind that the database, shared filesystem, worklow and search services are all single point of failures and could potentially bring your whole cluster down if one of the services crashes. So it is important for production environments to replicate those external services as well. This can be achieved by using cloud provider services (e.g. database as a service, distributed filesystems, etc.) or by using common software components and techniques (e.g. Postgresql/MS SQL Server replication, GlusterFs/Ceph as distributed filesystem instead of NFS, Solr cluster...) to replicate the services on your own.

## Intrexx cluster prerequisites

An Intrexx cluster usually consists of several nodes (virtual machines, Kubernetes pods, physical box):

- At least 3 application server instances for the portal server processes (testing with 2 instances is possible, too).
- One fileserver instance for sharing the portal folder to the application server instances.
- One database server instance (or a cloud provider database as a service) for the portal database.
- Optional: One instance for the workflow engine, otherwise timer processes are triggered on one of the app server nodes.
- Optional: One instance for the Solr search engine, otherwise installed on one of the app server nodes.
- A Linux provisioning instance to execute the Ansible deployment scripts or to manage the Kubernetes cluster.

### Security settings

Configure your virtual private cloud security group to allow internal traffic on all ports. In order to communicate with the other cluster nodes, Intrexx needs open ports for the internal network depending of the used operating system:

- 1337/8443 (tcp): Tomcat
- 8983 (tcp): Solr
- 47500-47600 (tcp): Internal cluster communication
- 5432 (tcp): Postgresql
- 1433 (tcp): MS SQLServer
- 111 and 2049 (tcp/udp): Linux NFS server
- 445 (tcp): Windows SMB server
- 49152 - 65535 (tcp): Intrexx might need to contact DC LDAP, LDAP GC, Kerberos

## Folder contents

### cloud-provider

CLI scripts and documentation for provisioning the required infrastructure on Microsoft Azure, Amanzon Web Services and Vagrant.

#### cloud-provider/installer

Contains the default CLI install scripts for Azure/AWS on Linux and Windows. Can be used for both providers and OSes and will support further cloud providers in the future. At the moment, it requires to start the Ansible provisioning scripts manually.

Consider these scripts as a reference for creating an automatically scaling Intrexx cluster setup.

#### cloud-provider/vagrant

Documentation and Vagrant configuration for setting up a 2-3 node Intrexx cluster on a local machine (notebook/workstation). VirtualBox and Vagrant must be available on this machine.

### linux

Ansible playbooks and resources for installing Intrexx on a Linux cluster. Requires already provided infrastructure (see docs in cloud-provider).

### windows

Ansible playbooks and resources for installing Intrexx on a Windows cluster. Requires already provided infrastructure (see docs in cloud-provider).

### kubernetes

Scripts and resources for installing Intrexx on a Kubernetes cluster. Requires already provided Kubernetes infrastructure.

## Deployment scenarios

### Vagrant for local test environments

Build an Intrexx cluster on your local machine. Each node is deployed on a Ubuntu 16.04 server (headless) VirtualBox VM managed by Vagrant. After VM provisioning, Intrexx must be installed with the Ansible playbooks found under `/linux` or `/windows`.

See [cloud-provider/vagrant/README.md](cloud-provider/vagrant/README.md)

### Microsoft Azure

Setup a full stack Intrexx Cloud deployment on Microsoft Azure with Linux or Windows instances.

- Script installer: [cloud-provider/installer/docs/README.md](cloud-provider/installer/docs/README.md)
- Manual setup (outdated and not recommended): [cloud-provider/azure/README.md](cloud-provider/azure/README.md)
- Collect log files with Logstash/Filebeat: [cloud-provider/azure/docs/Logstash.md](cloud-provider/azure/docs/Logstash.md)

After VM provisioning, Intrexx must be installed with the Ansible playbooks found under `/linux` or `/windows`.

### Amazon Web Services

Setup a full stack Intrexx Cloud deployment on Amazon Web Services with Linux or Windows instances.

- Script installer: [cloud-provider/installer/docs/README.md](cloud-provider/installer/docs/README.md)
- Manual setup (outdated and not recommended): [cloud-provider/aws/README.md](cloud-provider/aws/README.md)
- Collect log files with Logstash/Filebeat: [cloud-provider/azure/docs/Logstash.md](cloud-provider/azure/docs/Logstash.md)

After infrastructure provisioning, Intrexx must be installed with the Ansible playbooks in `/linux` or `/windows`.

### Kubernetes

Create a Kubernetes cluster on Azure (AKS) or AWS and deploy Intrexx Docker containers.

[kubernetes/linux/README.md](kubernetes/linux/docs/README.md)