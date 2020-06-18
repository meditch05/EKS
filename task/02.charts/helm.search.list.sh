#!/bin/bash

helm search repo -l stable/efs-provisioner
helm search repo -l stable/nginx-ingress
helm search repo -l stable/jenkins
helm search repo -l gitlab/gitlab

helm fetch stable/efs-provisioner --version v0.11.0
helm fetch stable/nginx-ingress   --version v1.39.1
helm fetch stable/jenkins         --version v2.0.1
helm fetch gitlab/gitlab          --version v4.0.5
