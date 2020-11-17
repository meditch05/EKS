#######################################################################################
# 앞에서 엄준식 수석이 진행한 Part에서 EKS 생성 + Nginx Igress 구성까지 진행하고 들어오세요.
#######################################################################################

#######################################################################################
# EKS + CI/CD 실습 Script 가져오기
#######################################################################################
[ 2020-08-03 실습 자료 ]
# cd ~
# git clone https://github.com/meditch05/EKS.git

###############################################################################
[ ECR 생성 ]
###############################################################################
1. ECR 생성
2. ECR 프로젝트 생성
   - restapi
   - bff-atcl
3. 각 프로젝트에 Permission 설정
   - ECR > Repositories > restapi  > Permissions > Edit poicy JSON
   - ECR > Repositories > bff-atcl > Permissions > Edit poicy JSON

{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "AllowPushPull",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ]
    }
  ]
}

################################################
# AWS - EFS 생성
################################################
1. EFS -> Create FileSystem
   - Name : ds05599
   - VPC  : eksctl-ds05599-cluster/VPC   

2. EFS -> Create FileSystem -> Customize -> Next

3. Mount Targtes -> ( PrivateSubnet ) -> Security groups ( default로 하면 EFS Provisionner에서 EFS 볼륨 사용못하니, EKS Cluster의 Security Group을 지정해야함. )
   - ap-northeast-1a : eks-cluster-sg-skcc-05599-647076920
   - ap-northeast-1c : eks-cluster-sg-skcc-05599-647076920
   - ap-northeast-1d : eks-cluster-sg-skcc-05599-647076920

4. Next -> Next
   - FileSystem ID : fs-551cf075
    
################################################
# EKS - EFS Provisioner 생성
################################################
# cd ~/EKS/2.task/2.CHART/2.efs-provisioner-0.13.0
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
>   efsFileSystemId: fs-551cf075
>   awsRegion: ap-northeast-1
>   path: /eks-pv
>   provisionerName: biz-think.net/aws-efs
54c54
<     reclaimPolicy: Delete
---
>     reclaimPolicy: Retain

# kubectl create ns infra
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

# kubectl get sc -n infra
NAME            PROVISIONER             AGE
aws-efs         tbiz-actl.net/aws-efs   5m15s
gp2 (default)   kubernetes.io/aws-ebs   2d5h

################################################
# GitLab 구성
################################################
# cd ~/EKS/2.task/2.CHART/3.gitlab-ce.12.10.11
# kubectl apply -f 1.gitlab-configmap.yaml
# kubectl apply -f 2.gitlab-pvc-svc-ingress.yaml
# kubectl apply -f 3.deploy.gitlab-ce.yaml

################################################
# Jenkins 구성
################################################
# cd ~/EKS/2.task/2.CHART/4.jenkins-2.3.3
# kubectl apply -f 1.pvc.yaml
# diff values.yaml values.yaml.edit
104c104
<   # adminPassword: <defaults to random>
---
>   adminPassword: "alskfl12~!"
122c122
<       memory: "256Mi"
---
>       memory: "1024Mi"
242c242
<   overwritePluginsFromImage: true
---
>   master.overwritePluginsFromImage: true
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
>     hostName: jenkins.biz-think.net
594c594
<   existingClaim:
---
>   existingClaim: "jenkins"

