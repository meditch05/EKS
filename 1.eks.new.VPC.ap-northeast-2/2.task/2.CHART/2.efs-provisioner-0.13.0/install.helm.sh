#!/bin/bash

#aws efs put-file-system-policy --file-system-id fs-0fc2fa6e --policy '{
#    "Version": "2012-10-17",
#    "Id": "1",
#    "Statement": [
#        {
#            "Effect": "Allow",
#            "Action": [
#                "elasticfilesystem:ClientMount"
#            ],
#            "Principal": {
#                "AWS": "*"
#            }
#        }
#    ]
#}'

helm install efs-provisioner -n infra -f values.yaml.edit stable/efs-provisioner --version 0.13.0
