#!/bin/bash

helm install nginx-ingress-external -n infra -f 1.values.yaml.nginx-ingress-1.41.1.external stable/nginx-ingress --version 1.41.1
helm install nginx-ingress-internal -n infra -f 2.values.yaml.nginx-ingress-1.41.1.internal stable/nginx-ingress --version 1.41.1