# helm install jenkins -n infra -f values.yaml.edit stable/jenkins --version 2.3.3
NAME: jenkins
LAST DEPLOYED: Tue Jul 28 14:35:38 2020
NAMESPACE: infra
STATUS: deployed
REVISION: 1
NOTES:
1. Get your 'admin' user password by running:
  printf $(kubectl get secret --namespace infra jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

2. Visit http://jenkins.biz-think.net

3. Login with the password from step 1 and the username: admin

4. Use Jenkins Configuration as Code by specifying configScripts in your values.yaml file, see documentation: http://jenkins.biz-think.net/configuration-as-code and examples: https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine
For more information about Jenkins Configuration as Code, visit:
https://jenkins.io/projects/jcasc/


################################################
# EKS - ServiceAccount/jenkins 에kubernetes의 cluster-admin 권한 부여
################################################
# cd ~/EKS/2.task/2.CHART/4.jenkins-2.3.3
# kubectl apply -f 2.set.ClusteRoleBinding.yaml

################################################
# Route53에 Sub domain 등록하기
################################################
12. Route53에 External NLB 연결
    => Route53 > Hosted Zone > biz-think.net > Create Record
       - record name            : gitlab ( jenkins.biz-think.net )
       - Value/Route traffic to : Alias to Network LoadBalancer > ap-northeast-1 > a9300d7e6bf8445a1837a3ce252904a6-bb46000a4b3ff6ec.elb.ap-northeast-1.amazonaws.com
       - record type            : A - Routes traffic to an IPv4 ~~
       - Evaluate target health : Yes

    => Route53 > Hosted Zone > biz-think.net > Create Record
       - record name            : jenkins ( jenkins.biz-think.net )
       - Value/Route traffic to : Alias to Network LoadBalancer > ap-northeast-1 > a9300d7e6bf8445a1837a3ce252904a6-bb46000a4b3ff6ec.elb.ap-northeast-1.amazonaws.com
       - record type            : A - Routes traffic to an IPv4 ~~
       - Evaluate target health : Yes


################################################
# Github - 프로젝트 만들기
################################################
1. 각자의 Github에 Login / Repository 생성 ( restapi_rds_select )
2. 각자의 Github에 Login / Repository 생성 ( bff_atcl )

################################################
# Github - 소스 Mig 하기
################################################
[ 샘플 git 프로젝트 가져오기] 
# cd ~
# mkdir git 
# git clone https://github.com/meditch05/restapi_rds_select.git
# git clone https://github.com/meditch05/bff_atcl.git
# mv restapi_rds_select src1
# mv bff_atcl           src2

[ 각자git 프로젝트 가져오기] 
# cd ~/git
# git clone https://github.com/${github ID}/restapi_rds_select.git
# cd restapi_rds_select
# cp -Rp ../src1/*          .
# cp -Rp ../src1/.gitignore .
# git add *
# git add .gitignore
# git commit -m "clone"
# git push (github ID/PWD 입력)

# cd ~/git
# git clone https://github.com/${github ID}/bff_atcl.git
# cd bff_atcl
# cp -Rp ../src2/*          .
# cp -Rp ../src2/.gitignore .
# git add *
# git add .gitignore
# git commit -m "clone"
# git push (github ID/PWD 입력)

################################################
# PC에 /etc/hosts 에 NLB IP / Jenkins Domain 추가
################################################
# kubectl get svc -n infra    | grep nginx-ingress-controller
nginx-ingrexx-external-nginx-ingress-controller        LoadBalancer   10.100.243.3     aff3ee8bdcea0488ca94a6486666cdb1-f01ec2b6dc646cec.elb.ap-northeast-2.amazonaws.com   80:31665/TCP,443:30200/TCP   8d

# nslookup aff3ee8bdcea0488ca94a6486666cdb1-f01ec2b6dc646cec.elb.ap-northeast-2.amazonaws.com
Server:         10.16.0.2
Address:        10.16.0.2#53

Non-authoritative answer:
Name:   aff3ee8bdcea0488ca94a6486666cdb1-f01ec2b6dc646cec.elb.ap-northeast-2.amazonaws.com
Address: 13.209.220.214
Name:   aff3ee8bdcea0488ca94a6486666cdb1-f01ec2b6dc646cec.elb.ap-northeast-2.amazonaws.com
Address: 3.35.28.184

1. PC에 hosts 파일 관리자 모드로 notepad 열기
   # C:\Windows\System32\drivers\etc

2. 3개 domain 추가 / 저장 ( 실습에서 쓰는건 jenkins만 사용 )
   13.124.35.3 jenkins.biz-think.net
   13.124.35.3 api.biz-think.net
   13.124.35.3 bff.biz-think.net
   13.124.35.3 gitlab.biz-think.net

################################################
# GitLab 사용
################################################
1. chrom 열고  http://gitlab.biz-think.net 접속 ( root / 미나리12~! )
2. GitHub 처럼 동일하게 사용하며됨 ( 단 File 보는거는 domain 이 POD명으로 맵핑되서 안됨. 이슈해결하는중 )

################################################
# Jenkins Pipeline 구성
################################################
1. chrom 열고  http://jenkins.biz-think.net 접속 ( admin / 미나리12~! )

2-1. New Item 클릭 / 입력 / OK
   - Name : restapi_rds_select
   - TYPE : Pipeline
2-2. Pipeline > Definition > pipeline script from SCM  
   - SCM : git
           > Repository URL : https://github.com/${github ID}/restapi_rds_select.git
	   > Credential     : Add > jenkins 누르고 ( github ID / PWD 입력 )

3-1. New Item 클릭 / 입력 / OK
   - Name : bff_atcl
   - TYPE : Pipeline
3-2. Pipeline > Definition > pipeline script from SCM
   - SCM : git
           > Repository URL : https://github.com/${github ID}/bff_atcl.git
           > Credential     : Add > jenkins 누르고 ( github ID / PWD 입력 )

###############################################################################
# 서비스 호출
###############################################################################
1. RestAPI 호출
   http://api.biz-think.net/get/salary/10051

2. Web 화면 호출 ( WEB에서 RestAPI 호출한걸 JSP 통해서 WEB 화면으로 View )
   http://bff.biz-think.net/view/select/10051



###############################################################################
#  Eclipse - Git 연결
###############################################################################
1. Eclipse > Git > clone a git repository > https://github.com/${github ID}/restapi_rds_select.git
2. Eclipse > Git > clone a git repository > https://github.com/${github ID}/bff_atcl.git

###############################################################################
#  Eclipse - 프로젝트 생성
###############################################################################
3. Eclipse > Java > import > Git ( Projects from Git (with smart import ) > Existing local repository > restapi_rds_select
4. Eclipse > Java > import > Git ( Projects from Git (with smart import ) > Existing local repository > bff_atcl

소스 수정하고 Jenkins에서 "Build Now" 수행
