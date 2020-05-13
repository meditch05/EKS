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
   # kubectl label nodes ip-10-5-175-248.ap-northeast-2.compute.internal node-role.kubernetes.io/proxy=true
   # kubectl label nodes ip-10-5-129-227.ap-northeast-2.compute.internal node-role.kubernetes.io/proxy=true
   
   # kubectl label nodes ip-10-5-152-14.ap-northeast-2.compute.internal  node-role.kubernetes.io/worker=true
   # kubectl label nodes ip-10-5-126-137.ap-northeast-2.compute.internal node-role.kubernetes.io/worker=true
   # kubectl label nodes ip-10-5-160-219.ap-northeast-2.compute.internal node-role.kubernetes.io/worker=true


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
	# diff values.yaml.ingress-nginx.edit values.yaml.ingress-nginx.ori
        134c134
        <   kind: Deployment
        ---
        >   kind: DaemonSet
        196c196,197
        <   nodeSelector: {}
        ---
        >   nodeSelector:
        >     role: proxy
        247c248,250
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
	
	# clear; kc get svc,ep,pod -n infra
	NAME                                                  TYPE           CLUSTER-IP       EXTERNAL-IP                                                                   PORT(S)                      AGE
	service/ingress-nginx-nginx-ingress-controller        LoadBalancer   172.20.241.87    a84e52c89fe2848fba967f30111b1ffb-974291596.ap-northeast-2.elb.amazonaws.com   80:31958/TCP,443:31305/TCP   10m
	service/ingress-nginx-nginx-ingress-default-backend   ClusterIP      172.20.196.55    <none>                                                                        80/TCP                       10m
	
	NAME                                                    ENDPOINTS                                                      AGE
	endpoints/ingress-nginx-nginx-ingress-controller        10.16.149.39:80,10.16.44.132:80,10.16.149.39:443 + 1 more...   10m
	endpoints/ingress-nginx-nginx-ingress-default-backend   10.16.33.124:8080                                              10m

	
	
						[ helm 버전 - helm version 3 ]
						# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
						# helm install ingress-nginx
	
						***** [ git 버전 ]
						==> https://aws.amazon.com/premiumsupport/knowledge-center/eks-access-kubernetes-services/
							( Last updated: 2020-01-29 )
						==> https://kubernetes.github.io/ingress-nginx/deploy/#network-load-balancer-nlb
						
						[ nginx-ingress-controller 구성 ]
						# cd ~/EKS/cluster
						# git clone https://github.com/nginxinc/kubernetes-ingress.git
						# cd nginx-ingress-controller/kubernetes-ingress/deployments
						# kubectl apply -f common/ns-and-sa.yaml
						# kubectl apply -f common/default-server-secret.yaml
						# kubectl apply -f common/nginx-config.yaml
						# kubectl apply -f rbac/rbac.yaml
						# kubectl apply -f daemon-set/nginx-ingress.yaml
						# kubectl get pods --namespace=nginx-ingress
	
						[ nginx-ingress-controller 구성 ]
						# kubectl apply -f service/loadbalancer-aws-elb.yaml
	
	
		
						***** [ kubernetes/ingress-nginx 버전 ]
						==> https://kubernetes.github.io/ingress-nginx/deploy/#aws
							- SSL 미사용 버전
							- SSL 사용 버전
						
						# cd ~/EKS/cluster/nginx-ingress-controller
						# wget -O nginx-ic.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/deploy.yaml 
						# wget -O nginx-ic-tls.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/204739fb6650c48fd41dc9505f8fd9ef6bc768e1/deploy/static/provider/aws/deploy-tls-termination.yaml
							=> ACM 이랑 연동해서 쓰는거
						# kubectl apply -f nginx-ic.yaml
			
			
						============================================
						[ NLB 로 Ingress 구성 / 테스트 ] ==> helm 버전에 맞게 수정
						============================================
						==> https://aws.amazon.com/blogs/opensource/network-load-balancer-nginx-ingress-controller-eks/
							( by Cornell Anthony | on 09 AUG 2019  )
							ALB보다 NLB를 쓰는게 더 좋다 
							- ALB + ALB Ingress Controller		: Ingress 1개당 Load Balaner 가 1개씩 생성됨 ==> 비용 
							- NLB + Ngingx Ingress Controller	: Load Balancer가 1개만 써서, ingress 를 여러개 쓸수 있고, 모든 Namespace에 대해서 Access 가능, path-based routing 이 가능함
							
							* Static IP/elastic IP addresses	: For each Availability Zone (AZ) you enable on the NLB, you have a network interface. Each load balancer node in the AZ uses this network interface to get a static IP address. You can also use Elastic IP to assign a fixed IP address for each Availability Zone.
							* Scalability						: Ability to handle volatile workloads and scale to millions of requests per second.
							* Zonal isolation					: The Network Load Balancer can be used for application architectures within a Single Zone. Network Load Balancers attempt to route a series of requests from a particular source to targets in a single AZ while still providing automatic failover should those targets become unavailable.
							* Source/remote address preservation: With a Network Load Balancer, the original source IP address and source ports for the incoming connections remain unmodified. With Classic and Application load balancers, we had to use HTTP header X-Forwarded-For to get the remote IP address.
							* Long-lived TCP connections		: Network Load Balancer supports long-running TCP connections that can be open for months or years, making it ideal for WebSocket-type applications, IoT, gaming, and messaging applications.
							* Reduced bandwidth usage			: Most applications are bandwidth-bound and should see a cost reduction (for load balancing) of about 25% compared to Application or Classic Load Balancers.
							* SSL termination					: SSL termination will need to happen at the backend, since SSL termination on NLB for Kubernetes is not yet available.
							
							
						==> https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-elb-load-balancer.html
						==> https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-creating.html#resource-record-sets-elb-dns-name-procedure
						==> https://aws.amazon.com/ko/route53/pricing/
							- 12시간내에 삭제한 domain에 대해서는 과금X
						
						* How to use a Network Load Balancer with the NGINX Ingress resource in Kubernetes
	
	# cd ~/EKS/cluster/NLB
	# wget https://raw.githubusercontent.com/cornellanthony/nlb-nginxIngress-eks/master/nlb-service.yaml
	# wget https://raw.githubusercontent.com/cornellanthony/nlb-nginxIngress-eks/master/apple.yaml
	# wget https://raw.githubusercontent.com/cornellanthony/nlb-nginxIngress-eks/master/banana.yaml
	
	# kubectl apply -f ns.test.yaml
	# kubectl apply -f apple.yaml
	# kubectl apply -f banana.yaml
	
	# ec2-user@ip-10-16-0-23:~/EKS/cluster/NLB # kc get svc -n infra
	NAME                                          TYPE           CLUSTER-IP       EXTERNAL-IP                                                                   PORT(S)                      AGE
	ingress-nginx-nginx-ingress-controller        LoadBalancer   172.20.34.101    a732bae8f852b44acbaa3ddc7c22a9dc-518580590.ap-northeast-2.elb.amazonaws.com   80:32067/TCP,443:30027/TCP   4m22s
	ingress-nginx-nginx-ingress-default-backend   ClusterIP      172.20.230.210   <none>                                                                        80/TCP                       4m22s
	redis-ha-headless                             ClusterIP      None             <none>                                                                        6379/TCP                     6h53m
	redis-ha-master                               ClusterIP      172.20.237.129   <none>                                                                        6379/TCP                     6h53m
	redis-ha-slave                                ClusterIP      172.20.253.114   <none>                                                                        6379/TCP                     6h53m
	
			* Defining the Ingress resource (with SSL termination) to route traffic to the services created above
			# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=ffptest.com/O=ffptest.com"
			# kubectl create secret tls tls-ffptest --key tls.key --cert tls.crt
		
	* Create Ingress
	# vi ingress.yaml
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

					
	# kubectl apply -f ingress.yaml
	
				* Set up Route 53 to have your domain pointed to the NLB (optional):
				anthonycornell.com.
				A.    ALIAS abf3d14967d6511e9903d12aa583c79b-e3b2965682e9fbde.elb.us-east-1.amazonaws.com 
	
	# kc get pod,svc,ingress -n test -o wide
	NAME             READY   STATUS    RESTARTS   AGE     IP             NODE                                              NOMINATED NODE   READINESS GATES
	pod/apple-app    1/1     Running   0          3m49s   10.5.183.207   ip-10-5-175-248.ap-northeast-2.compute.internal   <none>           <none>
	pod/banana-app   1/1     Running   0          3m45s   10.5.104.208   ip-10-5-126-137.ap-northeast-2.compute.internal   <none>           <none>
	
	NAME                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE     SELECTOR
	service/apple-service    ClusterIP   172.20.11.64   <none>        5678/TCP   3m49s   app=apple
	service/banana-service   ClusterIP   172.20.7.115   <none>        5678/TCP   3m45s   app=banana
	
	NAME                             HOSTS         ADDRESS                                                           PORTS   AGE
	ingress.extensions/nlb-example   ffptest.com   10.5.126.137,10.5.129.227,10.5.152.14,10.5.160.219,10.5.175.248   80      2m36s
	
	
	* 접속 TEST
	# curl -H "Host: ffptest.com" http://a732bae8f852b44acbaa3ddc7c22a9dc-518580590.ap-northeast-2.elb.amazonaws.com/banana
	# curl -H "Host: ffptest.com" http://a732bae8f852b44acbaa3ddc7c22a9dc-518580590.ap-northeast-2.elb.amazonaws.com/apple
	


