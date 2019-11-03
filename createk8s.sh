
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


echo "The folloing values will be used for k8s creation"
echo  "ACR_RES_GROUP = " $ACR_RES_GROUP
echo "AKS_CLUSTER_NAME = " $AKS_CLUSTER_NAME
echo  "ACR_NAME =" $ACR_NAME
echo  "AKS_RES_GROUP = " $AKS_RES_GROUP

# -- サンプルのダウンロード
if [ ! -d Understanding-K8s ]
then
    git clone https://github.com/ToruMakabe/Understanding-K8s
fi

# -- レジストリにコンテナを登録
az group create --resource-group $ACR_RES_GROUP --location japaneast
az acr create --resource-group $ACR_RES_GROUP --name $ACR_NAME --sku Standard --location japaneast
az acr build --registry $ACR_NAME --image photo-view:v1.0 Understanding-K8s/chap02/v1.0/
az acr build --registry $ACR_NAME --image photo-view:v2.0 Understanding-K8s/chap02/v2.0/

# -- リポジトリの確認
echo "check if repository are created "
az acr repository show-tags -n $ACR_NAME --repository photo-view

# -- ACR と AKS の連携のためのID / Password の作成
# AKS は、ACR からコンテナを取得する
ACR_ID=$(az acr show --name $ACR_NAME --query id --output tsv)
SP_PASSWD=$(az ad sp create-for-rbac --name $SP_NAME --role Reader --scopes $ACR_ID --query password --output tsv)
APP_ID=$(az ad sp show --id http://$SP_NAME --query appId --output tsv)

# -- 確認
echo "APP_ID = " $APP_ID
echo "SP_PASSWD = " $SP_PASSWD

#  - リソースグループの作成
echo "Creating K8S cluster resource group"
az group create --resource-group $AKS_RES_GROUP --location japaneast

# -- クラスタの作成
echo "Creating K8S cluster"
az aks create --name $AKS_CLUSTER_NAME --resource-group $AKS_RES_GROUP --node-count 3 --kubernetes-version 1.12.8 --node-vm-size Standard_DS1_v2 --generate-ssh-keys --service-principal $APP_ID --client-secret $SP_PASSWD
  
# -クレデンシャルの取得
echo "Getting credentials" 
az aks get-credentials --admin --resource-group $AKS_RES_GROUP --name $AKS_CLUSTER_NAME

# --確認コマンド
echo "check if cluster is created successfully"
kubectl cluster-info
# kubectl get node
echo "cluster node check"
kubectl get node -o=wide
# kubectl describe node aks-nodepool1-36860460-0
