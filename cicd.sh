#######################################################################################
# EKS에 GitLab + Jenkins + EFS Provisioner 구성
#######################################################################################
[ 2020-07-28 OJT ]

# git clone https://github.com/meditch05/EKS.git

################################################
# [ EFS 볼륨 생성 ]
################################################
1. EFS -> Create FileSystem
   - Name : skcc05599
   - VPC  : eksctl-skcc05599-cluster/VPC   

2. EFS -> Create FileSystem -> Customize -> Next

3. Mount Targtes -> Security groups ( default로 하면 EFS Provisionner에서 EFS 볼륨 사용못하니, EKS Cluster의 Security Group을 지정해야함. )
   - ap-northeast-2a : eks-cluster-sg-skcc-05599-647076920
   - ap-northeast-2c : eks-cluster-sg-skcc-05599-647076920

4. Next -> Next
   
[ EFS Provisioner 생성 ]
# cd ~/EKS/2.task/2.CHARTS/02.efs-provisioner-0.13.0
# diff values.yaml.ori values.yaml.edit
9c9
<   deployEnv: dev
---
>   deployEnv: prd
43,46c43,46
<   efsFileSystemId: fs-12345678
<   awsRegion: us-east-2
<   path: /example-pv
<   provisionerName: example.com/aws-efs
---
>   efsFileSystemId: fs-fdc7ff9c
>   awsRegion: ap-northeast-2
>   path: /eks-pv
>   provisionerName: tbiz-actl.net/aws-efs
54c54
<     reclaimPolicy: Delete
---
>     reclaimPolicy: Retain


# helm install efs-provisioner --namespace infra -f values.yaml.edit stable/efs-provisioner --version v0.13.0
NAME: efs-provisioner
LAST DEPLOYED: Tue Jul 28 13:21:32 2020
NAMESPACE: infra
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
You can provision an EFS-backed persistent volume with a persistent volume claim like below:

kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: my-efs-vol-1
  annotations:
    volume.beta.kubernetes.io/storage-class: aws-efs
spec:
  storageClassName: aws-efs
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi

# kc get sc -n infra
NAME            PROVISIONER             AGE
aws-efs         tbiz-actl.net/aws-efs   5m15s
gp2 (default)   kubernetes.io/aws-ebs   2d5h


################################################
# [ GITLAB 구성 ] => Helm gitlab/gitlab은 너무 무겁고, Sub-Pack 들이 많이 뜨니, Docker 버전을 Deployment로 띄우자
################################################
# cd ~/EKS/task/2.CHARTS/03.gitlab-ce.12.10.11
# kubectl apply -f 1.gitlab-configmap.yaml
# kubectl apply -f 2.gitlab-pvc-svc-ingress.yaml
# kubectl apply -f 3.deploy.gitlab-ce.yaml


################################################
# [ Jenkins 구성 ] => helm v2.3.0
################################################
## helm search repo stable/jenkins --version v2.3.0
## helm fetch stable/jenkins --version v2.3.0
## tar -xvf jenkins-2.3.0.tgz

# cd ~/EKS/2.task/2.CHART/04.jenkins-2.3.0
# diff values.yaml.ori values.yaml.edit
104c104
<   # adminPassword: <defaults to random>
---
>   adminPassword: "alskfl12~!"
122c122
<       memory: "256Mi"
---
>       memory: "1024Mi"
376c376
<     enabled: false
---
>     enabled: true
390,391c390,391
<     annotations: {}
<     # kubernetes.io/ingress.class: nginx
---
>     annotations:
>       kubernetes.io/ingress.class: nginx
394c394
<     # path: "/jenkins"
---
>       path: "/"
396c396
<     hostName:
---
>     hostName: jenkins.tbiz-atcl.net
602c602
<   storageClass:
---
>   storageClass: aws-efs

# helm install jenkins -n infra -f values.yaml.edit stable/jenkins --version 2.3.0
NAME: jenkins
LAST DEPLOYED: Tue Jul 28 14:35:38 2020
NAMESPACE: infra
STATUS: deployed
REVISION: 1
NOTES:
1. Get your 'admin' user password by running:
  printf $(kubectl get secret --namespace infra jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

2. Visit http://jenkins.tbiz-atcl.net

3. Login with the password from step 1 and the username: admin

4. Use Jenkins Configuration as Code by specifying configScripts in your values.yaml file, see documentation: http://jenkins.tbiz-atcl.net/configuration-as-code and examples: https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine
For more information about Jenkins Configuration as Code, visit:
https://jenkins.io/projects/jcasc/


################################################
# [ EKS에 sa/jenkins 에 cluster-admin 권한 부여 ]
################################################
# cd ~EKS/task/01.charts/05.cicd.sample
# kubectl apply -f 1.ClusteRoleBinding.yaml

################################################
# [ Github 프로젝트 만들기 ]
################################################
1. 각자의 Github에 Login / Repository 생성 ( restapi_rds_select )

# cd ~
# mkdir git
# My_Repo="EX> https://github.com/skcc05599/restapi.git"
# git clone ${My_Repo}
# git clone https://github.com/meditch05/restapi_rds_select.git
# cd ${My_Repo}
# cp -R ../restapi_rds_select/*          .
# cp -R ../restapi_rds_select/.gitignore .
# git add *
# git add .gitignore
# git commit -m "clone"
# git push

################################################
# [ Jenkins Pipeline 구성 ]
################################################
1. http://jenkins.tbiz-atcl.net
# cat ~/EKS/2.task/2.CHART/05.jenkins.setting/2.Jenkinsfile


################################################
# [ Test용 RestAPI 호출 방법 ]
################################################
1. /etc/hosts 에 Domain 추가
	3.34.173.12 gitlab.tbiz-atcl.net
	3.34.173.12 jenkins.tbiz-atcl.net
	3.34.173.12 tbiz-atcl.net
	
2. Rest API 호출
	# while true
	# do
	#    curl http://tbiz-atcl.net/api/get/salary/10001 | jq .
	#    sleep 1
	# done
	
	