==========================
해야할거
==========================
1. Route53 에서 Domain 따서 NLB로 붙여서 해보기
	# curl http://ffptest.com/banana
	# curl http://ffptest.com/apple
   
1. EFS 구성
2. EFS Provisioner 구성
3. EFS 써서 PVC 만들기
4. PVC 사용하는 Sample App 개발/배포
5. 잘되는지 보기














	

	
	
	
	
	
	
	* Ingress 선언시 다른 Namespace를 지정할 경우 subdomain 을 사용할 수 있음
		apiVersion: extensions/v1beta1
		kind: Ingress
		metadata:
		name: api-ingresse-test
		namespace: test
		annotations:
		kubernetes.io/ingress.class: "nginx"
		spec:
		rules:
		- host: test.anthonycornell.com
		http:
			paths:
			- backend:
				serviceName: myApp
				servicePort: 80
			path: /
		
		
		
	
	============================================
	[ ALB 로 Ingress 구성 / 테스트 ]
	============================================
	# eksctl utils associate-iam-oidc-provider --region ap-northeast-2 --cluster ffp-cluster-eksctl --approve
	[ℹ]  eksctl version 0.16.0
	[ℹ]  using region ap-northeast-2
	[ℹ]  will create IAM Open ID Connect provider for cluster "ffp-cluster-eksctl" in "ap-northeast-2"
	[✔]  created IAM Open ID Connect provider for cluster "ffp-cluster-eksctl" in "ap-northeast-2"
	
	[ eksctl Create Policy ]
	# aws iam create-policy --policy-name ALBIngressControllerIAMPolicy --policy-document https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/iam-policy.json
	# wget https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/iam-policy.json
	# aws iam create-policy --policy-name ALBIngressControllerIAMPolicy --policy-document file://./iam-policy.json
	
	# aws iam list-policies | jq . > list-policies
	# cat list-policies | jq '.Policies[] | select ( .PolicyName == "ALBIngressControllerIAMPolicy")'
	{
	"PolicyName": "ALBIngressControllerIAMPolicy",
	"PolicyId": "ANPAZMKVASO3B3QSEXPRT",
	"Arn": "arn:aws:iam::644960261046:policy/ALBIngressControllerIAMPolicy",
	"Path": "/",
	"DefaultVersionId": "v1",
	"AttachmentCount": 0,
	"PermissionsBoundaryUsageCount": 0,
	"IsAttachable": true,
	"CreateDate": "2020-04-20T05:34:36+00:00",
	"UpdateDate": "2020-04-20T05:34:36+00:00"
	}
	
	# wget https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/rbac-role.yaml
	# mv rbac-role.yaml alb-rbac-role.yaml
	# kubectl apply -f alb-rbac-role.yaml
	
	# eksctl create iamserviceaccount \
    --region ap-northeast-2 \
    --name alb-ingress-controller \
    --namespace kube-system \
    --cluster ffp-cluster-eksctl \
    --attach-policy-arn arn:aws:iam::644960261046:policy/ALBIngressControllerIAMPolicy \
    --override-existing-serviceaccounts \
    --approve
	
	[ℹ]  eksctl version 0.16.0
	[ℹ]  using region ap-northeast-2
	[ℹ]  1 iamserviceaccount (kube-system/alb-ingress-controller) was included (based on the include/exclude rules)
	[!]  metadata of serviceaccounts that exist in Kubernetes will be updated, as --override-existing-serviceaccounts was set
	[ℹ]  1 task: { 2 sequential sub-tasks: { create IAM role for serviceaccount "kube-system/alb-ingress-controller", create serviceaccount "kube-system/alb-ingress-controller" } }
	[ℹ]  building iamserviceaccount stack "eksctl-ffp-cluster-eksctl-addon-iamserviceaccount-kube-system-alb-ingress-controller"
	[ℹ]  deploying stack "eksctl-ffp-cluster-eksctl-addon-iamserviceaccount-kube-system-alb-ingress-controller"
	[ℹ]  serviceaccount "kube-system/alb-ingress-controller" already exists
	[ℹ]  updated serviceaccount "kube-system/alb-ingress-controller"
	
	# eksctl get cluster
	NAME                    REGION
	ffp-cluster-eksctl      ap-northeast-2

	# aws ec2 describe-vpcs | jq '.Vpcs[] | .CidrBlock, .VpcId'
	
	# wget https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/alb-ingress-controller.yaml
	# kubectl apply -f alb-ingress-controller.yaml
	# vi alb-ingress-controller.yaml
	# kubectl apply -f alb-ingress-controller.yaml
	deployment.apps/alb-ingress-controller configured
	
	# kubectl get pods -l "app.kubernetes.io/name=<Ingress name>,app.kubernetes.io/instance=alb" -n kube-system
	
	# wget  https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/2048/2048-namespace.yaml
	# wget  https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/2048/2048-deployment.yaml
	# wget  https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/2048/2048-service.yaml
	# wget  https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/2048/2048-ingress.yaml

	# kubectl apply -f 2048-namespace.yaml
	# kubectl apply -f 2048-deployment.yaml
	# kubectl apply -f 2048-service.yaml
	# kubectl apply -f 2048-ingress.yaml
	
	# kc get ing --all-namespaces
	NAMESPACE   NAME           HOSTS   ADDRESS                                                                       PORTS   AGE
	2048-game   2048-ingress   *       6dd2b3d3-2048game-2048ingr-6fa0-1707268499.ap-northeast-2.elb.amazonaws.com   80      37m
	
	# curl http://6dd2b3d3-2048game-2048ingr-6fa0-1707268499.ap-northeast-2.elb.amazonaws.com
	
	
	# curl -I -H "Host: ffptest.com" http://10.16.140.75/banana
	# curl -I -H "Host: ffptest.com" http://52.79.237.122/banana
	# curl -I -H "Host: ffptest.com" http://a84e52c89fe2848fba967f30111b1ffb-974291596.ap-northeast-2.elb.amazonaws.com/banana
	
	# traceroute a84e52c89fe2848fba967f30111b1ffb-974291596.ap-northeast-2.elb.amazonaws.com
	# vi /etc/hosts
	13.124.34.223 ffptest.com
	# curl http://www.ffptest.com
	
	
	# curl -I -H "Host: www.ffptest.com" http://10.16.140.75/banana
	# curl -I -H "Host: www.ffptest.com" http://10.16.140.75/banana
	# curl -I -H "Host: www.ffptest.com" http://10.16.140.75/banana
	
	

		
		
	
	
	
	
	
	


	
	

