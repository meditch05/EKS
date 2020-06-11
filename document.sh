############################################################################################################################################################
# [ Bastion 서버 생성 ]
############################################################################################################################################################

1. Bastion 서버 생성 / 환경구성

	- AMI					: Amazon EKS-Optimized Amazon Linux AMI ( Docker / kubectl 기본설치되어있음. 다른거 쓰고 깔아도됨 )
	- InstanceSize			: t3a.micro
	- Subnet				: service-nat-public-p-subnet1 ( 기존 VPC 있는 PublicSubnet 아무대나 생성 )
	- Auto-assign Public IP	: Enable
	- Key Pair				: meditch05.pem
	
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
	0.21.0
	
	=====================================
	[ Bastion 서버 구성 - kubectl 구성 ]
	=====================================	
	# kubectl_ver=`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`
	# echo $kubectl_ver
	# curl -LO https://storage.googleapis.com/kubernetes-release/release/${kubectl_ver}/bin/linux/amd64/kubectl
	# chmod +x ./kubectl
	# sudo mv  ./kubectl /usr/local/bin/kubectl
	# kubectl version --client
	1.18.3
	
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


5. EKS CLUSTER 생성 ( eksctl 사용. 0.20.0 부터는 managednodegreoup 생성시에 Error가 나니 Cluster / NodeGroup을 나눠서 만든다. )

	[ EKS Optimized AMI 확인 - managedNodeGroups 사용하면 필요 없음 ]
	# aws ssm get-parameter --name /aws/service/eks/optimized-ami/1.16/amazon-linux-2/recommended/image_id --region ap-northeast-2 --query "Parameter.Value" --output text
	ami-0b18567e6d3b05548   # 2020-06-09

	# cd EKS/cluster
	
	[ Cluster 생성 ]
	# date; eksctl create cluster --config-file=00.ap-northeast-2.eks-skcc05599.create-cluster.yaml ; date
	
	[ NodeGreoup 생성 ]
	# date; eksctl create nodegroup --config-file=03.ap-northeast-2.eks-skcc05599-1devops-2worker.managed.yaml ; date
	
	# aws eks describe-cluster --name skcc05599 | jq '.cluster |.name, .endpoint, .resourcesVpcConfig'
	
	
6. Node별 Label 추가
	# Node에 Label 추가 ( Cluster.yaml에 label 추가해서 생성하면 오류나니 수동으로 label 추가 )
	# kubectl get node -L role,ec2-type
	# DEVS_NODE=$(kc get nodes -L role | grep devops | grep none | awk '{print $1}')
	# WRKS_NODE=$(kc get nodes -L role | grep worker | grep none | awk '{print $1}')
	
	# for NODE in $DEVS_NODE
	  do
		kubectl label nodes ${NODE} node-role.kubernetes.io/devops=true
	  done
	
	# for NODE in $WRKS_NODE
	  do
		kubectl label nodes ${NODE} node-role.kubernetes.io/worker=true
	  done
	
	
7. EC2 TYPE별 POD 갯수
	
	[ EKS 의 POD 갯수 제한 ]
	=> https://medium.com/faun/aws-eks-and-pods-sizing-per-node-considerations-964b08dcfad3 )
		* Max Pods = Maximum supported  Network Interfaces for instance type ) * ( IPv4 Addresses per Interface ) - 1

	=> https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html
		* t3a.micro  = IPv4 addresses per interface 2 => 3 * 2 - 1 = 5
		* t3a.small  = IPv4 addresses per interface 4 => 3 * 4 - 1 = 11
		* t3a.medium = IPv4 addresses per interface 6 => 3 * 6 - 1 = 17
		
		
	VS
	
	[ ECS 의 POD 갯수 제한 ]
	=> https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html

