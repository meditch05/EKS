############################################################################################################################################################
# [ Bastion 서버 생성 ]
############################################################################################################################################################

1. Bastion 서버 생성 / 환경구성

	- AMI					: Amazon EKS-Optimized Amazon Linux AMI ( Docker / kubectl 기본설치되어있음. 다른거 쓰고 깔아도됨 )
	- InstanceSize			: t3a.micro
	- Subnet				: service-nat-public-p-subnet1 ( 기존 VPC 있는 PublicSubnet 아무대나 생성 )
	- Auto-assign Public IP	: Enable
	- Key Pair				: meditch05.pem
	
	#- AMI 			: CentOS 7 (x86_64) - with Updates HVM
	#- InstanceSize	: t3a.micro
	
2. Bastion 서버 접속 SSH 구성
    - puttygen 설치
	- pem -> ppk 로 변경 ( Key Pair 파일을 ppk 로 변경 )
	- MobaXterm에서 SSH -> Private key 에 ppk 파일 지정
	- ec2-user 로 로그인
	
3. Bastion 서버 점검 / TimeZone 변경
	# sudo timedatectl set-timezone Asia/Seoul
	# date


	
			=====================================
			[ Bastion 서버 구성 - Docker Repository 연결 설정 ( 생성한 ECR 정보 ) ]
			=====================================
			# echo {\"insecure-registries\": [\"644960261046.dkr.ecr.ap-northeast-2.amazonaws.com\"]} | jq . > /etc/docker/daemon.json
	
	
	=====================================
	[ Bastion 서버 구성 - AWS CLI - Configure ( Authentication 구성 ) ]
	=====================================	
	# aws configure
	  - Access Key ID					: ( AWS콘솔 -> IAM -> User -> Security credentials )
	  - Secret access key				: ( Access Key 생성하고 나서 뜨는 팝업에서 "show" 에서만 보임. 잊어버리면 다시 만들어야함. "Download .csv file"로 파일저장해놓던지. )
	  - Default region name [None]		: ap-northeast-2
	  - Default output format [None]	: json
	# aws iam list-access-keys | jq .
	# aws ec2 describe-instances | jq .
	# aws ec2 describe-vpcs | jq '.Vpcs[] | .VpcId'
	# aws ec2 describe-vpcs | jq '.Vpcs[] | .VpcId, .CidrBlock'
	
	=====================================
	[ Bastion 서버 구성 - git ]
	=====================================	
	# sudo yum install -y git
	
	=====================================
	[ Bastion 서버 구성 - jq ]
	=====================================	
	# sudo yum install -y jq
	
	=====================================
	[ Bastion 서버 구성 - ssh keygen ( ~/.ssh/id_rsa.pub 생성 ) ]
	=====================================	
	# ssh-keygen
	
	=====================================
	[ Bastion 서버 구성 - eksctl 구성 ]
	=====================================	
	[ eksctl 설치 ]
	# echo "export PATH=${PATH}:/usr/local/bin:." >> ~/.bash_profile
	# . ~/.bash_profile
	
	# curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
	# sudo mv /tmp/eksctl /usr/local/bin
	# eksctl version
	0.19.0
	
	=====================================
	[ Bastion 서버 구성 - kubectl 구성 ]
	=====================================	
	# kubectl_ver=`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`
	# echo $kubectl_ver
	# curl -LO https://storage.googleapis.com/kubernetes-release/release/${kubectl_ver}/bin/linux/amd64/kubectl
	# chmod +x ./kubectl
	# sudo mv  ./kubectl /usr/local/bin/kubectl
	# kubectl version --client
	
	=====================================
	[ Bastion 서버 구성 - docker 구성 ]
	=====================================	
	# sudo yum install -y docker
	# sudo systemctl restart docker
	# sudo systemctl is-enabled docker
	# sudo systemctl enable docker   # VM 재기동시 Docker 엔진 기동되도록
	

	
4. 실습용 Git Repository 정보 등록 / get ( ID/PWD 저장 )

	# git clone https://github.com/meditch05/EKS.git
		
			# git config user.name "meditch05"
			# git config user.email "meditch05@gmail.com"
			# git push https://github.com/meditch05/EKS.git
			# git config credential.helper store --global