###############################################################################################################################################################################
# [ eksctl 사용 버전으로 다시 ]
###############################################################################################################################################################################
1. EKS용 CloudStack 생성 ( EKS-STACK-VPC )
   
   => 01_sk-IaC-infra-vpc-base-EKS.yaml 파일
	  - StackCreater		: kjh-00004-aws-d ( IAM User명 )

	  [ CloudStack Event Log ]		
	- 2020-04-13 14:44:05 UTC+0900	EKS-BASE-STACK								CREATE_COMPLETE	-
	- 2020-04-13 14:44:03 UTC+0900	skIaCVpcRoute2Route							CREATE_COMPLETE	-
	- 2020-04-13 14:43:47 UTC+0900	skIaCVpcRoute1Route							CREATE_COMPLETE	-
	- 2020-04-13 14:43:45 UTC+0900	skIaCNat2									CREATE_COMPLETE	-
	- 2020-04-13 14:43:29 UTC+0900	skIaCNat1									CREATE_COMPLETE	-
	- 2020-04-13 14:41:57 UTC+0900	SKIaCNATPublicSubnet2RouteTableAssociation	CREATE_COMPLETE	-
	- 2020-04-13 14:41:57 UTC+0900	SKIaCNATPublicSubnet1RouteTableAssociation	CREATE_COMPLETE	-
	- 2020-04-13 14:41:56 UTC+0900	skIaCVpcRouteRoute							CREATE_COMPLETE	-
	- 2020-04-13 14:41:40 UTC+0900	SKIaCNATPublicSubnet2						CREATE_COMPLETE	-
	- 2020-04-13 14:41:40 UTC+0900	SKIaCNATPublicSubnet1						CREATE_COMPLETE	-
	- 2020-04-13 14:41:39 UTC+0900	VPCGatewayAttachment						CREATE_COMPLETE	-
	- 2020-04-13 14:41:25 UTC+0900	skIaCVpcRoute								CREATE_COMPLETE	-
	- 2020-04-13 14:41:25 UTC+0900	skIaCVpcRoute1								CREATE_COMPLETE	-
	- 2020-04-13 14:41:24 UTC+0900	skIaCVpcRoute2								CREATE_COMPLETE	-
	- 2020-04-13 14:41:22 UTC+0900	skIaCEip1									CREATE_COMPLETE	-
	- 2020-04-13 14:41:22 UTC+0900	skIaCVpc									CREATE_COMPLETE	-
	- 2020-04-13 14:41:21 UTC+0900	skIaCEip2									CREATE_COMPLETE	-
	- 2020-04-13 14:41:21 UTC+0900	skIaCVpcIgw									CREATE_COMPLETE	-
	...
	- 2020-04-13 14:41:02 UTC+0900	EKS-BASE-STACK								CREATE_IN_PROGRESS	User Initiated

