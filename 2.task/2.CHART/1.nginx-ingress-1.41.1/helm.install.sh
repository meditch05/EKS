#!/bin/bash

helm install nginx-ingress-external -n infra -f 1.values.yaml.nginx-ingress-1.41.1.external     stable/nginx-ingress --version 1.41.1
helm install nginx-ingress-external -n infra -f 1.values.yaml.nginx-ingress-1.41.1.external-acm stable/nginx-ingress --version 1.41.1

helm install nginx-ingress-internal -n infra -f 2.values.yaml.nginx-ingress-1.41.1.internal stable/nginx-ingress --version 1.41.1


# Reference TLS
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.34.1/deploy/static/provider/aws/deploy-tls-termination.yaml
