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

chmod a+x intrexx/setup.sh
chmod a+x intrexx/java/packaged/linux/amd64/bin/java

echo "start db container"
docker run -d -e POSTGRES_PASSWORD=mysecretpassword --name ixclouddb postgres:11

echo "build base filesystem image"
cd setup
docker build -t ixcloudfs-base --rm=true .
cd ..

#start a filesystem container and run setup and portal build in it, afterwards keep it running
echo "start setup container"

#use this command to install portal into local portal folder
docker run -v "${WORKDIR}/intrexx":/tmp/ix-setup \
    --link ixclouddb:ixclouddbservice -v "${WORKDIR}/share/cfg":/tmp/server_cfg \
    -v "${WORKDIR}/share/bin":/tmp/server_bin  -v "${WORKDIR}/share/portal":/opt/intrexx/org/cloud -v "${WORKDIR}/import":/tmp/import \
    --name="ixcloudfs-setup" \
    ixcloudfs-base /bin/bash -c "/tmp/ix-setup/setup.sh -t --configFile=/root/configuration.properties; /tmp/build_portal.sh;"

#use this command to install portal in container image
#docker run -v "${WORKDIR}/intrexx":/tmp/ix-setup --name="ixcloudfs-setup" ixcloudfs-base \
#   /bin/bash -c "/tmp/ix-setup/setup.sh -t --configFile=/root/configuration.properties; /tmp/build_portal.sh;"

#commit image
docker stop ixcloudfs-setup
docker commit --change='CMD ["/bin/true"]' ixcloudfs-setup ixcloudsetup:latest

#remove container
docker rm ixcloudfs-setup

#remove base image
docker rmi ixcloudfs-base

#dump database
docker exec ixclouddb  /usr/bin/pg_dump -d ixcloud -U postgres > postgres/ixcloudapp.sql

#kill database
docker stop ixclouddb
docker rm ixclouddb

#build database image
cd postgres
docker build -t ixclouddb --rm=true .
cd ..

#build portal server image
cd portalservice
docker build -t ixcloud --rm=true .
cd ..

#build solr server image
cd solr
docker build -t ixcloudsolr --rm=true .
cd ..

#remove setup image
docker rmi ixcloudsetup:latest

#cleanup dangling volumes
# /bin/bash -c "docker system prune -f"

#create server share folder tarball
tar cvfz server_share.tar.gz share/

echo "Finished"