2. EKS용 CloudStack 생성 ( EKS-STACK-SUBNET )

   => 02_sk-IaC-infra-vpc-svc-EKSCluster.yaml 파일
      - ParentStackName : EKS-BASE_STACK   ( 1에서 생성한 STACK명 )
	  - StackCreater		: kjh-00004-aws-d ( IAM User명 )
	  
	  [ CloudStack Event Log ]
	- 2020-04-13 14:53:13 UTC+0900	EKS-CLUSTER-STACK									CREATE_COMPLETE	-
	- 2020-04-13 14:53:11 UTC+0900	SVCNodeGroup1PrivateSubnet1RouteTableAssociation	CREATE_COMPLETE	-
	- 2020-04-13 14:53:11 UTC+0900	SVCNodeGroup2PrivateSubnet1RouteTableAssociation	CREATE_COMPLETE	-
	- 2020-04-13 14:53:11 UTC+0900	SVCLoadBalancePublicSubnet2RouteTableAssociation	CREATE_COMPLETE	-
	- 2020-04-13 14:53:11 UTC+0900	SVCLoadBalancePublicSubnet1RouteTableAssociation	CREATE_COMPLETE	-
	- 2020-04-13 14:53:11 UTC+0900	SVCNodeGroup1PrivateSubnet2RouteTableAssociation	CREATE_COMPLETE	-
	- 2020-04-13 14:53:10 UTC+0900	SVCNodeGroup2PrivateSubnet2RouteTableAssociation	CREATE_COMPLETE	-
	- 2020-04-13 14:52:54 UTC+0900	SVCNodeGroup2PrivateSubnet1							CREATE_COMPLETE	-
	- 2020-04-13 14:52:54 UTC+0900	SVCNodeGroup1PrivateSubnet1							CREATE_COMPLETE	-
	- 2020-04-13 14:52:53 UTC+0900	SVCLoadBalancePublicSubnet1							CREATE_COMPLETE	-
	- 2020-04-13 14:52:53 UTC+0900	SVCLoadBalancePublicSubnet2							CREATE_COMPLETE	-
	- 2020-04-13 14:52:53 UTC+0900	SVCNodeGroup1PrivateSubnet2							CREATE_COMPLETE	-
	- 2020-04-13 14:52:53 UTC+0900	SVCNodeGroup2PrivateSubnet2							CREATE_COMPLETE	-
	- 2020-04-13 14:52:42 UTC+0900	ControlPlaneSecurityGroup							CREATE_COMPLETE	-
	...
	- 2020-04-13 14:52:33 UTC+0900	EKS-CLUSTER-STACK									CREATE_IN_PROGRESS	User Initiated
	
3. IAM Role 생성

	[ 수동생성한 Role - BASTION 서버용 ]
	- Role명	: 	EKS-BASTION-ROLE
	- Policy	: 	AmazonEC2FullAccess
	
	[ 수동생성한 Role - EKS Cluster 용 ]
	- Role명	: 	EKS-IAM-ROLE
	- Policy	: 	AmazonEKSClusterPolicy
					AmazonEKSServicePolicy
					AmazonEKSWorkerNodePolicy
					AmazonEC2ContainerServiceAutoscaleRole
					AmazonEKS_CNI_Policy
					
	[ eksctl 로 Cluster 생성시 생기는 Role ]
	
	- Role명	:	eksctl-ffp-cluster-type2-cluster-ServiceRole-ZC9CRAM4Y4Y2
	- Policy	: 	AmazonEKSClusterPolicy
					AmazonEKSServicePolicy
					eksctl-ffp-cluster-type2-cluster-PolicyCloudWatchMetrics
						CloudWatch ( Limited: Write)
					eksctl-ffp-cluster-type2-cluster-PolicyNLB
						EC2		( Limited: List, Read, Write )
						ELB
						ELB v2

	- Role명	:	eksctl-ffp-cluster-type2-nodegrou-NodeInstanceRole-BZ0495K6XAGP
	- Policy	: 	AmazonEKSWorkerNodePolicy
					AmazonEC2ContainerRegistryReadOnly
					CloudWatchAgentServerPolicy
					AmazonEKS_CNI_Policy
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-proxy-PolicyALBIngress
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-proxy-PolicyAutoScaling
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-proxy-PolicyEBS
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-proxy-PolicyEFS
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-proxy-PolicyEFSEC2
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-proxy-PolicyFSX
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-proxy-PolicyServiceLinkRole
					
	- Role명	:	eksctl-ffp-cluster-type2-nodegrou-NodeInstanceRole-ZIU7621Q4XIY
	- Policy	: 	AmazonEKSWorkerNodePolicy
					AmazonEC2ContainerRegistryReadOnly
					CloudWatchAgentServerPolicy
					AmazonEKS_CNI_Policy
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-worker-PolicyALBIngress
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-worker-PolicyAutoScaling
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-worker-PolicyEBS
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-worker-PolicyEFS
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-worker-PolicyEFSEC2
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-worker-PolicyFSX
					eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-worker-PolicyServiceLinkRole

