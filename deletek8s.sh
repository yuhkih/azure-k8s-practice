#!/bin/bash
export SP_NAME=sample-acr-service-principal
export ACR_RES_GROUP=yuhkiACRRegistry
export AKS_RESOURCE_GROUP=AKSCluster

echo "Deleting Azure Container Resource Group"
az group delete --name $ACR_RES_GROUP --yes
echo "Deleting Azure K8S Resource Group"
az group delete --name $AKS_RESOURCE_GROUP --yes
echo "Deleting Azure Service Principal"
az ad sp delete --id=$(az ad sp show --id http://$SP_NAME --query appId --output tsv)
