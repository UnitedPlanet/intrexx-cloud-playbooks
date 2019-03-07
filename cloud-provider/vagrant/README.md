# Intrexx provisioning on Vagrant/Virtual Box

Follow the steps below to build an Intrexx cluster on your local machine consisting of 3 app server and 1 database/fileserver server nodes as well as an extra instance for Ansible provisioning. Each node is deployed on a Ubuntu 16.04 server (headless) virtual box machine managed by Vagrant. The Ansible playbooks are located in the linux folder which must be copied to the provisioning node.

The portal server would be installed on the app server nodes into /opt/intrexx while the portal folder is mapped to a shared NFS mount `/share` which is provided by the db server instance. The folders `/internal/tmp` and `/log` are mapped to the local `/tmp` and `/var/log/intrexx` folders.

Furthermore, a nginx load balancer service is running on the db server distributing requests to the 3 app server nodes.

- Install/update latest VirtualBox

- Install latest Vagrant

- Clone Git repo cloud-playbooks -> `git clone https://github.com/UnitedPlanet/intrexx-cloud-playbooks`

- CD into Git project, `clould-provider/vagrant/ixcloud` -> `vagrant up`

- Copy `../../../linux` folder into local folder.

- After box is up -> `vagrant ssh provision`

- From within the VM, copy `/vagrant/linux` folder to home folder.

- CD into linux folder. Edit variables in `vars.yml` to match your environment. Change `ix_remote_user` and `ix_remote_home` to root. Check IP adresses in hosts_vagrant and vars.yml and modify them to match your Vagrant network.

- Install dbserver -> `ansible-playbook -v -i hosts_vagrant dbserver.yml`

- Install fileserver -> `ansible-playbook -v -i hosts_vagrant fileserver.yml`

- Install services (Solr) node -> `ansible-playbook -v -i hosts_vagrant appserver_services.yml`

- Install portal nodes -> `ansible-playbook -v -i hosts_vagrant appserver_portal.yml`

- Install load balancer -> `ansible-playbook -v -i hosts_vagrant loadbalancer.yml`

- Open portal in browser: e.g. `http://192.168.55.11/default.ixsp`

- To restart appserver nodes -> `ansible-playbook -v -i hosts appserver_restart.yml`