4. EKS Cluster 생성

	1. 김상경 수석님 CloudFormation 활용 -> eksctl 사용
	   => 실패 ( 25분 Timeout남 )
	   
	2. VPC / PrivateSubnet만 생성 -> eksctl 사용
	   => 성공
	   
	3. VPC도 없이 그냥 eksctl만 사용
	   => 
		# date; eksctl create cluster -f ffp-cluster-type4.yaml --timeout 10m ; date

========================================================================================================================================================================================
Logical ID									Physical ID													Type									Status				Status reason
========================================================================================================================================================================================
ClusterSharedNodeSecurityGroup				sg-0c144efed20a0c61e										AWS::EC2::SecurityGroup					CREATE_COMPLETE		-
ControlPlane								ffp-cluster-eksctl											AWS::EKS::Cluster						CREATE_IN_PROGRESS	Resource creation Initiated
ControlPlaneSecurityGroup					sg-012172f403cfb91eb										AWS::EC2::SecurityGroup					CREATE_COMPLETE	-
IngressInterNodeGroupSG						IngressInterNodeGroupSG										AWS::EC2::SecurityGroupIngress			CREATE_COMPLETE	-
InternetGateway								igw-0b5d69246f785cdd1										AWS::EC2::InternetGateway				CREATE_COMPLETE	-
NATGateway									nat-0e2957eced502ac1b										AWS::EC2::NatGateway					CREATE_COMPLETE	-
NATIP										15.164.65.190												AWS::EC2::EIP							CREATE_COMPLETE	-
NATPrivateSubnetRouteAPNORTHEAST2A			eksct-NATPr-12SDCGXZQG6V5									AWS::EC2::Route							CREATE_COMPLETE	-
NATPrivateSubnetRouteAPNORTHEAST2B			eksct-NATPr-1GQ03CF3FR75N									AWS::EC2::Route							CREATE_COMPLETE	-
NATPrivateSubnetRouteAPNORTHEAST2C			eksct-NATPr-SOUQC7J6N042									AWS::EC2::Route							CREATE_COMPLETE	-
PolicyCloudWatchMetrics						eksct-Poli-1G8VTNR6TP1VP									AWS::IAM::Policy						CREATE_COMPLETE	-
PolicyNLB									eksct-Poli-N9ZCDUJBE6PB										AWS::IAM::Policy						CREATE_COMPLETE	-
PrivateRouteTableAPNORTHEAST2A				rtb-0528b5b2b90a8f253										AWS::EC2::RouteTable					CREATE_COMPLETE	-
PrivateRouteTableAPNORTHEAST2B				rtb-0c25980856eb5947b										AWS::EC2::RouteTable					CREATE_COMPLETE	-
PrivateRouteTableAPNORTHEAST2C				rtb-06055ea631c1fd302										AWS::EC2::RouteTable					CREATE_COMPLETE	-
PublicRouteTable							rtb-0ddd8176cb256c0ea										AWS::EC2::RouteTable					CREATE_COMPLETE	-
PublicSubnetRoute							eksct-Publi-1HUX6Y407DLH1									AWS::EC2::Route							CREATE_COMPLETE	-
RouteTableAssociationPrivateAPNORTHEAST2A	rtbassoc-05cdf28a6d15a84c0									AWS::EC2::SubnetRouteTableAssociation	CREATE_COMPLETE	-
RouteTableAssociationPrivateAPNORTHEAST2B	rtbassoc-0049bfd5dec26114d									AWS::EC2::SubnetRouteTableAssociation	CREATE_COMPLETE	-
RouteTableAssociationPrivateAPNORTHEAST2C	rtbassoc-0bee072e160150648									AWS::EC2::SubnetRouteTableAssociation	CREATE_COMPLETE	-
RouteTableAssociationPublicAPNORTHEAST2A	rtbassoc-0e73a53a65fa9bebe									AWS::EC2::SubnetRouteTableAssociation	CREATE_COMPLETE	-
RouteTableAssociationPublicAPNORTHEAST2B	rtbassoc-02914f828b9523293									AWS::EC2::SubnetRouteTableAssociation	CREATE_COMPLETE	-
RouteTableAssociationPublicAPNORTHEAST2C	rtbassoc-0d1e9087549c456ef									AWS::EC2::SubnetRouteTableAssociation	CREATE_COMPLETE	-
ServiceRole									eksctl-ffp-cluster-eksctl-cluster-ServiceRole-ZG14HHCF65H7	AWS::IAM::Role							CREATE_COMPLETE	-
SubnetPrivateAPNORTHEAST2A					subnet-0716f8d368ad22e8c									AWS::EC2::Subnet						CREATE_COMPLETE	-
SubnetPrivateAPNORTHEAST2B					subnet-0247194ba9c724b05									AWS::EC2::Subnet						CREATE_COMPLETE	-
SubnetPrivateAPNORTHEAST2C					subnet-0b604fc9f306561a2									AWS::EC2::Subnet						CREATE_COMPLETE	-
SubnetPublicAPNORTHEAST2A					subnet-09ee797a4e7845069									AWS::EC2::Subnet						CREATE_COMPLETE	-
SubnetPublicAPNORTHEAST2B					subnet-01608ef7b2b64b1ed									AWS::EC2::Subnet						CREATE_COMPLETE	-
SubnetPublicAPNORTHEAST2C					subnet-0d263b7ff17097776									AWS::EC2::Subnet						CREATE_COMPLETE	-
VPC											vpc-0c8d51dea1fb62898										AWS::EC2::VPC							CREATE_COMPLETE	-
VPCGatewayAttachment						eksct-VPCGa-1FF1TRQO0WOUB									AWS::EC2::VPCGatewayAttachment			CREATE_COMPLETE	-
========================================================================================================================================================================================
	
	
	- ECR 과는 어떻게 연동할껀가?
		=> https://aws.amazon.com/blogs/compute/setting-up-aws-privatelink-for-amazon-ecs-and-amazon-ecr/
		=> Private Subnet에서 ECR을 사용하는 방법
		
	- eksctl 용으로 사용하는 yaml 로 cluster 생성이 아래 Error 가 발생하는건
		=> EC2 인스턴스가 EKS에 Join되지 못하기 때문임
		=> docker 가 정상적으로 재기동되지 않기 때문임
		=> VM에서 /etc/docker/daemon.json 수정하고 재기동해도면 안됨.

		[ℹ]  nodegroup "ffp-unmanaged-ng-proxy" has 0 node(s)
		[ℹ]  waiting for at least 1 node(s) to become ready in "ffp-unmanaged-ng-proxy"
		
		=> 아래 설정을 빼야함.
		preBootstrapCommands:
		# allow docker registries to be deployed as cluster service ( Need. ECR )
		- 'echo {\"insecure-registries\": [\"172.20.0.0/16\",\"10.100.0.0/16\"]} > /etc/docker/daemon.json'
		- "systemctl restart docker"
		
		=> 빼도 안됨
		=> 처음처럼 VPC / PrivateSubnet만 만들고 해보자 

	
	
	
