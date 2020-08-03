#!/bin/bash

helm search repo -l stable/efs-provisioner
helm search repo -l stable/nginx-ingress
helm search repo -l stable/jenkins
helm search repo -l gitlab/gitlab

# helm fetch stable/efs-provisioner --version v0.11.0
helm fetch stable/efs-provisioner --version v0.13.0
helm fetch stable/nginx-ingress   --version v1.41.1
helm fetch stable/jenkins         --version v2.3.3
# helm fetch gitlab/gitlab          --version v4.0.5