8. Node별 POD 갯수 확인
   => Dual CIDR을 안쓰면 EC2에 Network Interface가 Main CIDR에만 할당됨
   => Dual CIDR을   쓰면 EC2에 Network Interface중에 1개가 Sub CIDR에 할당되서 1개가 빠지는거와 마찮가지임. ( 확인해봐라 )
   => Dual CIDR을   써도 aws-node-#### kube-proxy-### 은 Main CIDR로 생성된다.

	######################################################
	[ Dual CIDR 적용시 ]
	=> t3a.small에서 Running 가능한 POD는 11개 지만, 실제 Running 가능한건 5개 ( 왜??? )
	=> t3a.medium 에서 Running 가능한 POD는 17개이고, 실제 Running 가능한것도 OO개 ( 다시 확인해봐라 )
	=> 나머지 POD는 'ContainerCreating' 에서 Stuck 걸림
	######################################################
	# kc get node -L ec2-type
	NAME                                              STATUS   ROLES    AGE    VERSION              EC2-TYPE
	ip-10-5-115-27.ap-northeast-2.compute.internal    Ready    worker   110m   v1.16.8-eks-e16311   t3a.small
	ip-10-5-120-232.ap-northeast-2.compute.internal   Ready    devops   110m   v1.16.8-eks-e16311   t3a.medium
	ip-10-5-188-123.ap-northeast-2.compute.internal   Ready    worker   110m   v1.16.8-eks-e16311   t3a.small	

	# kc get pod --all-namespaces -o wide | grep Running | awk '{print $8}' | sort | uniq -c
      5 ip-10-5-115-27.ap-northeast-2.compute.internal
      3 ip-10-5-120-232.ap-northeast-2.compute.internal
      5 ip-10-5-188-123.ap-northeast-2.compute.internal

	# kc get pod --all-namespaces -o wide | grep ContainerCreating | awk '{print $8}' | sort | uniq -c
      1 ip-10-5-115-27.ap-northeast-2.compute.internal
      1 ip-10-5-188-123.ap-northeast-2.compute.internal
	  
	# kc get pod --all-namespaces -o wide | awk '{print $8}' | grep -v NODE | sort | uniq -c
      6 ip-10-5-115-27.ap-northeast-2.compute.internal
      3 ip-10-5-120-232.ap-northeast-2.compute.internal
      6 ip-10-5-188-123.ap-northeast-2.compute.internal
	  
	# kc describe pod/busybox-ecr1-75648f4945-49sdq -n infra | tail -1   # ( 로그 확인해보면 CNI에서 IP 할당 실패로 ContainerCreating 상태임 )
	Warning  FailedCreatePodSandBox  4m47s (x271 over 9m38s)  kubelet, ip-10-5-115-27.ap-northeast-2.compute.internal  (combined from similar events): Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "7acdc447cb5f77399ecf21089f2d46501fe9bdf0aa9288a71800c3a4a500a13b" network for pod "busybox-ecr1-75648f4945-49sdq": networkPlugin cni failed to set up pod "busybox-ecr1-75648f4945-49sdq_infra" network: add cmd: failed to assign an IP address to container

	######################################################
	[ Dual CIDR 미 적용시 ]
	=> t3a.small  에서 Running 가능한 POD는 11개 지만, 실제 Running 가능한건 8개
	=> t3a.medium 에서 Running 가능한 POD는 17개이고, 실제 Running 가능한것도 17개
	=> 나머지 POD는 'Pending' 에서 Stuck 걸림
	######################################################
	# kc get node -L ec2-type
	NAME                                               STATUS   ROLES    AGE     VERSION              EC2-TYPE
	ip-10-50-120-135.ap-northeast-2.compute.internal   Ready    worker   7m9s    v1.16.8-eks-e16311   t3a.small
	ip-10-50-142-29.ap-northeast-2.compute.internal    Ready    devops   6m56s   v1.16.8-eks-e16311   t3a.medium
	ip-10-50-158-107.ap-northeast-2.compute.internal   Ready    worker   7m15s   v1.16.8-eks-e16311   t3a.small
	
	# kc get pod --all-namespaces -o wide | awk '{print $8}' | grep -v NODE | sort | uniq -c
      8 ip-10-50-120-135.ap-northeast-2.compute.internal
     17 ip-10-50-142-29.ap-northeast-2.compute.internal
      8 ip-10-50-158-107.ap-northeast-2.compute.internal

	# kc get pod --all-namespaces -o wide | grep Running | awk '{print $8}' | sort | uniq -c
      8 ip-10-50-120-135.ap-northeast-2.compute.internal
     17 ip-10-50-142-29.ap-northeast-2.compute.internal
      8 ip-10-50-158-107.ap-northeast-2.compute.internal
	  
	# kc get pod -o wide --all-namespaces | grep "ip-10-50-142-29.ap-northeast-2.compute.internal" | grep Running | wc -l
	17
	  
	# kc get pod --all-namespaces -o wide | grep -v Running | awk '{print $8}' | sort | uniq -c
	0

	
	[ Pending 이었던 POD describe 를 보면 ]
	# kc describe pod/busybox-ecr1-75648f4945-2p84j -n infra | tail -1   # ( 로그 확인해보면 POD수 제한으로 Pending 상태임 )
	Warning  FailedScheduling  10s (x32 over 45m)  default-scheduler  0/3 nodes are available: 1 node(s) didn't match node selector, 2 Insufficient pods.


	######################################################
	[ Dual CIDR 미 적용시 => 적용하고, nodeGroup 다시 만들었을때 ]
	=> t3a.small  에서 Running 가능한 POD는 11개 지만, 실제 Running 가능한건 5개  ( -3 )  => 100.64.0.0/16 대역으로 Secondary IP가  3개 생성되고, eth1  에 3개가 할당됨
	=> t3a.medium 에서 Running 가능한 POD는 17개 지만, 실제 Running 가능한건 12개 ( -5 )  => 100.64.0.0/16 대역으로 Secondary IP가 10개 생성되고, eth1/2에 5개씩 할당됨
	=> 나머지 POD는 'Pending' 에서 Stuck 걸림
	######################################################
	# kc get node -L ec2-type
	NAME                                              STATUS   ROLES    AGE     VERSION              EC2-TYPE
	ip-10-50-123-94.ap-northeast-2.compute.internal   Ready    devops   6m2s    v1.16.8-eks-e16311   t3a.medium
	ip-10-50-132-2.ap-northeast-2.compute.internal    Ready    worker   5m48s   v1.16.8-eks-e16311   t3a.small
	ip-10-50-97-145.ap-northeast-2.compute.internal   Ready    worker   6m16s   v1.16.8-eks-e16311   t3a.small
	
	# kc get pod --all-namespaces -o wide | awk '{print $8}' | grep -v NODE | sort | uniq -c
     17 ip-10-50-123-94.ap-northeast-2.compute.internal
      8 ip-10-50-132-2.ap-northeast-2.compute.internal
      8 ip-10-50-97-145.ap-northeast-2.compute.internal

	# kc get pod --all-namespaces -o wide | grep Running | awk '{print $8}'  | sort | uniq -c
     12 ip-10-50-123-94.ap-northeast-2.compute.internal
      2 ip-10-50-132-2.ap-northeast-2.compute.internal     # ( Network interface가 eth0 1개만 붙어있고, Secondary Private IPs가 비어있음. ENIConfig.yaml 에서 Subnet을 잘못 지정했음 )
      5 ip-10-50-97-145.ap-northeast-2.compute.internal
	  
	# kc get pod --all-namespaces -o wide | grep Running | awk '{print $8}'  | sort | uniq -c
     12 ip-10-50-123-94.ap-northeast-2.compute.internal
      5 ip-10-50-132-2.ap-northeast-2.compute.internal
      5 ip-10-50-97-145.ap-northeast-2.compute.internal
	
	# kc get pod --all-namespaces -o wide | grep -v Running | awk '{print $8}' | sort | uniq -c
	

	
	
	
	
	
