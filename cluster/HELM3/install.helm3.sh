#!/bin/bash

curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
sudo chmod 700 get_helm.sh
sudo ./get_helm.sh
helm version

helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm search repo stable
helm repo update

helm search repo stable/nginx-ingress 

mkdir charts
cd charts
helm fetch stable/nginx-ingress 
tar -zxvf nginx-ingress*.tgz
cp nginx-ingress/values.yaml  nginx-ingress/values.yaml.edit

# diff values.yaml values.yaml.edit
# 134c134
# <   kind: Deployment
# ---
# >   kind: DaemonSet
# 247c247
# <     annotations: {}
# ---
# >     annotations: {service.beta.kubernetes.io/aws-load-balancer-type: nlb}

kubectl create ns infra

cd nginx-ingress
helm install nginx-ingress --namespace infra -f values.yaml.edit stable/nginx-ingress
