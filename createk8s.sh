
#!/bin/bash

# login to Azure
az login

# -- 環境変数
export ACR_RES_GROUP=yuhkiACRRegistry
export AKS_CLUSTER_NAME=AKSCluster
export ACR_NAME=
export AKS_RES_GROUP=$AKS_CLUSTER_NAME

echo "The folloing values will be used for k8s creation"
echo  "ACR_RES_GROUP = " $ACR_RES_GROUP
echo "AKS_CLUSTER_NAME = " $AKS_CLUSTER_NAME
echo  "ACR_NAME =" $ACR_NAME
echo  "AKS_RES_GROUP = " $AKS_RES_GROUP

# -- サンプルのダウンロード
if [ ! -d Understanding-K8s ]
then
    git clone https://github.com/ToruMakabe/Understanding-K8s
    cd Understanding-K8s/chap02/
fi

# -- レジストリにコンテナを登録
az group create --resource-group $ACR_RES_GROUP --location japaneast
az acr create --resource-group $ACR_RES_GROUP --name $ACR_NAME --sku Standard --location japaneast
az acr build --registry $ACR_NAME --image photo-view:v1.0 v1.0/
az acr build --registry $ACR_NAME --image photo-view:v2.0 v2.0/


# -- レジストリの確認
az acr repository show-tags -n $ACR_NAME --repository photo-view

# -- ACR と AKS の連携のためのID / Password の作成
ACR_ID=$(az acr show --name $ACR_NAME --query id --output tsv)
SP_NAME=sample-acr-service-principal
SP_PASSWD=$(az ad sp create-for-rbac --name $SP_NAME --role Reader --scopes $ACR_ID --query password --output tsv)
APP_ID=$(az ad sp show --id http://$SP_NAME --query appId --output tsv)

# -- 確認
echo $APP_ID
echo $SP_PASSWD
AKS_CLUSTER_NAME=AKSCluster
AKS_RES_GROUP=$AKS_CLUSTER_NAME

#  - リソースグループの作成
az group create --resource-group $AKS_RES_GROUP --location japaneastç

# -- クラスタの作成
az aks create --name $AKS_CLUSTER_NAME --resource-group $AKS_RES_GROUP --node-count 3 --kubernetes-version 1.11.10 --node-vm-size Standard_DS1_v2 --generate-ssh-keys --service-principal $APP_ID --client-secret $SP_PASSWD
  
# -クレデンシャルの取得
az aks get-credentials --admin --resource-group $AKS_RES_GROUP --name $AKS_CLUSTER_NAME

# --確認コマンド
kubectl cluster-info
kubectl get node
kubectl get node -o=wide
kubectl describe node aks-nodepool1-36860460-0