############################################################################################################
# HELM 3 설치
############################################################################################################

1. HELM3 설치
	# curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
	# sudo chmod 700 get_helm.sh
	# sudo ./get_helm.sh
	# helm version
	
	# helm repo add stable https://kubernetes-charts.storage.googleapis.com/
	# helm search repo stable
	# helm repo update

############################################################################################################
# nginx-ingress 설치
############################################################################################################
1. nginx-ingress 설치
	# helm search repo stable/nginx-ingress
	# mkdir charts
	# cd charts
	# helm fetch stable/nginx-ingress
	# tar -zxvf nginx-ingress*.tgz
	# cp nginx-ingress/values.yaml  nginx-ingress/values.yaml.edit
	# diff values.yaml values.yaml.edit
	134c134
	<   kind: Deployment
	---
	>   kind: DaemonSet
	164c164
	<   affinity: {}
	---
	>   affinity:
	196c196,197
	<   nodeSelector: {}
	---
	>   nodeSelector:
	>     role: worker
	247c248
	<     annotations: {}
	---
>     annotations: {service.beta.kubernetes.io/aws-load-balancer-type: nlb}

	
	# kubectl create ns infra	
	# cd nginx-ingress
	# helm install nginx-ingress --namespace infra -f values.yaml.edit stable/nginx-ingress
	
	# helm list -n infra
	
			# helm uninstall nginx-ingress -n infra

2. 생성 확인
	# kc get svc,pod -n infra
	NAME                                    TYPE           CLUSTER-IP      EXTERNAL-IP                                                                          PORT(S)                      AGE
	service/nginx-ingress-controller        LoadBalancer   172.20.203.54   ab29712e0d4ba4bcc916fb6f4c935379-a3da055390627c00.elb.ap-northeast-2.amazonaws.com   80:30692/TCP,443:30567/TCP   21m
	service/nginx-ingress-default-backend   ClusterIP      172.20.89.80    <none>                                                                               80/TCP                       21m
	NAME                                                   READY   STATUS    RESTARTS   AGE
	pod/nginx-ingress-controller-5569c                     1/1     Running   0          10m
	pod/nginx-ingress-controller-nv2l2                     1/1     Running   0          21m
	pod/nginx-ingress-default-backend-5b967cf596-wzhc9     1/1     Running   0          5m5s


3. Worker Node에만 POD들이 생성되도록 Chart Update
	# diff values.yaml values.yaml.edit
	134c134
	<   kind: Deployment
	---
	>   kind: DaemonSet
	164c164
	<   affinity: {}
	---
	>   affinity:
	196c196,197
	<   nodeSelector: {}
	---
	>   nodeSelector:
	>     role: worker
	247c248
	<     annotations: {}
	---
	>     annotations: {service.beta.kubernetes.io/aws-load-balancer-type: nlb}
	507c508,509
	<   nodeSelector: {}
	---
	>   nodeSelector:
	>     role: worker

	# helm upgrade nginx-ingress --namespace infra -f values.yaml.edit stable/nginx-ingress
	
	# kc get pod -n infra -o wide
	NAME                                             READY   STATUS    RESTARTS   AGE     IP              NODE                                              NOMINATED NODE   READINESS GATES
	busybox-deployment-ecr1-75bdbb5ffd-5bh5b         1/1     Running   0          4m40s   10.5.0.75     ip-10-5-188-123.ap-northeast-2.compute.internal   <none>           <none>
	busybox-deployment-ecr1-75bdbb5ffd-6hl2k         1/1     Running   0          4m42s   10.5.66.222   ip-10-5-115-27.ap-northeast-2.compute.internal    <none>           <none>
	nginx-ingress-controller-pvh97                   1/1     Running   0          20m     10.5.6.184    ip-10-5-188-123.ap-northeast-2.compute.internal   <none>           <none>
	nginx-ingress-controller-zg85b                   1/1     Running   0          20m     10.5.71.32    ip-10-5-115-27.ap-northeast-2.compute.internal    <none>           <none>
	nginx-ingress-default-backend-6d7985b7ff-5kdvc   1/1     Running   0          60s     10.5.88.111   ip-10-5-115-27.ap-northeast-2.compute.internal    <none>           <none>

	
############################################################################################################################################################
# [ Dual CIDR 사용 EKS 생성 ]
# https://aws.amazon.com/ko/premiumsupport/knowledge-center/eks-multiple-cidr-ranges/
############################################################################################################################################################

1. EKS Cluster 명 확인
	# export EKS_CLUSTER_NAME=meditch05

2. EKS가 사용하는 VPC_ID 확인
	# export VPC_ID=$(eksctl utils describe-stacks --region=ap-northeast-2 --cluster=${EKS_CLUSTER_NAME} | grep OutputValue | grep vpc | cut -d"\"" -f2)	
	
3. VPC에 Sub-CIDR 추가 ( 100.64.0.0/16 => VPC 네트워크를 확장 )
	# aws ec2 associate-vpc-cidr-block --vpc-id $VPC_ID --cidr-block 100.64.0.0/16
	
