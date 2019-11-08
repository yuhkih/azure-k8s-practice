#!/bin/bash
export SP_NAME=sample-acr-service-principal
export ACR_RES_GROUP=yuhkiACRRegistry
export AKS_RESOURCE_GROUP=AKSCluster

# -- シェル名の取得
shellname=${0##*/}

echo "[" $shellname "] Deleting Azure Container Resource Group"
result=`az group delete --name $ACR_RES_GROUP --yes`
ret=$?
echo  "[" $shellname "] Deleting Azure Container Resource Group result =" $result "," "return code=" $ret

echo "[" $shellname "] Deleting Azure K8S Resource Group"
result=`az group delete --name $AKS_RESOURCE_GROUP --yes`
ret=$?
echo  "[" $shellname "] Deleting Azure K8S Resource Group result =" $result "," "return code=" $ret

echo "[" $shellname "] Deleting Azure Service Principal"
result=`az ad sp delete --id=$(az ad sp show --id http://$SP_NAME --query appId --output tsv)`
ret=$?
echo  "[" $shellname "] Deleting Azure Service Principal result =" $result "," "return code=" $ret