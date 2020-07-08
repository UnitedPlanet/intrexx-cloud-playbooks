#!/bin/bash

/opt/intrexx/bin/linux/buildportal.sh -t --configFile=/tmp/portal_config.xml

cp /tmp/portal.sh /opt/intrexx/bin/linux

#touch /opt/intrexx/org/cloud/external/htmlroot/websurge-allow.txt

if [ -d "/tmp/server_cfg" ]; then
    cp -R /opt/intrexx/cfg/* /tmp/server_cfg
fi

if [ -d "/tmp/server_bin" ]; then
    cp -R /opt/intrexx/bin/* /tmp/server_bin
fi

cd /opt/intrexx/bin/linux