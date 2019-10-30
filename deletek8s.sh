#!/bin/bash
export SP_NAME=sample-acr-service-principal
export ACR_RES_GROUP=yuhkiACRRegistry
export AKS_RESOURCE_GROUP=AKSCluster
az group delete --name $ACR_RES_GROUP
az group delete --name $AKS_RESOURCE_GROUP
az ad sp delete --id=$(az ad sp show --id http://$SP_NAME --query appId --output tsv)
