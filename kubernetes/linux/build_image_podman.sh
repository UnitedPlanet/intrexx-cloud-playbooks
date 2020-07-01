#!/bin/bash

source ./environment.sh

echo "Building Intrexx Cloud container images"

if [ -z "${WORKDIR}" ]; then
    WORKDIR = $(pwd)
fi

cd $WORKDIR

if [ ! -f "${WORKDIR}/intrexx/setup.sh" ]; then
    echo "No setup found in folder intrexx. Please copy the intrexx setup folder."
    exit
fi

rm -rf $WORKDIR/share
rm -rf $WORKDIR/server_share.tar.gz

mkdir -p $WORKDIR/share/bin
mkdir -p $WORKDIR/share/cfg
mkdir -p $WORKDIR/share/portal
mkdir -p $WORKDIR/share/solr

chmod a+x intrexx/setup.sh
chmod a+x intrexx/java/packaged/linux/amd64/bin/java

echo "start db container"
podman run -d -e POSTGRES_PASSWORD=mysecretpassword --network ixcloud --name ixclouddb postgres:12

echo "build base filesystem image"
cd setup
podman build -t ixcloudfs-base --rm=true .
cd ..

#start a filesystem container and run setup and portal build in it, afterwards keep it running
echo "start setup container"

#use this command to install portal into local portal folder
podman run --privileged=true --network ixcloud -v "${WORKDIR}/intrexx":/tmp/ix-setup \
        -v "${WORKDIR}/share/cfg":/tmp/server_cfg -v "${WORKDIR}/share/bin":/tmp/server_bin  \
        -v "${WORKDIR}/share/portal":/opt/intrexx/org/cloud  -v "${WORKDIR}/share/solr":/opt/intrexx/solr \
        --name="ixcloudfs-setup" localhost/ixcloudfs-base:latest \
        /bin/bash -c "/tmp/ix-setup/setup.sh -t --configFile=/root/configuration.properties; /tmp/build_portal.sh;"

#podman run --privileged=true -v "${WORKDIR}/intrexx":/tmp/ix-setup \
#    -v "${WORKDIR}/share/cfg":/tmp/server_cfg \
#    -v "${WORKDIR}/share/bin":/tmp/server_bin \
#    -v "${WORKDIR}/share/portal":/opt/intrexx/org/cloud \ 
#    -v "${WORKDIR}/import":/tmp/import \
#    --name="ixcloudfs-setup" \
#    localhost/ixcloudfs-base:latest /bin/bash -c "/tmp/ix-setup/setup.sh -t --configFile=/root/configuration.properties; /tmp/build_portal.sh;"

#use this command to install portal in container image
#docker run -v "${WORKDIR}/intrexx":/tmp/ix-setup --name="ixcloudfs-setup" ixcloudfs-base \
#   /bin/bash -c "/tmp/ix-setup/setup.sh -t --configFile=/root/configuration.properties; /tmp/build_portal.sh;"

#commit image
podman stop ixcloudfs-setup
podman commit --change='CMD ["/bin/true"]' ixcloudfs-setup ixcloudsetup:latest

#remove container
podman rm -v ixcloudfs-setup

#remove base image
podman rmi ixcloudfs-base

#dump database
podman exec ixclouddb  /usr/bin/pg_dump -d ixcloud -U postgres > postgres/ixcloudapp.sql

#kill database
podman stop ixclouddb
podman rm ixclouddb

#build database image
cd postgres
podman build -t ixclouddb --rm=true .
cd ..

#build portal server image
cd portalservice
podman build -t ixcloud --rm=true .
cd ..

#build solr server image
cd solr
podman build -t ixcloudsolr --rm=true .
cd ..

#remove setup image
podman rmi ixcloudsetup:latest

#cleanup dangling volumes
# /bin/bash -c "docker system prune -f"

#create server share folder tarball
tar cvfz server_share.tar.gz share/

echo "Finished"
