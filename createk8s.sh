
#!/bin/bash

# login to Azure
az login

# -- 環境変数
# ACR = Azure Container Registry の略
# ここの名前は自分用に変更して下さい (ACR_RES_GROUP / AKS_CLUSTER_NAME / SP_NAME)
export ACR_RES_GROUP=yuhkiACRRegistry
export ACR_NAME=$ACR_RES_GROUP

export AKS_CLUSTER_NAME=AKSCluster
export AKS_RES_GROUP=$AKS_CLUSTER_NAME

export SP_NAME=sample-acr-service-principal


echo  "[" $shellname "] The folloing values will be used for k8s creation"
echo  "[" $shellname "] ACR_RES_GROUP = " $ACR_RES_GROUP
echo  "[" $shellname "] AKS_CLUSTER_NAME = " $AKS_CLUSTER_NAME
echo  "[" $shellname "] ACR_NAME =" $ACR_NAME
echo  "[" $shellname "] AKS_RES_GROUP = " $AKS_RES_GROUP

# -- サンプルのダウンロード
if [ ! -d Understanding-K8s ]
then
    git clone https://github.com/ToruMakabe/Understanding-K8s
fi

# -- シェル名の取得
shellname=${0##*/}

# -- レジストリにコンテナを登録
# -- リソース・グループの作成
echo  "[" $shellname "] create resource group for registry"
result=`az group create --resource-group $ACR_RES_GROUP --location japaneast`
ret=$?
echo  "[" $shellname "] create resource group for registry result =" $result "," "return code=" $ret
echo  "[" $shellname "] Sleep 10 sec to make sure az command completion"; sleep 10

# -- レジストリの作成
echo "[" $shellname "] create registry"
result=`az acr create --resource-group $ACR_RES_GROUP --name $ACR_NAME --sku Standard --location japaneast`
ret=$?
echo  "[" $shellname "] create registry result =" $result "," "return code=" $ret
echo  "[" $shellname "] Sleep 10 sec to make sure az command completion"; sleep 10

# -- レジストリへのイメージの登録 1
echo "[" $shellname "] build registry for v1.0"
result=`az acr build --registry $ACR_NAME --image photo-view:v1.0 Understanding-K8s/chap02/v1.0/`
ret=$?
echo "[" $shellname "] build registry result =" $result "," "return code=" $ret
echo "[" $shellname "] Sleep 10 sec to make sure az command completion"; sleep 10

# -- レジストリへのイメージの登録 2
echo "[" $shellname "] build registry for v2.0"
result=`az acr build --registry $ACR_NAME --image photo-view:v2.0 Understanding-K8s/chap02/v2.0/`
ret=$?
echo "[" $shellname "] build registry result =" $result "," "return code=" $ret
echo "[" $shellname "] Sleep 10 sec to make sure az command completion"; sleep 10

# -- リポジトリの確認
echo "[" $shellname "] check if repository are created "
az acr repository show-tags -n $ACR_NAME --repository photo-view

# -- ACR と AKS の連携のためのID / Password の作成
# AKS は、ACR からコンテナを取得する
ACR_ID=$(az acr show --name $ACR_NAME --query id --output tsv)
SP_PASSWD=$(az ad sp create-for-rbac --name $SP_NAME --role Reader --scopes $ACR_ID --query password --output tsv)
APP_ID=$(az ad sp show --id http://$SP_NAME --query appId --output tsv)

# -- 確認
echo "[" $shellname "] APP_ID = " $APP_ID
echo "[" $shellname "] SP_PASSWD = " $SP_PASSWD

#  - リソースグループの作成
echo "[" $shellname "] Creating K8S cluster resource group"
result=`az group create --resource-group $AKS_RES_GROUP --location japaneast`
ret=$?
echo "[" $shellname "] Creating K8S Cluster resource group =" $result "," "return code=" $ret
echo "[" $shellname "] Sleep 10 sec to make sure az command completion"; sleep 10

# -- K8S クラスタの作成
echo "[" $shellname "] Creating K8S cluster. This takes time."
echo "[" $shellname "] Start creating K8S cluster: " `date '+%y/%m/%d %H:%M:%S'`
result=`az aks create --name $AKS_CLUSTER_NAME --resource-group $AKS_RES_GROUP --node-count 3 --kubernetes-version 1.12.8 --node-vm-size Standard_DS1_v2 --generate-ssh-keys --service-principal $APP_ID --client-secret $SP_PASSWD`
ret=$? 
echo "[" $shellname "] Creating K8S Cluster result =" $result "," "return code=" $ret
echo "[" $shellname "] Sleep 10 sec to make sure az command completion"; sleep 10
echo "[" $shellname "] End creaating K8S Cluster: " `date '+%y/%m/%d %H:%M:%S'`
  
# -- クレデンシャルの取得
echo "[" $shellname "] Getting credentials" 
result=`az aks get-credentials --admin --resource-group $AKS_RES_GROUP --name $AKS_CLUSTER_NAME`
ret=$?
echo "[" $shellname "] Getting credentials result =" $result "," "return code=" $ret
echo "[" $shellname "] Sleep 10 sec for az command completion"; sleep 10

# --確認コマンド
echo "[" $shellname "] check if cluster is created successfully"
kubectl cluster-info
# kubectl get node
echo "[" $shellname "] cluster node check"
kubectl get node -o=wide
# kubectl describe node aks-nodepool1-36860460-0
