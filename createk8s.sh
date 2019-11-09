
#!/bin/bash

# login to Azure
az login

# -- 環境変数 --
# ACR = Azure Container Registry の略
# ここの名前は自分用に変更して下さい (ACR_RES_GROUP / AKS_CLUSTER_NAME / SP_NAME)
export ACR_RES_GROUP=yuhkiACRRegistry
export ACR_NAME=$ACR_RES_GROUP

export AKS_CLUSTER_NAME=AKSCluster
export AKS_RES_GROUP=$AKS_CLUSTER_NAME

export SP_NAME=sample-acr-service-principal

# -- シェル名の取得 --
shellname=${0##*/}

# -- ログ用のファンクション -- 
function shell_log(){
    shellname=${0##*/}
    echo  "[" $shellname "][" `date '+%Y/%m/%d %H:%M:%S'`" ] " $1 $2 $3 $4
}

shell_log "The folloing values will be used for k8s creation"
shell_log "ACR_RES_GROUP = " $ACR_RES_GROUP
shell_log "AKS_CLUSTER_NAME = " $AKS_CLUSTER_NAME
shell_log "ACR_NAME =" $ACR_NAME
shell_log "AKS_RES_GROUP = " $AKS_RES_GROUP

# -- サンプルのダウンロード
if [ ! -d Understanding-K8s ]
then
    git clone https://github.com/ToruMakabe/Understanding-K8s
fi

# -- レジストリにコンテナを登録
# -- リソース・グループの作成
command="az group create --resource-group $ACR_RES_GROUP --location japaneast"
shell_log "レジストリのリスースグループを作成します ["  "$command" "]"
result=eval $command
ret=$?
shell_log "create resource group for registry result=[" $result "]," "return code=" $ret
shell_log "Sleep 10 sec to make sure az command completion"; sleep 10

# -- レジストリの作成
command="az acr create --resource-group $ACR_RES_GROUP --name $ACR_NAME --sku Standard --location japaneast"
shell_log "レジストリを作成します ["　"$command" "]"
result=eval $command
ret=$?
shell_log "create registry result =" $result "," "return code=" $ret
shell_log "Sleep 10 sec to make sure az command completion"; sleep 10

# -- レジストリへのイメージの登録 1
command="az acr build --registry $ACR_NAME --image photo-view:v1.0 Understanding-K8s/chap02/v1.0/"
shell_log "v1.0 用のコンテナイメージをビルドしてレジストリに登録します。 [" "$command" "]"
result=eval $command
ret=$?
shell_log "build registry result=[" $result "]," "return code=" $ret
shell_log "Sleep 10 sec to make sure az command completion"; sleep 10

# -- レジストリへのイメージの登録 2
command="az acr build --registry $ACR_NAME --image photo-view:v2.0 Understanding-K8s/chap02/v2.0/"
shell_log "v2.0用のコンテナイメージをビルドしてレジストリに登録します。[" "$command" "]"
result=eval $command
ret=$?
shell_log "build registry result=[" $result "]," "return code=" $ret
shell_log "Sleep 10 sec to make sure az command completion"; sleep 10

# -- リポジトリの確認
command="az acr repository show-tags -n $ACR_NAME --repository photo-view"
shell_log "レポジトリが作成されたか確認します。 [" "$command" "]"
result=eval $command
ret=$?

# -- ACR と AKS の連携のためのID / Password の作成
# AKS は、ACR からコンテナを取得する
ACR_ID=$(az acr show --name $ACR_NAME --query id --output tsv)
SP_PASSWD=$(az ad sp create-for-rbac --name $SP_NAME --role Reader --scopes $ACR_ID --query password --output tsv)
APP_ID=$(az ad sp show --id http://$SP_NAME --query appId --output tsv)

# -- 確認
shell_log "APP_ID = " $APP_ID
shell_log "SP_PASSWD = " $SP_PASSWD

#  - リソースグループの作成
command="az group create --resource-group $AKS_RES_GROUP --location japaneast"
shell_log "K8S クラスタ用のリソースグループを作成します。 [" "$command" "]"
result=eval $command
ret=$?
shell_log "Creating K8S Cluster resource group=[" $result "]," "return code=" $ret
shell_log "Sleep 10 sec to make sure az command completion"; sleep 10

# -- K8S クラスタの作成
command="az aks create --name $AKS_CLUSTER_NAME --resource-group $AKS_RES_GROUP --node-count 3 --kubernetes-version 1.12.8 --node-vm-size Standard_DS1_v2 --generate-ssh-keys --service-principal $APP_ID --client-secret $SP_PASSWD"
shell_log "K8Sのクラスタを作成します。この処理は少し時間がかかります。 [" "$command" "]"
result=eval $command
ret=$?
shell_log "Creating K8S Cluster result=[" $result "]," "return code=" $ret
shell_log "Sleep 30 sec to make sure az command completion"; sleep 30
shell_log "End creaating K8S Cluster: " `date '+%y/%m/%d %H:%M:%S'`
  
# -- クレデンシャルの取得 ./kube にクレデンシャル情報が書き込まれて kubectl が使えるようになる。
command="az aks get-credentials --admin --resource-group $AKS_RES_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing"
shell_log "kubectl 用のクレデンシャルを取得します。["  "$command" "]"
result=eval $command
ret=$?
shell_log "Getting credentials result =" $result "," "return code=" $ret
shell_Log  "Sleep 10 sec for az command completion"; sleep 10

# --確認コマンド
shell_log "check if cluster is created successfully"
kubectl cluster-info
# kubectl get node
shell_log "cluster node check"
kubectl get node -o=wide
# kubectl describe node aks-nodepool1-36860460-0