======================================================================================================================================================
[ VPC 목록 ]
FFP-d-vpc								vpc-00bb68e8057b64f66		available	10.16.0.0/16	-	dopt-cd9412a6	rtb-0fa67eab5546bda1d	acl-0df9d65863775454e

[ VPC -> SubNet 목록 ]
service-loadbalance-public-d-subnet1	subnet-002e690f24d624b11	available	vpc-00bb68e8057b64f66 | FFP-d-vpc	10.16.0.32/27		27	-	ap-northeast-2a	apne2-az1	rtb-0cf2876ae6c946998 | FFP-d-route	acl-0df9d65863775454e
service-loadbalance-public-d-subnet2	subnet-05cdfcf164bc2c15b	available	vpc-00bb68e8057b64f66 | FFP-d-vpc	10.16.32.32/27		27	-	ap-northeast-2b	apne2-az2	rtb-0cf2876ae6c946998 | FFP-d-route	acl-0df9d65863775454e
service-loadbalance-public-d-subnet3	subnet-0c6a228a82c18d4d6	available	vpc-00bb68e8057b64f66 | FFP-d-vpc	10.16.64.32/27		27	-	ap-northeast-2c	apne2-az3	rtb-0cf2876ae6c946998 | FFP-d-route	acl-0df9d65863775454e
service-nat-public-p-subnet1			subnet-09e115e55da6e05a5	available	vpc-00bb68e8057b64f66 | FFP-d-vpc	10.16.0.0/28		9	-	ap-northeast-2a	apne2-az1	rtb-0cf2876ae6c946998 | FFP-d-route	acl-0df9d65863775454e
service-nat-public-p-subnet2			subnet-0628601413a6a344f	available	vpc-00bb68e8057b64f66 | FFP-d-vpc	10.16.32.0/28		10	-	ap-northeast-2b	apne2-az2	rtb-0cf2876ae6c946998 | FFP-d-route	acl-0df9d65863775454e
service-nat-public-p-subnet3			subnet-09e2e39c02024a7ba	available	vpc-00bb68e8057b64f66 | FFP-d-vpc	10.16.64.0/28		10	-	ap-northeast-2c	apne2-az3	rtb-0cf2876ae6c946998 | FFP-d-route	acl-0df9d65863775454e
service-nodegrp1-private-d-subnet1		subnet-0f7101ad7cff51732	available	vpc-00bb68e8057b64f66 | FFP-d-vpc	10.16.32.128/26		59	-	ap-northeast-2a	apne2-az1	rtb-0fa67eab5546bda1d	acl-0df9d65863775454e
service-nodegrp1-private-d-subnet2		subnet-0206185592766d486	available	vpc-00bb68e8057b64f66 | FFP-d-vpc	10.16.64.128/26		59	-	ap-northeast-2b	apne2-az2	rtb-0fa67eab5546bda1d	acl-0df9d65863775454e	
service-nodegrp1-private-d-subnet3		subnet-092fe63be54b653a4	available	vpc-00bb68e8057b64f66 | FFP-d-vpc	10.16.128.128/26	59	-	ap-northeast-2c	apne2-az3	rtb-0fa67eab5546bda1d	acl-0df9d65863775454e

[ Elastic IPs ]
FFP-d-eip1	3.34.63.10		eipalloc-022c22701e9ac1814	-	10.16.0.14	vpc	eipassoc-ba21b446	eni-0e288af5fb4f1f997	644960261046
FFP-d-eip2	13.125.111.139	eipalloc-099e69d04a04f127c	-	10.16.32.4	vpc	eipassoc-7b4aa2b6	eni-07099cc799bddc33c	644960261046
FFP-d-eip3	54.180.13.237	eipalloc-0a31652c91af8a7f1	-	10.16.64.12	vpc	eipassoc-15b56ccf	eni-0adefddc4c2f8176a	644960261046
======================================================================================================================================================