4. AZ별 Sub-CIDR 용 Subnet 생성
	# export AZ1=ap-northeast-2a
	# export AZ2=ap-northeast-2b
	# export AZ3=ap-northeast-2c
	
	# export CUST_SNET1=$(aws ec2 create-subnet --cidr-block 100.64.0.0/19  --vpc-id $VPC_ID --availability-zone $AZ1 | jq -r .Subnet.SubnetId)
	# export CUST_SNET2=$(aws ec2 create-subnet --cidr-block 100.64.32.0/19 --vpc-id $VPC_ID --availability-zone $AZ2 | jq -r .Subnet.SubnetId)
	# export CUST_SNET3=$(aws ec2 create-subnet --cidr-block 100.64.64.0/19 --vpc-id $VPC_ID --availability-zone $AZ3 | jq -r .Subnet.SubnetId)
	
	# echo CUST_SNET1
	# echo CUST_SNET2
	# echo CUST_SNET3

5. 새로 생성한 서브넷에 태그 지정 ( EKS가 서브넷을 검색할 수 있도록 태그를 지정 )
	# aws ec2 create-tags --resources $CUST_SNET1 --tags Key=Name,Value=SubnetA
	# aws ec2 create-tags --resources $CUST_SNET2 --tags Key=Name,Value=SubnetB
	# aws ec2 create-tags --resources $CUST_SNET3 --tags Key=Name,Value=SubnetC

	# aws ec2 create-tags --resources $CUST_SNET1 --tags Key=kubernetes.io/cluster/${EKS_CLUSTER_NAME},Value=shared
	# aws ec2 create-tags --resources $CUST_SNET2 --tags Key=kubernetes.io/cluster/${EKS_CLUSTER_NAME},Value=shared
	# aws ec2 create-tags --resources $CUST_SNET3 --tags Key=kubernetes.io/cluster/${EKS_CLUSTER_NAME},Value=shared
	
6. Sub-CIDR 용 Subnet 을 VPC의 AZ별 라우팅 테이블에 연결
	# aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC_ID | jq -r '.RouteTables[].RouteTableId'
	
	※ IAM 으로 여러명이 사용하면 어떤게 내껀지 구별하기 어려움. rtb ID가 안보이면 웹콘솔가서 따로 확인을 하자
	eksctl-skcc05599-cluster/PrivateRouteTableAPNORTHEAST2A => rtb-0916ebb8934a4ab9e
	eksctl-skcc05599-cluster/PrivateRouteTableAPNORTHEAST2B => rtb-03fcb781f4f5713d9
	eksctl-skcc05599-cluster/PrivateRouteTableAPNORTHEAST2C => rtb-033102996bad6734d

	# export RTASSOC_ID1=rtb-0916ebb8934a4ab9e
	# export RTASSOC_ID2=rtb-03fcb781f4f5713d9
	# export RTASSOC_ID3=rtb-033102996bad6734d

	# aws ec2 associate-route-table --route-table-id $RTASSOC_ID1 --subnet-id $CUST_SNET1
	# aws ec2 associate-route-table --route-table-id $RTASSOC_ID2 --subnet-id $CUST_SNET2
	# aws ec2 associate-route-table --route-table-id $RTASSOC_ID3 --subnet-id $CUST_SNET3
	
7. Sub-CIDR 을 사용하도록 EKS에 CNI 플러그인 구성 ( 신규생성한 EKS는 1.6.2 이므로 안해도됨 )
	[ CNI 플러그인 확인 / 필요시 Upgrade ]
	# kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2
	# kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/master/config/v1.5/aws-k8s-cni.yaml

8. CNI 플러그인에 대한 사용자 지정 네트워크 구성 활성화
	# kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true

9. Worker 노드를 식별하기 위한 ENIConfig 레이블을 추가하려면 다음 명령을 실행  ( 이해가 안되요... ;ㅅ; )
	# kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=failure-domain.beta.kubernetes.io/zone


10. ENIConfig CRD 구성 

	# vi ENIConfig.CRD.yaml
	apiVersion: apiextensions.k8s.io/v1beta1
	kind: CustomResourceDefinition
	metadata:
	name: eniconfigs.crd.k8s.amazonaws.com
	spec:
	scope: Cluster
	group: crd.k8s.amazonaws.com
	version: v1alpha1
	names:
		plural: eniconfigs
		singular: eniconfig
		kind: ENIConfig
	
	# kubectl apply -f ENIConfig.CRD.yaml


11. 모든 서브넷 및 AZ에 대해 ENIConfig CRD 생성

	# vi ENIConfig.AZs.yaml
	---
	apiVersion: crd.k8s.amazonaws.com/v1alpha1
	kind: ENIConfig
	metadata:
	name: $AZ1
	spec:
	subnet: $CUST_SNET1 
	---
	apiVersion: crd.k8s.amazonaws.com/v1alpha1
	kind: ENIConfig
	metadata:
	name: $AZ2
	spec:
	subnet: $CUST_SNET2
	---
	apiVersion: crd.k8s.amazonaws.com/v1alpha1
	kind: ENIConfig
	metadata:
	name: $AZ3
	spec:
	subnet: $CUST_SNET3
	---	
	
	# kubectl apply -f ENIConfig.AZs.yaml
	
12. Worker NodeGroup 재생성 ( 새 NodeGroup 에서만 Dual-CIDR 가 적용된다 )

	  
13. nginx-ingress 호출 테스트 ( 안될껄 )
	# curl http://ab29712e0d4ba4bcc916fb6f4c935379-a3da055390627c00.elb.ap-northeast-2.amazonaws.com/asdlkjfskajdf