5. EKS CLUSTER 생성 ( eksctl 사용 )

	# cd EKS/cluster
	# date; eksctl create cluster -f eks-meditch05.yaml; date

			[ 오류 1 ]
			# test for error - Error: timed out (after 25m0s) waiting for at least 1 nodes to join the cluster and become ready in "ffp-unmanaged-ng-proxy"
		
			- 테스트 1 ( # https://eksctl.io/usage/autoscaling/ )
			추가1
			# availabilityZones: ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]	  

	
	# aws eks describe-cluster --name eks-meditch05 | jq '.cluster |.name, .endpoint, .resourcesVpcConfig'


############################################################################################################################################################
# [ EKS Cluster 운영환경 구성 ]
############################################################################################################################################################
※ EKSCTL 사용시 EKS에 필요한 모드 Resource들을 CloudFormation으로 다 만들어준다
   => 별도의 CloudFormation을 사용할 필요가 없음
   => 보안 강화를 위해서 추가적인 수정/추가가 필요할 수는 있음 ( Bastion 서버라든지... )
   
   - VPC
   - NAT IP
   - ServiceRole
   - InternetGateway
   - SecurityGroup


1. EKS Cluster 생성

   [ Local VM에서 eksctl 수행 ]
   
   # date; eksctl create cluster -f ffp-eks-2.yaml; date
   
		# Bastion 생성 ( eksctl 생성시에 만들어지는 PublicSubnet 중에 아무거나 1개 선택하거나 기존 VPC 있는 PublicSubnet 아무대나 생성 )
		# Bastion 서버 접속
		# aws eks list-clusters
		# aws eks update-kubeconfig --name ffp-cluster-eksctl
			=> ~/.kube/config 생성됨
   
   # kubectl get node
   # kubectl get svc
   # kubectl get ns
   # kubectl get all --all-namespaces
   
   
2. Kuberntes Node 별 Labeling ( eks.yaml 에서 Labeling 자동화 하는 방법이 있을거 같은데.. 확인해라 )
   # kubectl get node
   
   # kubectl label nodes ip-10-5-119-102.ap-northeast-2.compute.internal node-role.kubernetes.io/worker=true
   # kubectl label nodes ip-10-5-191-251.ap-northeast-2.compute.internal node-role.kubernetes.io/worker=true
   
   # kubectl label nodes ip-10-5-101-252.ap-northeast-2.compute.internal node-role.kubernetes.io/proxy=true
   # kubectl label nodes ip-10-5-144-181.ap-northeast-2.compute.internal node-role.kubernetes.io/proxy=true
   
   
   # kubectl label nodes ip-10-5-106-194.ap-northeast-2.compute.internal node-role.kubernetes.io/worker=true
   # kubectl label nodes ip-10-5-146-249.ap-northeast-2.compute.internal node-role.kubernetes.io/worker=true
   # kubectl label nodes ip-10-5-167-97.ap-northeast-2.compute.internal  node-role.kubernetes.io/worker=true
   


3. Helm 환경 구성
	=====================================
	[ helm 설치 / 테스트 ]
	=====================================
	==> https://docs.aws.amazon.com/eks/latest/userguide/helm.html
	==> https://sarc.io/index.php/cloud/1763-install-helm-to-eks
	
	[ Helm ver 2 ]
	# cd ~/EKS/cluster/HELM	
	# curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
	# chmod +x get_helm.sh
	# ./get_helm.sh
	Downloading https://get.helm.sh/helm-v2.16.6-linux-amd64.tar.gz
	Preparing to install helm and tiller into /usr/local/bin
	helm installed into /usr/local/bin/helm
	tiller installed into /usr/local/bin/tiller
	Run 'helm init' to configure helm.
	
			[ Helm ver 3 ]
			# curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
			# chmod 700 get_helm.sh
			# ./get_helm.sh
			Downloading https://get.helm.sh/helm-v3.1.2-linux-amd64.tar.gz
			Preparing to install helm into /usr/local/bin
			helm installed into /usr/local/bin/helm
	
	# cat helm-rbac-config.yaml
	---
	apiVersion: v1
	kind: ServiceAccount
	metadata:
	  name: tiller
	  namespace: kube-system
	---
	apiVersion: rbac.authorization.k8s.io/v1
	kind: ClusterRoleBinding
	metadata:
	  name: tiller
	roleRef:
	  apiGroup: rbac.authorization.k8s.io
	  kind: ClusterRole
	  name: cluster-admin
	subjects:
	- kind: ServiceAccount
	    name: tiller
	    namespace: kube-system
	---
	
	# kubectl apply -f helm-rbac-config.yaml
	serviceaccount/tiller created
	clusterrolebinding.rbac.authorization.k8s.io/tiller created
	
	# helm init --service-account tiller
	
	# kubectl get pod --all-namespaces | grep tiller
	
	# helm version
	Client: &version.Version{SemVer:"v2.16.6", GitCommit:"dd2e5695da88625b190e6b22e9542550ab503a47", GitTreeState:"clean"}
	Server: &version.Version{SemVer:"v2.16.6", GitCommit:"dd2e5695da88625b190e6b22e9542550ab503a47", GitTreeState:"clean"}
	
	=====================================
	[ helm redis-ha 설치 테스트 ]
	=====================================
	# mkdir ~/EKS/cluster/HELM/redis
	# cd    ~/EKS/cluster/HELM/redis
	# helm inspect values stable/redis-ha > values.yaml.redis.ori
	# cp values.yaml.redis.ori values.yaml.redis.edit
	# vi values.yaml.redis.edit
	# kubectl create ns infra
	# helm install --name redis-ha --namespace infra -f values.yaml.redis.edit stable/redis
	
	# kc get pod -n infra -o wide
	NAME                READY   STATUS    RESTARTS   AGE   IP              NODE                                               NOMINATED NODE   READINESS GATES
	redis-ha-master-0   1/1     Running   0          75s   10.16.144.200   ip-10-16-155-104.ap-northeast-2.compute.internal   <none>           <none>
	redis-ha-slave-0    1/1     Running   0          75s   10.16.155.203   ip-10-16-155-104.ap-northeast-2.compute.internal   <none>           <none>
	redis-ha-slave-1    1/1     Running   0          49s   10.16.108.55    ip-10-16-102-199.ap-northeast-2.compute.internal   <none>           <none>	
	
	
	=====================================
	[ helm redis-ha 삭제 ]
	=====================================
	# helm delete redis-ha --purge
	
					[ helm repo 추가 ]
					# helm repo add stable https://kubernetes-charts.storage.googleapis.com
					# helm repo update
					# helm search repo redis-ha
					
					※ https://github.com/aws/eks-charts
					# helm repo add eks https://aws.github.io/eks-charts
   
[ VPC ]
eksctl-ffp-cluster-eksctl-cluster/VPC	vpc-06b58c823534e8a4b	available	192.168.0.0/16	-	dopt-cd9412a6	rtb-0410b83d42873bfbb	acl-00b86c40f279e89f3	default	No	644960261046

[ Subnet ]
eksctl-ffp-cluster-eksctl-cluster/SubnetPrivateAPNORTHEAST2A	subnet-0e3a6adf353d26378	available	vpc-06b58c823534e8a4b | eksctl-ffp-cluster-eksctl-cluster/VPC	192.168.128.0/19	8187	-	ap-northeast-2a	apne2-az1	rtb-02f1d9a252042bc32 | eksctl-ffp-cluster-eksctl-cluster/PrivateRouteTableAPNORTHEAST2A	acl-00b86c40f279e89f3
eksctl-ffp-cluster-eksctl-cluster/SubnetPrivateAPNORTHEAST2B	subnet-0b07356d0ae4ac8ea	available	vpc-06b58c823534e8a4b | eksctl-ffp-cluster-eksctl-cluster/VPC	192.168.96.0/19		8174	-	ap-northeast-2b	apne2-az2	rtb-004c3a479df8b04d1 | eksctl-ffp-cluster-eksctl-cluster/PrivateRouteTableAPNORTHEAST2B	 acl-00b86c40f279e89f3
eksctl-ffp-cluster-eksctl-cluster/SubnetPrivateAPNORTHEAST2C	subnet-0f1e41917ec8ea71d	available	vpc-06b58c823534e8a4b | eksctl-ffp-cluster-eksctl-cluster/VPC	192.168.160.0/19	8186	-	ap-northeast-2c	apne2-az3	rtb-0f2f95fa8f88bfa98 | eksctl-ffp-cluster-eksctl-cluster/PrivateRouteTableAPNORTHEAST2C
eksctl-ffp-cluster-eksctl-cluster/SubnetPublicAPNORTHEAST2A		subnet-0429f99a6e531fc97	available	vpc-06b58c823534e8a4b | eksctl-ffp-cluster-eksctl-cluster/VPC	192.168.32.0/19		8186	-	ap-northeast-2a	apne2-az1	rtb-028b55b507e9fff2f | eksctl-ffp-cluster-eksctl-cluster/PublicRouteTable
eksctl-ffp-cluster-eksctl-cluster/SubnetPublicAPNORTHEAST2B		subnet-020893d59b963eae9	available	vpc-06b58c823534e8a4b | eksctl-ffp-cluster-eksctl-cluster/VPC	192.168.0.0/19		8186	-	ap-northeast-2b	apne2-az2	rtb-028b55b507e9fff2f | eksctl-ffp-cluster-eksctl-cluster/PublicRouteTable
eksctl-ffp-cluster-eksctl-cluster/SubnetPublicAPNORTHEAST2C		subnet-0093baa5f20164895	available	vpc-06b58c823534e8a4b | eksctl-ffp-cluster-eksctl-cluster/VPC	192.168.64.0/19		8187	-	ap-northeast-2c	apne2-az3	rtb-028b55b507e9fff2f | eksctl-ffp-cluster-eksctl-cluster/PublicRouteTable

[ Route Table ]
eksctl-ffp-cluster-eksctl-cluster/PublicRouteTable					rtb-028b55b507e9fff2f	3 subnets					-	No	vpc-06b58c823534e8a4b | eksctl-ffp-cluster-eksctl-cluster/VPC	644960261046
eksctl-ffp-cluster-eksctl-cluster/PrivateRouteTableAPNORTHEAST2A	rtb-02f1d9a252042bc32	subnet-0e3a6adf353d26378	-	No	vpc-06b58c823534e8a4b | eksctl-ffp-cluster-eksctl-cluster/VPC	644960261046
eksctl-ffp-cluster-eksctl-cluster/PrivateRouteTableAPNORTHEAST2B	rtb-004c3a479df8b04d1	subnet-0b07356d0ae4ac8ea	-	No	vpc-06b58c823534e8a4b | eksctl-ffp-cluster-eksctl-cluster/VPC	644960261046
eksctl-ffp-cluster-eksctl-cluster/PrivateRouteTableAPNORTHEAST2C	rtb-0f2f95fa8f88bfa98	subnet-0f1e41917ec8ea71d	-	No	vpc-06b58c823534e8a4b | eksctl-ffp-cluster-eksctl-cluster/VPC	644960261046

[ InternetGateway ]
eksctl-ffp-cluster-eksctl-cluster/InternetGateway	igw-0d0e46289a59337ae	attached	vpc-06b58c823534e8a4b | eksctl-ffp-cluster-eksctl-cluster/VPC	644960261046

[ NATGateway ]
eksctl-ffp-cluster-eksctl-cluster/NATGateway	nat-0b373ef0c0c400fb4	available	-	3.34.33.98	192.168.30.22	eni-0229a4eaf07966931	vpc-06b58c823534e8a4b | eksctl-ffp-cluster-eksctl-cluster/VPC	subnet-020893d59b963eae9 | eksctl-ffp-cluster-eksctl-cluster/SubnetPublicAPNORTHEAST2B

[ Network ACL ]
acl-00b86c40f279e89f3	6 Subnets	Yes	vpc-06b58c823534e8a4b | eksctl-ffp-cluster-eksctl-cluster/VPC	644960261046

[ SecurityGroup ]
eks-cluster-sg-ffp-cluster-eksctl-1046320802						sg-071c7bfdc8afeb6d9	eks-cluster-sg-ffp-cluster-eksctl-1046320802									vpc-06b58c823534e8a4b	EC2-VPC
eksctl-ffp-cluster-eksctl-cluster/ClusterSharedNodeSecurityGroup	sg-0f2766cbb03b3648e	eksctl-ffp-cluster-eksctl-cluster-ClusterSharedNodeSecurityGroup-DNRWX0M3VPV3	vpc-06b58c823534e8a4b	EC2-VPC
eksctl-ffp-cluster-eksctl-cluster/ControlPlaneSecurityGroup			sg-0cefea890e45b41fb	eksctl-ffp-cluster-eksctl-cluster-ControlPlaneSecurityGroup-1CRVCX694GPEY		vpc-06b58c823534e8a4b	EC2-VPC
eksctl-ffp-cluster-eksctl-nodegroup-ffp-unmanaged-ng-proxy/SG		sg-0ce8bdadf658eea65	eksctl-ffp-cluster-eksctl-nodegroup-ffp-unmanaged-ng-proxy-SG-H7ZID695YQCP		vpc-06b58c823534e8a4b	EC2-VPC

[ EC2 - AutoScailing Group ]
eksctl-ffp-cluster-eksctl-nodegroup-ffp-unmanaged-ng-proxy-NodeGroup-1CIY5WEPUTDO9	eksctl-ffp-cluster-eksctl-nodegroup-ffp-unmanaged-ng-proxy	1	1	1	3	ap-northeast-2a, ap-northeast-2b, ap-northeast-2c	300	0

[ Network Interface ]
eni-0c015d32f0bd06aa2	subnet-045b93fd2243d3492	vpc-0f9d35d3c57436f17	ap-northeast-2c	eks-cluster-sg-ffp-cluster-eksctl-1046320802, eksctl-ffp-cluster-eksctl-cluster-ControlPlaneSecurityGroup-QS50AKJCXST7	Amazon EKS ffp-cluster-eksctl	 in-use	-	10.16.51.224	-	644960261046	-
eni-0f17828ee758e5db0	subnet-0b8d1ffd0c04baf94	vpc-0f9d35d3c57436f17	ap-northeast-2b	eks-cluster-sg-ffp-cluster-eksctl-1046320802, eksctl-ffp-cluster-eksctl-cluster-ControlPlaneSecurityGroup-QS50AKJCXST7	Amazon EKS ffp-cluster-eksctl		 in-use	-	10.16.9.139	-	644960261046	-	 
eni-068e042b1ce42ae0d	subnet-045d7e27f52adb502	vpc-0f9d35d3c57436f17	ap-northeast-2b	eksctl-ffp-cluster-eksctl-cluster-ClusterSharedNodeSecurityGroup-893CGLK8CQTZ, eksctl-ffp-cluster-eksctl-nodegroup-ffp-unmanaged-ng-proxy-SG-1534TUWY0F4QQ	aws-K8S-i-0576adfa4a62c5adb	i-0576adfa4a62c5adb	 in-use	-	10.16.121.213	0.16.120.196, 10.16.111.70, 10.16.114.214, 10.16.109.26, 10.16.109.254	-	644960261046	-
eni-074ccc39ef9427549	subnet-045d7e27f52adb502	vpc-0f9d35d3c57436f17	ap-northeast-2b	eksctl-ffp-cluster-eksctl-cluster-ClusterSharedNodeSecurityGroup-893CGLK8CQTZ, eksctl-ffp-cluster-eksctl-nodegroup-ffp-unmanaged-ng-proxy-SG-1534TUWY0F4QQ	i-0576adfa4a62c5adb	 in-use	-	10.16.102.199	10.16.106.148, 10.16.116.20, 10.16.108.55, 10.16.124.120, 10.16.115.249	-	644960261046	-
eni-082309c5e3ed2c8c6	subnet-0db9ea516d8855be7	vpc-0f9d35d3c57436f17	ap-northeast-2a	eksctl-ffp-cluster-eksctl-cluster-ClusterSharedNodeSecurityGroup-893CGLK8CQTZ, eksctl-ffp-cluster-eksctl-nodegroup-ffp-unmanaged-ng-proxy-SG-1534TUWY0F4QQ	i-0db7ba6f31854b2df	 in-use	-	10.16.167.171	10.16.187.114, 10.16.164.8, 10.16.187.27, 10.16.172.77, 10.16.180.207	-	644960261046	-	 
eni-0c3f331f797840ffd	subnet-0f3c6bc32e47ff064	vpc-0f9d35d3c57436f17	ap-northeast-2c	eksctl-ffp-cluster-eksctl-cluster-ClusterSharedNodeSecurityGroup-893CGLK8CQTZ, eksctl-ffp-cluster-eksctl-nodegroup-ffp-unmanaged-ng-proxy-SG-1534TUWY0F4QQ	i-06bb7238df5b6e248	 in-use	-	10.16.155.104	10.16.143.226, 10.16.154.194, 10.16.144.200, 10.16.154.106, 10.16.155.203	-	644960261046	-
eni-0efa3eaf306d6f31a	subnet-0f3c6bc32e47ff064	vpc-0f9d35d3c57436f17	ap-northeast-2c	eksctl-ffp-cluster-eksctl-cluster-ClusterSharedNodeSecurityGroup-893CGLK8CQTZ, eksctl-ffp-cluster-eksctl-nodegroup-ffp-unmanaged-ng-proxy-SG-1534TUWY0F4QQ	aws-K8S-i-06bb7238df5b6e248	i-06bb7238df5b6e248	 in-use	-	10.16.152.240	10.16.143.225, 10.16.145.147, 10.16.133.23, 10.16.144.203, 10.16.147.255	-	644960261046	-
eni-0f36f09dff8937e54	subnet-0db9ea516d8855be7	vpc-0f9d35d3c57436f17	ap-northeast-2a	eksctl-ffp-cluster-eksctl-cluster-ClusterSharedNodeSecurityGroup-893CGLK8CQTZ, eksctl-ffp-cluster-eksctl-nodegroup-ffp-unmanaged-ng-proxy-SG-1534TUWY0F4QQ	aws-K8S-i-0db7ba6f31854b2df	i-0db7ba6f31854b2df	 in-use	-	10.16.170.86	10.16.190.225, 10.16.187.76, 10.16.177.60, 10.16.191.93, 10.16.185.238	-	644960261046	-	


############################################################################################################################################################
# [ ECR 생성 ] Elastic Container Registry
############################################################################################################################################################
3. AWS ECR 생성
	=====================================
	[ ECR 생성 ]
	=====================================
	AWS -> ECR 
	- Repository name	: nginx / busybox / httpd
	- Tag immutability	: Disabled ( 같은 TAG면 OverWirte 하게끔. 이게 편함, 컨테이너 이미지 TAG 매번 바꾸기도 어렵고, 계속 늘거나기만하고, 지우기도 어려움 )
	- Scan on push		: Disables ( 컨테이너 이미지 Push 하고나면 자동으로 이미지 push 결과 보여줌, 필요 없음. 필요하면 수동으로 봐 )
	
	==> ECR URI	: 847322629192.dkr.ecr.ap-northeast-2.amazonaws.com
	
	=====================================
	[ ECR 연결 테스트 ]
	=====================================
	---------------------------------
	[ AWSCLI verion 1.18.41 사용시 ]
	---------------------------------
	# aws ecr get-login
	
	docker login -u AWS -p KKKKK -e none https://644960261046.dkr.ecr.ap-northeast-2.amazonaws.com
	
	# export ECR_URL=`   aws ecr describe-repositories | jq -r .repositories[].repositoryUri | cut -d"/" -f1 | uniq`
	# export ECR_PASSWD=`aws ecr get-login | cut -d" " -f6`
	# sudo docker login -u AWS -p ${ECR_PASSWD} ${ECR_URL}
		=> ~/.docker/config.json 이 자동으로 생성된다

	# aws ecr create-repository --repository-name meditch05
		
	# aws ecr create-repository --repository-name nginx
	# sudo docker pull nginx
	# sudo docker tag docker.io/nginx:latest   ${ECR_URL}/nginx:latest
	# sudo docker push 						   ${ECR_URL}/nginx:latest
	
	# aws ecr create-repository --repository-name busybox
	# sudo docker pull busybox
	# sudo docker tag docker.io/busybox:latest ${ECR_URL}/busybox:latest
	# sudo docker push 						   ${ECR_URL}/busybox:latest
	
	# aws ecr create-repository --repository-name httpd
	# sudo docker pull httpd
	# sudo docker tag docker.io/httpd:latest   ${ECR_URL}/httpd:latest
	# sudo docker push                         ${ECR_URL}/httpd:latest
	
	# cd ~/QA/shl/
	# sh docker.repo.list.sh
	
	
############################################################################################################################################################
# [ EKS / ECR 연동 테스트 ]
############################################################################################################################################################
4. k8s Deployment 생성
	=====================================
	[ Deployment 생성 테스트 ]
	=====================================
	# vi busybox.yaml
	---
	apiVersion: apps/v1
	kind: Deployment
	metadata:
	name: busybox-deployment-ecr1
	labels:
		app: busybox-deployment-ecr1
	spec:
	replicas: 3
	selector:
		matchLabels:
		app: busybox
	template:
		metadata:
		labels:
			app: busybox
		spec:
		imagePullSecrets:
		- name: ecr1
		containers:
		- name: nginx
			image: 644960261046.dkr.ecr.ap-northeast-2.amazonaws.com/busybox:latest  # ECR Repository URL 로 수정
			imagePullPolicy: Always # IfNotPresent
			command:
			- sleep
			- "3600"
			ports:
			- containerPort: 80
	---		
	
	# cd ~/EKS/cluster/TEST
	# kubectl create ns infra
	# kubectl apply -f busybox.yaml	
	# kubectl get pod -n infra
	

				[ kubernetes에 ECR 정보 등록 - secret ]
				# kubectl create secret docker-registry ecr1	\
				--docker-server="644960261046.dkr.ecr.ap-northeast-2.amazonaws.com"			\
				--docker-username="AWS"					\
				--docker-password="KKKKKKKKKKKKKKK"					\
				--docker-email="meditch@naver.com"
				
				# kubectl get secret ecr1 --output=yaml
				# kubectl get secret ecr1 --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
				# echo "${auth}" | base64 --decode
				=> ID / PASS 확인가능
	
				---------------------------------
				[ AWSCLI verion 2 사용시 ]
				---------------------------------
				# aws ecr describe-repositories
				{
					"repositories": []
				}	  
				# aws ecr get-login-password
				KKKKKKKKKKKKKKK
				==
				
				# export ECR_URL="644960261046.dkr.ecr.ap-northeast-2.amazonaws.com"
				# export ECR_PASSWD=`aws ecr get-login-password`	
				# docker login -u AWS -p ${ECR_PASSWD} ${ECR_URL}
				
				[ jq로 json 파싱해서 Uri 별도로 추출하는것 ]
				# aws ecr create-repository --repository-name nginx
				# aws ecr describe-repositories | jq -r '.repositories[] | select(.repositoryName=="nginx") | .repositoryUri'
				644960261046.dkr.ecr.ap-northeast-2.amazonaws.com/nginx
			
				# export ECR_URL=`aws ecr describe-repositories | jq -r '.repositories[] | select(.repositoryName=="nginx") | .repositoryUri'`
				
			
				[ ~/.docker/config.json 생성 여부 확인 - docker login 하면 생성됨]
				==> https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
				
				{
						"auths": {
								"644960261046.dkr.ecr.ap-northeast-2.amazonaws.com": {
										"auth": "KKKKK="
								}
						}
				}
	
5. EKS 활용 테스트
	==> https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
	==> https://stackoverflow.com/questions/24026348/aws-malformed-policy-error
	==> https://medium.com/tensult/alb-ingress-controller-on-aws-eks-45bf8e36020d
	==> https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html#load-balancer-scheme	
	==> https://aws.amazon.com/blogs/opensource/network-load-balancer-nginx-ingress-controller-eks/
		( by Cornell Anthony | on 09 AUG 2019  )
	==> https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-elb-load-balancer.html
		
	확인1. PublicSubnet 에 Tag 추가되어있는지 확인
			- Key:  kubernetes.io/role/elb
			- Value: 1
	확인2. PrivateSubnet 에 Tag 추가되어있는지 확인
			- Key:  kubernetes.io/role/internal-elb
			- Value: 1
	
	============================================	
	[ nginx-ingress-controller 구성 ] helm 버전 - helm version 2
	============================================	
	# cd ~/EKS/cluster/HELM/nginx-ingress-controller
	# helm inspect values stable/nginx-ingress > values.yaml.ingress-nginx.ori
	# cp values.yaml.ingress-nginx.ori values.yaml.ingress-nginx.edit
	# vi values.yaml.ingress-nginx.edit
	# diff values.yaml.ingress-nginx.ori values.yaml.ingress-nginx.edit
	25c25,28
	<   config: {}
	---
	>   config:
	>     proxy-protocol: "True"
	>     real-ip-header: "proxy_protocol"
	>     set-real-ip-from: "0.0.0.0/0"
	134c137
	<   kind: Deployment
	---
	>   kind: DaemonSet
	196c199,200
	<   nodeSelector: {}
	---
	>   nodeSelector:
	>     role: proxy
	247c251,253
	<     annotations: {}
	---
	>     annotations:
	>       service.beta.kubernetes.io/aws-load-balancer-type: nlb


	# helm install --name ingress-nginx --namespace infra -f values.yaml.ingress-nginx.edit stable/nginx-ingress
			An example Ingress that makes use of the controller:
			
			apiVersion: extensions/v1beta1
			kind: Ingress
			metadata:
				annotations:
				  kubernetes.io/ingress.class: nginx
				name: example
				namespace: foo
			spec:
				rules:
				- host: www.example.com
					http:
					paths:
						- backend:
							serviceName: exampleService
							servicePort: 80
						path: /
				# This section is only required if TLS is to be enabled for the Ingress
				tls:
					- hosts:
						- www.example.com
					secretName: example-tls
			
			If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:
			
			apiVersion: v1
			kind: Secret
			metadata:
				name: example-tls
				namespace: foo
			data:
				tls.crt: <base64 encoded cert>
				tls.key: <base64 encoded key>
			type: kubernetes.io/tls
	
	# POD_NAME=$(kubectl get pods -n infra -l app=nginx-ingress -o jsonpath='{.items[0].metadata.name}')
	# kubectl exec -it $POD_NAME -n infra -- /nginx-ingress-controller --version	
	
	# clear; kc get pod,svc,ep,cm -n infra
	NAME                                                               READY   STATUS    RESTARTS   AGE
	pod/ingress-nginx-nginx-ingress-controller-btm6r                   1/1     Running   0          41s
	pod/ingress-nginx-nginx-ingress-controller-h8dk8                   1/1     Running   0          41s
	pod/ingress-nginx-nginx-ingress-default-backend-5cfccbcd7d-n5nzd   1/1     Running   0          41s
	
	NAME                                                  TYPE           CLUSTER-IP       EXTERNAL-IP                                                                          PORT(S)                      AGE
	service/ingress-nginx-nginx-ingress-controller        LoadBalancer   172.20.136.226   a822107b5a264463eaa31a707df7b36b-f72f20a7a37688cb.elb.ap-northeast-2.amazonaws.com   80:30425/TCP,443:30470/TCP   41s
	service/ingress-nginx-nginx-ingress-default-backend   ClusterIP      172.20.29.200    <none>                                                                               80/TCP                       41s
	
	NAME                                                    ENDPOINTS                                                  AGE
	endpoints/ingress-nginx-nginx-ingress-controller        10.5.121.90:80,10.5.137.1:80,10.5.121.90:443 + 1 more...   41s
	endpoints/ingress-nginx-nginx-ingress-default-backend   10.5.163.147:8080                                          41s
	
	NAME                                               DATA   AGE
	configmap/ingress-controller-leader-nginx          0      160m
	configmap/ingress-nginx-nginx-ingress-controller   3      42s

	============================================
	테스트 Appl 구성
	============================================
	# cd ~/EKS/cluster/NLB	
	# kubectl apply -f ns.test.yaml
	# kubectl apply -f apple.yaml
	# kubectl apply -f banana.yaml
	
	# ec2-user@ip-10-16-0-23:~/EKS/cluster/NLB # kc get svc -n infra
	NAME                                          TYPE           CLUSTER-IP       EXTERNAL-IP                                                                   		PORT(S)                      AGE
	ingress-nginx-nginx-ingress-controller        LoadBalancer   172.20.34.101    a822107b5a264463eaa31a707df7b36b-f72f20a7a37688cb.elb.ap-northeast-2.amazonaws.com	80:32067/TCP,443:30027/TCP   4m22s
	ingress-nginx-nginx-ingress-default-backend   ClusterIP      172.20.230.210   <none>                                                                        		80/TCP                       4m22s
	redis-ha-headless                             ClusterIP      None             <none>                                                                        		6379/TCP                     6h53m
	redis-ha-master                               ClusterIP      172.20.237.129   <none>                                                                        		6379/TCP                     6h53m
	redis-ha-slave                                ClusterIP      172.20.253.114   <none>                                                                        		6379/TCP                     6h53m
	
			* Defining the Ingress resource (with SSL termination) to route traffic to the services created above
			# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=ffptest.com/O=ffptest.com"
			# kubectl create secret tls tls-ffptest --key tls.key --cert tls.crt
		
	# cat ingress.yaml
	apiVersion: extensions/v1beta1
	kind: Ingress
	metadata:
	name: nlb-example
	namespace: test
	annotations:
		kubernetes.io/ingress.class: nginx
		#nginx.ingress.kubernetes.io/ssl-redirect: "false"
		#nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
		#nginx.ingress.kubernetes.io/rewrite-target: /
	spec:
	rules:
	- host: ffptest.com
		http:
		paths:
			- path: /apple
			backend:
				serviceName: apple-service
				servicePort: 5678
			- path: /banana
			backend:
				serviceName: banana-service
				servicePort: 5678
	# This section is only required if TLS is to be enabled for the Ingress
	#tls:
	#    - hosts:
	#        - www.example.com
	#      secretName: example-tls
	
	# cat ingress.subdomain.yaml
	apiVersion: extensions/v1beta1
	kind: Ingress
	metadata:
	name: nlb-example-sub
	namespace: test
	annotations:
		kubernetes.io/ingress.class: nginx
		#nginx.ingress.kubernetes.io/ssl-redirect: "false"
		#nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
		#nginx.ingress.kubernetes.io/rewrite-target: /
	spec:
	rules:
	- host: sub.ffptest.com
		http:
		paths:
			- path: /apple
			backend:
				serviceName: apple-service
				servicePort: 5678
			- path: /banana
			backend:
				serviceName: banana-service
				servicePort: 5678
	# This section is only required if TLS is to be enabled for the Ingress
	#tls:
	#    - hosts:
	#        - www.example.com
	#      secretName: example-tls
	
	# cat ingress.subdomain.yaml
	apiVersion: extensions/v1beta1
	kind: Ingress
	metadata:
	name: nlb-example-www
	namespace: test
	annotations:
		kubernetes.io/ingress.class: nginx
		#nginx.ingress.kubernetes.io/ssl-redirect: "false"
		#nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
		#nginx.ingress.kubernetes.io/rewrite-target: /
	spec:
	rules:
	- host: www.ffptest.com
		http:
		paths:
			- path: /apple
			backend:
				serviceName: apple-service
				servicePort: 5678
			- path: /banana
			backend:
				serviceName: banana-service
				servicePort: 5678
	# This section is only required if TLS is to be enabled for the Ingress
	#tls:
	#    - hosts:
	#        - www.example.com
	#      secretName: example-tls
					
	# kubectl apply -f ingress.yaml
	# kubectl apply -f ingress.www.yaml
	# kubectl apply -f ingress.subdomain.yaml
	
	# kc get pod,svc,ingress -n test -o wide
	NAME             READY   STATUS    RESTARTS   AGE   IP             NODE                                              NOMINATED NODE   READINESS GATES
	pod/apple-app    1/1     Running   0          79m   10.5.122.231   ip-10-5-106-194.ap-northeast-2.compute.internal   <none>           <none>
	pod/banana-app   1/1     Running   0          23m   10.5.182.54    ip-10-5-167-97.ap-northeast-2.compute.internal    <none>           <none>

	NAME                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE   SELECTOR
	service/apple-service    ClusterIP   172.20.93.59     <none>        5678/TCP   79m   app=apple
	service/banana-service   ClusterIP   172.20.209.147   <none>        5678/TCP   23m   app=banana

	NAME                                 HOSTS             ADDRESS                     PORTS   AGE
	ingress.extensions/nlb-example       ffptest.com       10.5.101.252,10.5.144.181   80      157m
	ingress.extensions/nlb-example-sub   sub.ffptest.com   10.5.101.252,10.5.144.181   80      3m16s
	ingress.extensions/nlb-example-www   www.ffptest.com   10.5.101.252,10.5.144.181   80      3m16s
	
	# kc get svc -n infra
	NAME                                          TYPE           CLUSTER-IP       EXTERNAL-IP                                                                          PORT(S)                      AGE
	ingress-nginx-nginx-ingress-controller        LoadBalancer   172.20.136.226   a822107b5a264463eaa31a707df7b36b-f72f20a7a37688cb.elb.ap-northeast-2.amazonaws.com   80:30425/TCP,443:30470/TCP   16m
	ingress-nginx-nginx-ingress-default-backend   ClusterIP      172.20.29.200    <none>                                                                               80/TCP                       16m
	
	
	* 접속 TEST
	# curl -H "Host: ffptest.com" http://a822107b5a264463eaa31a707df7b36b-f72f20a7a37688cb.elb.ap-northeast-2.amazonaws.com/banana
	# curl -H "Host: ffptest.com" http://a822107b5a264463eaa31a707df7b36b-f72f20a7a37688cb.elb.ap-northeast-2.amazonaws.com/apple
	

	============================================	
	[ Route53 에서 Domain 생성 ]
	※ https://docs.aws.amazon.com/ko_kr/Route53/latest/DeveloperGuide/migrate-dns-domain-in-use.html
	============================================
	
	* AWS -> Route 53 -> Domain registration -> Register Domain -> "ffptest.com" 생성
	  => Domain Name : ffptest.com
	  => Type        : Public Hosted Zone ( EKS Cluster의 Public Subnet 선택 )	  

	============================================	
	[ Route53 에서 Hosted Zone 생성 ]  ffptest.com 으로 호출시 NLB로 연결되도록
	※ https://medium.com/@labcloud/aws-route-53-%EC%97%90-%EB%8F%84%EB%A9%94%EC%9D%B8-%EB%93%B1%EB%A1%9D%ED%95%98%EC%97%AC-%EC%82%AC%EC%9A%A9%ED%95%98%EA%B8%B0-e2d9da2e864d
	============================================ 
	* AWS -> Route 53 -> Hosted zone -> Create Hosted Zone -> Create Record Set
	  => Name		: 빈칸
	  => Type		: A - IPv4 address
	  => Alias		: Yes
		 - Alias Target   			: a822107b5a264463eaa31a707df7b36b-f72f20a7a37688cb.elb.ap-northeast-2.amazonaws.com  ( 목록 누르면 ELB Network load balancers 에서 선택 )
		 - Routing Policy 			: Simple
		 - Evaluate Target Health	: No
	
	* PC에 DNS 서버 변경
	  - AWS -> Route 53 -> Hosted zone 에서 보이는 ns-###.awsdns-## 중에서 아무거나 하나 찍어서
	  - PC에 CMD 창에서
	    tracert ns-37.awsdns-04.com 실행해서 나오는 IP 확인
		=> 205.251.192.37 임
	  - PC에 네트워크 설정 -> DNS 서버 -> 보조 DNS IP를 205.251.192.37 로 변경
	  
	  나는 아래 4개 나옴
	  * ns-1834.awsdns-37.co.uk
	  * ns-1292.awsdns-33.org
	  * ns-550.awsdns-04.net 
	  * ns-37.awsdns-04.com
	
	* PC에 브라우저 열고 http://ffptest.com/apple  페이지 Open
	* PC에 브라우저 열고 http://ffptest.com/banana 페이지 Open
	
	
	============================================
	[ Route53 에서 Hosted Zone 생성 ]  sub.ffptest.com 으로 호출시 NLB로 연결되도록
	※ https://medium.com/@labcloud/aws-route-53-%EC%97%90-%EB%8F%84%EB%A9%94%EC%9D%B8-%EB%93%B1%EB%A1%9D%ED%95%98%EC%97%AC-%EC%82%AC%EC%9A%A9%ED%95%98%EA%B8%B0-e2d9da2e864d
	============================================
	* AWS -> Route 53 -> Hosted zone -> Create Hosted Zone -> Create Record Set
	  => Name			: sub
	  => Type			: CNAME - Canonical name
	  => Alias			: No
	     - Value		: ffptest.com
	  => Routing Policy : Simple
	  
	* PC에 브라우저 열고 http://sub.ffptest.com/apple  페이지 Open
	* PC에 브라우저 열고 http://sub.ffptest.com/banana 페이지 Open
	
	============================================
	[ Route53 에서 Hosted Zone 생성 ]  sub.ffptest.com 으로 호출시 NLB로 연결되도록
	※ https://medium.com/@labcloud/aws-route-53-%EC%97%90-%EB%8F%84%EB%A9%94%EC%9D%B8-%EB%93%B1%EB%A1%9D%ED%95%98%EC%97%AC-%EC%82%AC%EC%9A%A9%ED%95%98%EA%B8%B0-e2d9da2e864d
	============================================
	* AWS -> Route 53 -> Hosted zone -> Create Hosted Zone -> Create Record Set
	  => Name			: www
	  => Type			: CNAME - Canonical name
	  => Alias			: No
	     - Value		: ffptest.com
	  => Routing Policy : Simple
	  
	* PC에 브라우저 열고 http://www.ffptest.com/apple  페이지 Open
	* PC에 브라우저 열고 http://www.ffptest.com/banana 페이지 Open
	  
	  
	============================================
	[ PC에 DNS 서버 설정 변경없이 호출되게 하는 방법 ] 핸드폰에 웹브라우저로 호출되게 하는 방법
	※ https://docs.aws.amazon.com/ko_kr/Route53/latest/DeveloperGuide/migrate-dns-domain-in-use.html
	※ https://docs.aws.amazon.com/ko_kr/Route53/latest/DeveloperGuide/troubleshooting-domain-unavailable.html
	※ https://docs.aws.amazon.com/ko_kr/Route53/latest/DeveloperGuide/domain-view-status.html
	※ https://teddylee777.github.io/aws/%EC%95%84%EB%A7%88%EC%A1%B4AWS-%EC%9D%B8%EC%8A%A4%ED%84%B4%EC%8A%A4-%EB%8F%84%EB%A9%94%EC%9D%B8-%EC%97%B0%EA%B2%B0%ED%95%98%EA%B8%B0
	
	※ https://galid1.tistory.com/358
	============================================
	
	1. 일단 Route53에서 구매한 Domain의 등록 상태를 확인
	   # AWS -> Route53 -> Registered domains -> "Domain name status code" 확인 ( 도메인 생성한 직후는 "addPeriod" 임 )
	     => https://www.icann.org/resources/pages/epp-status-codes-2014-06-16-en 에서 확인해보면
	        최초 Domain을 등록시에 소요되는 시간 ( 이때 삭제하면 돈 돌려준데 )
		    => "This grace period is provided after the initial registration of a domain name.
		        If the registrar deletes the domain name during this period,
				the registry may provide credit to the registrar for the cost of the registration."
				
	   ※ DNS 갱신내용이 전파되는데는 최대 48시간까지 걸릴수도 있다고 한다.
	      => https://notice.tistory.com/2358
	   
	
	###### 테스트는 아래처럼 했는데 ######
	
	* PC에 DNS 서버 변경
	  - AWS -> Route 53 -> Hosted zone 에서 보이는 ns-###.awsdns-## 중에서 아무거나 하나 찍어서
	  - PC에 CMD 창에서
	    tracert ns-37.awsdns-04.com 실행해서 나오는 IP 확인
		=> 205.251.192.37 임
	  - PC에 네트워크 설정 -> DNS 서버 -> 보조 DNS IP를 205.251.192.37 로 변경
	  
	###### 글로벌에서 테스트되도록 ######
	
	* PC에 DNS 서버 변경
	  - PC에 네트워크 설정 -> DNS 서버 -> 보조 DNS IP를 8.8.8.8 로 변경 ( Google DNS로 )