[ EC2 Type ]
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
Instance type	vCPUs	Architecture	Memory (MiB)	Storage (GB)	Storage type	Network performance		On-Demand Linux pricing		On-Demand Windows pricing
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
t3.medium		2		x86_64			4096			-				-				Up to 5 Gigabit			0.052  USD per Hour	   		0.0704 USD per Hour
t3.micro		2		x86_64			1024			-				-				Up to 5 Gigabit			0.013  USD per Hour

t2.medium		2		i386, x86_64	4096			-				-				Low to Moderate			0.0576 USD per Hour	   		0.0756 USD per Hour
t2.micro		1		i386, x86_64	1024			-				-				Low to Moderate			0.0144 USD per Hour	   		0.019 USD per Hour

※ t3.medium 로 3 Node / 24 시간 = 3.744 USD = 4,492원 ( 환율 1,200원 )



	
	





###############################################################################################################################################################################
# eksctl 사용 버전
###############################################################################################################################################################################
0. AWS CLI / eksctl 구성 ( 별도 VM에서 CentOS 생성후 수행 - https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html )

	[ Install jq ]
	# wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
	# chmod 777 jq-linux64
	# mv jq-linux64 /usr/bin/jq

	[ Install Python3 ]
	# yum install -y python3-devel.x86_64

	[ Install PIP ]
	# curl -O https://bootstrap.pypa.io/get-pip.py
	# python3 get-pip.py --user
	# pip3 --version
	WARNING: pip is being invoked by an old script wrapper. This will fail in a future version of pip.
	Please see https://github.com/pypa/pip/issues/5599 for advice on fixing the underlying issue.
	To avoid this problem you can invoke Python with '-m pip' instead of running pip directly.
	pip 20.0.2 from /root/.local/lib/python3.6/site-packages/pip (python 3.6)
	
	[ Install AWS CLI - Version 1.18.41 ]
	# pip3 install awscli --upgrade --user
	
	# vi ~/.bash_profile
	export PATH=${PATH}:~/.local/bin:.
	
	# . ~/.bash_profile
	
	# aws --version
	aws-cli/1.18.41 Python/3.6.8 Linux/3.10.0-1062.el7.x86_64 botocore/1.15.41

	
	[ AWS CLI - Configure ( Authentication 구성 ) ]
	# aws configure
	  - Access Key ID					: KKKKK ( AWS콘솔 -> IAM -> User -> Security credentials )
	  - Secret access key				: KKKKK ( Access Key 생성하고 나서 뜨는 팝업에서 "show" 에서만 보임. 잊어버리면 다시 만들어야함. "Download .csv file"로 파일저장해놓던지. )
	  - Default region name [None]		: ap-northeast-2
	  - Default output format [None]	: json
	# aws iam list-access-keys | jq .
	# aws ec2 describe-instances | jq .
	
	[ eksctl 설치 ]
	# curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
	# mv /tmp/eksctl /usr/local/bin
	# eksctl version
	0.16.0
	
	[ kubectl 설치 ]
	# curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
	# mv kubectl /usr/bin/kubectl
	# chmod 755  /usr/bin/kubectl
	# kubectl version

4. EKS용 CloudStack 생성 ( EKS-NODEGROUP-STACK )
   => 03_sk-IaC-infra-vpc-svc-EKSNodeGroup.yaml 파일
	  - ParentStackName 	: EKS-CLUSTER-STACK   ( 2에서 생성한 STACK명 )
	  - StackCreater		: KKKKK ( IAM User명 )
	  - EKS Cluster 		: FFP-EKS
	  - NodeGroupName 		: EKS-NODEGROUP
      - NodeInstanceType	: t3.medium ( 2 core / 4 GB )
	  - NodeImagedId		: ami-08a18de5609e8f781 ( 구글에서 "EKS AMI"로 Search )
	  - NodeVolumeSize		: 40
	  - KeyName				: ffp key ( KKKKK )
	  - Worker Network Configuration - SubNets	: service-nodegrp1-private-d-subnet1 ( 10.166/0.128/16 )
	  
	  ※ IAM을 생성한다는 Noti에 Check 하고 생성
	  ==> EC2 3개가 생성됨
	  ==> eksctl 로 지정해서 생성할거니까. EC2 3개는 삭제할것 ( Terminating ... )
	  
	  ※ EKS-NODEGROUP-role 이 생성되는데 AWS Service가 EC2임 ( 왜 EKS가 아니지?? )
	  
	  
	  
	  [ CloudStack Event Log ]
	- 2020-04-13 15:14:51 UTC+0900	EKS-NODEGROUP-1-STACK							CREATE_COMPLETE	-
	- 2020-04-13 15:14:49 UTC+0900	NodeGroup										CREATE_COMPLETE	-
	- 2020-04-13 15:13:15 UTC+0900	NodeLaunchConfig								CREATE_COMPLETE	-
	- 2020-04-13 15:13:12 UTC+0900	NodeInstanceProfile								CREATE_COMPLETE	-
	- 2020-04-13 15:11:08 UTC+0900	NodeInstanceRole								CREATE_COMPLETE	-
	- 2020-04-13 15:10:57 UTC+0900	ControlPlaneEgressToNodeSecurityGroup			CREATE_COMPLETE	-
	- 2020-04-13 15:10:57 UTC+0900	ControlPlaneEgressToNodeSecurityGroupOn443		CREATE_COMPLETE	-
	- 2020-04-13 15:10:57 UTC+0900	NodeSecurityGroupFromControlPlaneOn443Ingress	CREATE_COMPLETE	-
	- 2020-04-13 15:10:57 UTC+0900	ClusterControlPlaneSecurityGroupIngress			CREATE_COMPLETE	-
	- 2020-04-13 15:10:56 UTC+0900	NodeSecurityGroupIngress						CREATE_COMPLETE	-
	- 2020-04-13 15:10:56 UTC+0900	NodeSecurityGroupFromControlPlaneIngress		CREATE_COMPLETE	-
	- 2020-04-13 15:10:54 UTC+0900	NodeSecurityGroup								CREATE_COMPLETE	-
	- .....
	- 2020-04-13 15:10:45 UTC+0900	EKS-NODEGROUP-1-STACK							CREATE_IN_PROGRESS	User Initiated