14. EKS의 보안그룹 ( ControlPlaneSecurityGroup ) 수정  => Sub-CIDR 에 생성되는 POD들과 EKS ControlPlane 대역(172.x.x.x)과 통신이 되지 않는 현상 조치

	[ Un-managed NodeGroup 일 경우 ]
	# 웹콘솔 => VPC => 보안 => Security Group => "클러스터명이 들어간 모든 Security Group" => 인바운드 규칙에 100.64.0.0/16 대역을 추가
	- 유형		: 모든 Traffic
	- 프로토콜	: ALL
	- 포트범위	: ALL
	- 소스		: 사용자지정 ( 100.64.0.0/16 )
	- 설명		: POD network TO ControlPlane network
	
	※ 2개 unmanaged node group 을 생성하면 아래 처럼 총 5개의 Security Group 이 보임 ( 5개 모두에 Inbound rule 추가 )
	# eksctl-skcc05599-nodegroup-devops-new/SG					sg-0443e5afda7c0c622	...
	# eks-cluster-sg-skcc05599-647076920						sg-0592750418c54c4a3	...
	# eksctl-skcc05599-nodegroup-worker-new/SG					sg-07982106e46d7d52b	...
	# eksctl-skcc05599-cluster/ClusterSharedNodeSecurityGroup	sg-08040113e12d6d1bb	...
	# eksctl-skcc05599-cluster/ControlPlaneSecurityGroup		sg-0dd182c2553e9d341	...
	
	[ managed NodeGroup 일 경우 ]
	
	※ 2개 managed node group 을 생성하면 아래 처럼 총 3개의 Security Group 이 보임 ( 3개 모두에 Inbound rule 추가 )
	eks-cluster-sg-skcc05599-647076920						sg-0592750418c54c4a3	...
	eksctl-skcc05599-cluster/ClusterSharedNodeSecurityGroup	sg-08040113e12d6d1bb	...   # 여기서 빼면 CNI 사용을 못해서 POD가 "ContainerCreating" 상태에서 멈춰버림
	eksctl-skcc05599-cluster/ControlPlaneSecurityGroup		sg-0dd182c2553e9d341	...
	
15. Node에 Label 추가 ( Cluster.yaml에 label 추가해서 생성하면 오류나니 수동으로 label 추가 )
	# kubectl get node -L role,ec2-type
	# DEVS_NODE=$(kc get nodes -L role | grep devops | grep none | awk '{print $1}')
	# WRKS_NODE=$(kc get nodes -L role | grep worker | grep none | awk '{print $1}')
	
	# for NODE in $DEVS_NODE
	  do
		kubectl label nodes ${NODE} node-role.kubernetes.io/devops=true
	  done
	
	# for NODE in $WRKS_NODE
	  do
		kubectl label nodes ${NODE} node-role.kubernetes.io/worker=true
	  done
	
	

############################################################################################################
# EKS nodeGroup 변경 ( unmanaged nodegroup 이고, AMI만 kubelet 1.16.8 용으로 변경 )
# => https://eksctl.io/usage/faq/
# => nodegroup은 immutable 이고 scale up/down 만 가능함. 새로운 nodegreoup을 만들고, 예전껄 지워야함
############################################################################################################

1. 기존 nodegroup 확인 ( AMI가 kubenetes 1.15 용이므로 1.16 용으로 변경하자 )
	# eksctl get  nodegroup --cluster skcc05599
	CLUSTER         NODEGROUP       CREATED                 MIN SIZE        MAX SIZE        DESIRED CAPACITY        INSTANCE TYPE   IMAGE ID
	skcc05599       devops          2020-06-09T00:59:23Z    1               2               1                       t3a.medium      ami-08a18de5609e8f781
	skcc05599       worker          2020-06-09T00:59:23Z    2               3               2                       t3a.small       ami-08a18de5609e8f781


2. 새로운 nodeGroup 설정파일 확인
	# diff 01.ap-northeast-2.eks-skcc05599-1devops-2worker.yaml  02.ap-northeast-2.eks-skcc05599-1devops-2worker.ami.chg.yaml
	15c15
	<   - name: devops
	---
	>   - name: devops-new
	24c24
	<     ami: ami-08a18de5609e8f781 # only for nodeGroups( Unmanaged nodegroup )
	---
	>     ami: ami-0b18567e6d3b05548 # only for nodeGroups( Unmanaged nodegroup )
	39c39
	<   - name: worker
	---
	>   - name: worker-new
	48c48
	<     ami: ami-08a18de5609e8f781 # only for nodeGroups( Unmanaged nodegroup )
	---
	>     ami: ami-0b18567e6d3b05548 # only for nodeGroups( Unmanaged nodegroup )

