#!/bin/bash

#push images to registry
docker tag ixclouddb IxKubernetesRegistry.azurecr.io/ixdocker/ixclouddb
docker tag ixcloudsolr IxKubernetesRegistry.azurecr.io/ixdocker/ixcloudsolr
docker tag ixcloud IxKubernetesRegistry.azurecr.io/ixdocker/ixcloud
docker push IxKubernetesRegistry.azurecr.io/ixdocker/ixclouddb
docker push IxKubernetesRegistry.azurecr.io/ixdocker/ixcloudsolr
docker push IxKubernetesRegistry.azurecr.io/ixdocker/ixcloud