5-1. CloudFormation으로 생성한 3개 yaml을 모두 삭제함

	※ 서비스 생성 참조 URL
		- https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
		
5-2. CloudFormation / 수동으로 VPC 1 -> SubNet 3 만듬 ( SubNet은 Private만 )

5. EKS Cluster 생성
	* 참고 - https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/create-cluster.html )
	* 참고 - https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/eksctl.html
	* 참고 - https://github.com/weaveworks/eksctl
	* 참고 - https://eksctl.io/introduction/getting-started/
	* 참고 - https://github.com/weaveworks/eksctl/tree/master/examples	 ( 매우매우 유용함 ★★★★★★★★★★ )

	==> "nodeGroups" 로 구성한 un-managed nodegroup은 AWS -> EKS NodeGroup 에서 볼수 있음
	     eksctl get nodegroup 으로도 보임
	
	==> "ManagedNodegropu" 으로는 구성불가함
			"[✖]  unexpected status "DELETE_FAILED" while waiting for CloudFormation stack "eksctl-ffp-cluster-type2-nodegroup-ffp-unmanaged-ng-worker"
			오류가 나는데 왜 나는지 알수가 없음
			- EKS -> NodeGroup에서 수동으로 생성해봐도 오류남
			
			
	==> ffp-test-cluster.yaml 파일로 EKS Cluster 생성시 필요한 정보
		- VPC : AZ 별로 1개씩 만들어서 yaml 파일에서 subnets 에 지정해서 사용하면 될것 같음
		- CSI : Storage는 EFS / EBS 중에 뭐 쓸지 결정해서 미리 생성해야함
		- CLOUDWATCH : 미리 만들어놔야 하는건가??
		- ALB : 미리 생성안해도 되긴 하는건가??
		- Role : 이것도 따로 필요 없는거 같은데?
		
		
		
	# date; eksctl create cluster -f ffp-test-cluster-test1.yaml
	# date; eksctl update cluster -f ffp-test-cluster-test2.yaml   # AZ 2b로 subnet 1개 추가한 파일
	  ==> Subnet 은 eksctl update로 추가가되지 않음. cluster를 지우고 처음부터 다시 만들어야됨. ( 처음부터 잘하자. AZ 3개 다 쓰는걸로 )
	  ==> Subnet 은 동적추가가 되지 않으므로, cidr 설정에 주의해야함                          ( 테스트시에는 */26 이라서 사용가능한 IP가 59개 뿐임 )
	  ==> Subnet 을 동적추가하려면 아래 처럼 command를 따로 써야함 ( yaml 로 안됨 )
	      # eksctl update cluster --vpc-private-subnets=
	
	# aws eks describe-cluster --name ffp-test-cluster | jq .
	
	# eksctl get cluster
	# 


###############################################################################################################################################################################
# 중단 버전
# - 김상경 수석님. CloudFormation 대로 3개 생성하고
# - EKS Cluster 에서 NodeGroup 생성하려고 하면 생성할 수 없음 ( Node IAM Role 지정 불가 )
# - EC2 인스턴스를 개별적으로 생성해서 EKS Cluster에 붙이면 될거 같은데... UI로 수작업하는거라서 운영 맞지 않음 ( 중단 )
###############################################################################################################################################################################
5. EKS Cluster 생성

	[ EKS-IAM-ROLE - EKS용 IAM 생성 ]
	# AWS -> IAM -> ROLE -> Create Role ( 아래 2개 선택 )
		- AmazonEKSClusterPolicy
		- AmazonEKSServicePolicy
	
	[ EKS-CLUSTER 생성 ]	
	# AWS -> EKS -> Create Cluster
		- CLUSTER	: FFP-CLUSTER
		- IAM		: EKS-IAM-ROLE ( 위에서 생성한 )
	
	[ kubectl 환경 설정 ]
	# aws eks update-kubeconfig --name FFP-CLUSTER --region ap-northeast-2
	  또는 수동으로 /root/.kube/kubeconfig 생성 ( https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html ) 
	  
	# cat /root/.kube/config
	
	# kc get svc --show-labels
		NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE   LABELS
		kubernetes   ClusterIP   172.20.0.1   <none>        443/TCP   12m   component=apiserver,provider=kubernetes
		
	# kc get node
		No resources found in default namespace.


	
5. EKS NodeGroup 생성 ( Managed NodeGroup으로 생성함 )
	※ Managed NodeGroup과 Un-managed NodeGroup의 차이
		=> https://aws.amazon.com/blogs/containers/eks-managed-node-groups/
		   * Managed NodeGroup은 AMI를 지정안함 ( EKS에 표준 AMI를 자동으로 사용하므로 AMI 를 유지관리할 필요가 없음 )

	# AWS -> EKS -> NodeGroup Add
		- NAME				: Managed-ng-1
		- IAM Role			: EKS-NODEGROUP-ROLE
		- Security Groups	: EKS-NODEGROUP-STACK-NodeSecurityGroup-###
		- MinSize			: 3
		- MaxSize			: 6
		- DesiredSize		: 3
		
		==> NodeGroup 생성시 "Node I-AM Role" 선택하는데서 아무 Role도 list-up 되지 않음
		    ( IAM에서 이것 저것 생성해봤으나.... 아무것도 안보임 )
			

		
		
#########################
	  








	
	
	
	
	