3. 새로운 nodegroup 용으로 clusterconfig 파일 변경 / nodegroup 생성
	# eksctl create nodegroup --config-file=02.ap-northeast-2.eks-skcc05599-1devops-2worker.unmanaged.ami.chg.yaml
 
	[ 새로운 nodegroup, POD 생성 확인 ] => 새로운 Node에 생성된 POD는 Dual CIDR을 사용하게됨
	# eksctl get nodegroup --cluster skcc05599
	CLUSTER         NODEGROUP       CREATED                 MIN SIZE        MAX SIZE        DESIRED CAPACITY        INSTANCE TYPE   IMAGE ID
	skcc05599       devops          2020-06-09T00:59:23Z    1               2               1                       t3a.medium      ami-08a18de5609e8f781
	skcc05599       devops-new      2020-06-09T02:02:29Z    1               2               1                       t3a.medium      ami-0b18567e6d3b05548
	skcc05599       worker          2020-06-09T00:59:23Z    2               3               2                       t3a.small       ami-08a18de5609e8f781
	skcc05599       worker-new      2020-06-09T02:02:29Z    2               3               2                       t3a.small       ami-0b18567e6d3b05548
	
	#  kc get node; kc get pod -n infra -o wide
	NAME                                              STATUS   ROLES        AGE     VERSION
	ip-10-5-126-161.ap-northeast-2.compute.internal   Ready    worker       2m4s    v1.16.8-eks-e16311
	ip-10-5-173-4.ap-northeast-2.compute.internal     Ready    worker       65m     v1.15.10-eks-bac369
	ip-10-5-182-180.ap-northeast-2.compute.internal   Ready    management   2m38s   v1.16.8-eks-e16311
	ip-10-5-189-242.ap-northeast-2.compute.internal   Ready    management   66m     v1.15.10-eks-bac369
	ip-10-5-191-218.ap-northeast-2.compute.internal   Ready    worker       2m1s    v1.16.8-eks-e16311
	ip-10-5-99-154.ap-northeast-2.compute.internal    Ready    worker       65m     v1.15.10-eks-bac369
	NAME                                             READY   STATUS    RESTARTS   AGE    IP              NODE                                              NOMINATED NODE   READINESS GATES
	nginx-ingress-controller-5569c                   1/1     Running   0          22m    10.5.110.204    ip-10-5-99-154.ap-northeast-2.compute.internal    <none>           <none>
	nginx-ingress-controller-782dq                   1/1     Running   0          65s    100.64.88.122   ip-10-5-126-161.ap-northeast-2.compute.internal   <none>           <none>
	nginx-ingress-controller-9jqn7                   1/1     Running   0          102s   100.64.0.255    ip-10-5-191-218.ap-northeast-2.compute.internal   <none>           <none>
	nginx-ingress-controller-nv2l2                   1/1     Running   0          33m    10.5.180.240    ip-10-5-173-4.ap-northeast-2.compute.internal     <none>           <none>
	nginx-ingress-default-backend-5b967cf596-wzhc9   1/1     Running   0          16m    10.5.167.155    ip-10-5-189-242.ap-northeast-2.compute.internal   <none>           <none>
	
	※ t3a.medium 타입을 사용하는 worker-t3a-medium nodegroup 으로 nginx-ingress POD들이 정상적으로 deploy 되었음
	
4. Node에 Label 추가 ( Cluster.yaml에 label 에 node-role.kubernetes.io/type: "true" 하면 오류남 )
	# kubectl get node -L role,ec2-type
	# DEVS_NODE=$(kc get nodes -L role | grep devops | grep none | awk '{print $1}')
	# WRKS_NODE=$(kc get nodes -L role | grep worker | grep none | awk '{print $1}')
	
	# for NODE in $DEVS_NODE
	  do
		kubectl label nodes ${NODE} node-role.kubernetes.io/devops=true
	  done
	
	# for NODE in $WRKS_NODE
	  do
		kubectl label nodes ${NODE} node-role.kubernetes.io/worker=true
	  done

5. 기존 nodegroup 삭제
	# eksctl delete nodegroup --cluster skcc05599 --name=workers
	# eksctl delete nodegroup --cluster skcc05599 --name=devops
		=> eks에서 cordon 시키고, drain 시킨다는 메시지가 뜨고
		=> Node가 Ready,SchedulingDisabled => NotReady,SchedulingDisabled => 삭제됨
	
	
############################################################################################################
# EKS nodeGroup 변경 ( Managed nodegroup 으로 변경 )
# => https://eksctl.io/usage/faq/
# => nodegroup은 immutable 이고 scale up/down 만 가능함. 새로운 nodegreoup을 만들고, 예전껄 지워야함
############################################################################################################

1. NodeGroup 생성
	# eksctl create nodegroup --config-file=03.ap-northeast-2.eks-skcc05599-1devops-2worker.managed.yaml

	# eksctl get nodegroup --cluster skcc05599
	CLUSTER         NODEGROUP               CREATED                 MIN SIZE        MAX SIZE        DESIRED CAPACITY        INSTANCE TYPE   IMAGE ID
	skcc05599       devops-new-managed      2020-06-09T04:14:41Z    1               2               1                       t3a.medium
	skcc05599       worker-new-managed      2020-06-09T04:14:41Z    2               3               2                       t3a.small
	
2. Node에 Label 추가 ( Cluster.yaml에 label 에 node-role.kubernetes.io/type: "true" 하면 오류남 )
	# kubectl get node -L role,ec2-type
	# DEVS_NODE=$(kc get nodes -L role | grep devops | grep none | awk '{print $1}')
	# WRKS_NODE=$(kc get nodes -L role | grep worker | grep none | awk '{print $1}')
	
	# for NODE in $DEVS_NODE
	  do
		kubectl label nodes ${NODE} node-role.kubernetes.io/devops=true
	  done
	
	# for NODE in $WRKS_NODE
	  do
		kubectl label nodes ${NODE} node-role.kubernetes.io/worker=true
	  done
	  
3. 기존 nodegroup 삭제
	# eksctl delete nodegroup --cluster skcc05599 --name=workers-new
	# eksctl delete nodegroup --cluster skcc05599 --name=devops-new
		=> eks에서 cordon 시키고, drain 시킨다는 메시지가 뜨고
		=> Node가 Ready,SchedulingDisabled => NotReady,SchedulingDisabled => 삭제됨
	
############################################################################################################
# 샘플 Appl 구성
############################################################################################################

1. 샘플 Appl 구성
	# cd EKS/cluster/app
	# kc apply -f 01.test.app.yaml
	
