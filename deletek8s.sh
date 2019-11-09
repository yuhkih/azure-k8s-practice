#!/bin/bash
export SP_NAME=sample-acr-service-principal
export ACR_RES_GROUP=yuhkiACRRegistry
export AKS_RESOURCE_GROUP=AKSCluster

# -- シェル名の取得 --
shellname=${0##*/}

# -- ログ用のファンクション -- 
function shell_log(){
    shellname=${0##*/}
    echo  "[" $shellname "][" `date '+%Y/%m/%d %H:%M:%S'`" ] " $1 $2 $3 $4 $5
}

command="az group delete --name $ACR_RES_GROUP --yes"
shell_log "Deleting Azure Container Resource Group:" "$command"
result=eval $command
ret=$?
shell_log "Deleting Azure Container Resource Group result =[" $result "]," "return code=" $ret

command="az group delete --name $AKS_RESOURCE_GROUP --yes"
shell_log "Deleting Azure K8S Resource Group:" "$command"
result=eval $command
ret=$?
shell_log "Deleting Azure K8S Resource Group result =[" $result "]," "return code=" $ret

# command="az ad sp delete --id=$(az ad sp show --id http://$SP_NAME --query appId --output tsv)" # これは one line では代入できない。
spid=`az ad sp show --id http://$SP_NAME --query appId --output tsv`
# echo $spid
command="az ad sp delete --id=$spid"
echo $command
shell_log "Deleting Azure Service Principal:" "$command"
result=eval $command
ret=$?
shell_log "Deleting Azure Service Principal result =[" $result "]," "return code=" $ret