2. 구성 확인
	# kc get ing,svc,pod -n test -o wide
	NAME                              HOSTS         ADDRESS                    PORTS   AGE
	ingress.extensions/apple-banana   ffptest.com   10.5.115.27,10.5.188.123   80      147m
	
	NAME                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
	service/apple-service    ClusterIP   172.20.154.71    <none>        5678/TCP   148m
	service/banana-service   ClusterIP   172.20.217.255   <none>        5678/TCP   148m
	
	NAME             READY   STATUS    RESTARTS   AGE
	pod/apple-app    1/1     Running   0          22m
	pod/banana-app   1/1     Running   0          22m
	
	
	# kc get ing,svc,pod -n infra -o wide
	NAME                                    TYPE           CLUSTER-IP      EXTERNAL-IP                                                                          PORT(S)                      AGE     SELECTOR
	service/nginx-ingress-controller        LoadBalancer   172.20.203.54   ab29712e0d4ba4bcc916fb6f4c935379-a3da055390627c00.elb.ap-northeast-2.amazonaws.com   80:30692/TCP,443:30567/TCP   3h16m   app.kubernetes.io/component=controller,app=nginx-ingress,release=nginx-ingress
	service/nginx-ingress-default-backend   ClusterIP      172.20.89.80    <none>                                                                               80/TCP                       3h16m   app.kubernetes.io/component=default-backend,app=nginx-ingress,release=nginx-ingress
	
	NAME                                                 READY   STATUS    RESTARTS   AGE   IP              NODE                                              NOMINATED NODE   READINESS GATES
	pod/busybox-deployment-ecr1-75bdbb5ffd-5bh5b         1/1     Running   0          20m   100.64.0.75     ip-10-5-188-123.ap-northeast-2.compute.internal   <none>           <none>
	pod/busybox-deployment-ecr1-75bdbb5ffd-6hl2k         1/1     Running   0          20m   100.64.66.222   ip-10-5-115-27.ap-northeast-2.compute.internal    <none>           <none>
	pod/nginx-ingress-controller-pvh97                   1/1     Running   0          36m   100.64.6.184    ip-10-5-188-123.ap-northeast-2.compute.internal   <none>           <none>
	pod/nginx-ingress-controller-zg85b                   1/1     Running   0          35m   100.64.71.32    ip-10-5-115-27.ap-northeast-2.compute.internal    <none>           <none>
	pod/nginx-ingress-default-backend-6d7985b7ff-5kdvc   1/1     Running   0          16m   100.64.88.111   ip-10-5-115-27.ap-northeast-2.compute.internal    <none>           <none>


################################################
[ Dual CIDR 사용시 ] => NLB 통해서 Ingress 호출하면 들어간 nginx-controller와 같은 EC2에 POD로는 들어가는데, 다른 EC2로는 못넘어감
################################################
	
3. Ingress 호출 테스트 ( NLB에 할당된 Public IP가 어떨땐 2개고, 어떨땐 3개여 ㅡ_ㅡ;;; )

	# nslookup ab29712e0d4ba4bcc916fb6f4c935379-a3da055390627c00.elb.ap-northeast-2.amazonaws.com
	Address:        10.16.0.2#53
	Address: 52.78.117.206
	Address: 52.79.203.186
	
	# curl -H "Host: ffptest.com" http://52.79.203.186/apple
	<html><header><title>Apple</title></header><body>ffptest.com/apple</body></html>
	
	# curl -H "Host: ffptest.com" http://52.78.117.206/apple
	<html><header><title>Apple</title></header><body>ffptest.com/apple</body></html>
	
	=> NLB 통해서 호출하면 될때 / 안될때가 갈린다.
	
	
4. nginx-ingress 를 지우고 다시 만들어놔야


5. Ingress 호출 테스트
	# nslookup a0f2bb0e1275c4c5aab93c7ec8e9f87c-218b841f9b10b36c.elb.ap-northeast-2.amazonaws.com | grep Address
	Address: 52.78.113.11
	Address: 52.79.68.159
	Address: 13.125.88.199
	
	# curl -H "Host: ffptest.com" http://52.78.113.11/apple
	# curl -H "Host: ffptest.com" http://52.79.68.159/apple
	# curl -H "Host: ffptest.com" http://13.125.88.199/apple


################################################
[ Dual CIDR 미 사용시 ]  => NLB 통해서 Ingress 호출하면 들어간 nginx-controller와 다른 EC2로도 잘 넘어가서 잘 됨
################################################

3. Ingress 호출 테스트 ( NLB에 할당된 Public IP가 어떨땐 2개고, 어떨땐 3개여 ㅡ_ㅡ;;; )
	# nslookup a6ac6cd5746ab4510ab3d2a5a2ced4f2-601267f4a9605765.elb.ap-northeast-2.amazonaws.com | grep Address
	Address:        10.16.0.2#53
	Address: 15.165.128.183
	Address: 15.164.56.232
	
	# curl -H "Host: ffptest.com" http://15.165.128.183/apple
	<html><header><title>Apple</title></header><body>ffptest.com/apple</body></html>
	
	# curl -H "Host: ffptest.com" http://15.164.56.232/apple
	<html><header><title>Apple</title></header><body>ffptest.com/apple</body></html>
	
	
	[ BUSYBOX에서 NGINX SVC를 찔러봐 ]
	# wget http://172.20.30.191/apple
	
	

################################################
[ Dual CIDR 미 사용시 => 사용시 ]  => NLB 통해서 들어가면 어디선가 막힌다.  
################################################

3. Ingress 호출 테스트 ( NLB에 할당된 Public IP가 어떨땐 2개고, 어떨땐 3개여 ㅡ_ㅡ;;; )
	# nslookup a6ac6cd5746ab4510ab3d2a5a2ced4f2-601267f4a9605765.elb.ap-northeast-2.amazonaws.com | grep Address
	Address:        10.16.0.2#53
	Address: 15.165.128.183
	
	# curl -H "Host: ffptest.com" http://15.165.128.183/apple
	<html><header><title>Apple</title></header><body>ffptest.com/apple</body></html>


	=> NLB 통해서 호출하면 될때 / 안될때가 갈린다.
	=> NLB 관련해서 뭔가 있는거 같은데... 
	
	[ TEST ]
	# busybox					에서 app pod 호출 ( OK )
	=> wget                              http://100.64.73.152:5678/apple; cat apple ; rm -rf apple
	=> wget                              http://100.64.2.81:5678/banana ; cat banana; rm -rf banana
	
	# busybox					에서 app svc 호출 ( OK )
	=> wget                              http://172.20.99.81:5678/apple  ; cat apple ; rm -rf apple
	=> wget                              http://172.20.91.45:5678/banana ; cat banana; rm -rf banana
	
	# busybox					에서 nginx-ingress-controller svc 호출 ( OK )
	=> wget --header 'Host: ffptest.com' http://172.20.30.191/apple ; cat apple ; rm -rf apple
	=> wget --header 'Host: ffptest.com' http://172.20.30.191/banana; cat banana; rm -rf banana
	
	
	# nginx-ingress-controller 2개 POD 에서 appl pod 호출 ( OK )
	=> wget                              http://100.64.73.152:5678/apple; rm -rf apple
	=> wget                              http://100.64.2.81:5678/banana ; rm -rf banana
	
	# nginx-ingress-controller 2개 POD 에서 appl svc 호출 ( OK )
	=> wget                              http://172.20.99.81:5678/apple  ; cat apple;  rm -rf apple
	=> wget                              http://172.20.91.45:5678/banana ; cat banana; rm -rf banana
	
	# nginx-ingress-controller	에서 nginx-ingress-controller svc 호출 ( OK )
	=> wget --header 'Host: ffptest.com' http://172.20.30.191/apple ; cat apple ; rm -rf apple
	=> wget --header 'Host: ffptest.com' http://172.20.30.191/banana; cat banana; rm -rf banana
	
	
	
	
	
	
	
	
[ 2020-06-11 ]

################################################
# Dual CIDR + NLB 사용시 ingress 호출시 50% Fail 나는거 F/U ==> 이건 준식이가 F/U 하는걸로
################################################

################################################
# EKS에 GitLab + Jenkins + EFS Provisioner 구성
################################################
[ EFS 볼륨 생성 ]
1. EKS Cluster 의 VPC 를 사용하도록 생성
	=> AZ 3개에 Main CIDR 대역으로 3개의 IP를 사용하게됨
	=> EFS의 DNS Name 확인 : fs-39c6f358.efs.ap-northeast-2.amazonaws.com
   
2. Security Group 변경 ( default로 하면 EFS Provisionner에서 EFS 볼륨 사용못하니, EKS Cluster의 Security Group을 지정해야함. )
	=> sg-05abc447a66a03a33 - eks-cluster-sg-skcc05599-647076920
   
   
[ EFS Provisioner 생성 ]

# helm search repo stable/efs-provisioner
# cd ~/EKS/cluster/HELM3/charts 
# helm fetch  stable/efs-provisioner
# tar -xvf efs-provisioner-0.11.1.tgz
# cd efs-provisioner
# diff values.yaml.edit values.yaml.ori
9c9
<   deployEnv: prd
---
>   deployEnv: dev
38,40c38,40
<   efsFileSystemId: fs-39c6f358
<   awsRegion: ap-northeast-2
<   path: /efs-pv
---
>   efsFileSystemId: fs-12345678
>   awsRegion: us-east-2
>   path: /example-pv
44c44
<     isDefault: true
---
>     isDefault: false
49c49
<     reclaimPolicy: Retain
---
>     reclaimPolicy: Delete
79,80c79
< nodeSelector:
<   role: devops
---
> nodeSelector: {}



# kc create ns infra
# helm install efs-provisioner --namespace infra -f values.yaml.edit stable/efs-provisioner
....
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
	  
[ GitLab 구성 ]

# helm repo add gitlab https://charts.gitlab.io/
# helm repo update
# helm search repo gitlab
# helm fetch gitlab/gitlab
# tar -xvf gitlab*.tgz
# cd gitlab
# vi  storageClass.yaml
  gitaly:
    persistence:
      storageClass: aws-efs
      size: 50Gi
postgresql:
  persistence:
    storageClass: aws-efs
    size: 8Gi
minio:
  persistence:
    storageClass: aws-efs
    size: 10Gi
redis:
  master:
    persistence:
      storageClass: aws-efs
      size: 5Gi
	  
# kubectl create secret generic custom-gitlab-ca -n infra


# diff values.yaml.edit values.yaml.ori
31c31
<   edition: ce
---
>   edition: ee
43c43
<     domain: gitlab.ffptest.com
---
>     domain: example.com
45c45
<     https: false
---
>     https: true
55c55
<     configureCertmanager: false
---
>     configureCertmanager: true
57c57
<     enabled: false
---
>     enabled: true
404c404
<   time_zone: Seoul
---
>   time_zone: UTC
452c452
<   enabled: false
---
>   enabled: true
474c474
<   createCustomResource: false
---
>   createCustomResource: true
478c478
<   install: false
---
>   install: true
490c490
<   enabled: false
---
>   enabled: true
538c538
<   install: false
---
>   install: true
558c558
<   install: false
---
>   install: true
573c573
<   install: false
---
>   install: true
596c596
<   enabled: false
---
>   enabled: true
603c603
<   install: false
---
>   install: true

# helm install gitlab --namespace infra -f values.yaml.edit -f storageClass.yaml gitlab/gitlab

		# helm uninstall gitlab --namespace infra
		# kc get secret -n infra | egrep "^gitlab"               | awk '{print $1}' | xargs kubectl delete -n infra secret
		# kc get cm     -n infra | egrep "^gitlab|^cert-manager" | awk '{print $1}' | xargs kubectl delete -n infra cm 


※ PVC가 필요한 내부 Package
	- Gitaly (persists the Git repositories)
	- PostgreSQL (persists the GitLab database data)
	- Redis (persists GitLab job data)
	- MinIO (persists the object storage data)

################################################
# Pipeline 구성 / App 배포
################################################
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
