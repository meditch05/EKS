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

############################################################################################################################################################
1. EKS Cluster 생성
############################################################################################################################################################

   [ Local VM 또는 Bastion 에서 eksctl 수행 ]

   # eksctl version
   0.31.0
  
   # eksctl create cluster -f 1.create-cluster.1.18.ap-northeast-2.eks-ds05599.yaml
   ## sh 2.create.subcidr.sh 
   # eksctl create nodegroup -f 3.ap-northeast-1.eks-ds05599-2worker.managed.yaml
   # eksctl create nodegroup -f 4.ap-northeast-1.eks-ds05599-1devops.managed.t3a.large.yaml
  
		# Bastion 생성 ( eksctl 생성시에 만들어지는 PublicSubnet 중에 아무거나 1개 선택하거나 기존 VPC 있는 PublicSubnet 아무대나 생성 )
		# Bastion 서버 접속
		# aws eks list-clusters
		# aws eks update-kubeconfig --name skcc05599
			=> ~/.kube/config 생성됨
   
   # kubectl get node
   # kubectl get svc
   # kubectl get ns
   # kubectl get all --all-namespaces
   
   
############################################################################################################################################################
2. Kuberntes Node 별 Labeling ( eks.yaml 에서 Labeling 자동화 하는 방법이 있을거 같은데.. 확인해라 )
############################################################################################################################################################
   # kubectl get node

   # kubectl label nodes ip-100-64-3-248.ap-northeast-1.compute.internal node-role.kubernetes.io/worker=true
   # kubectl label nodes ip-100-64-5-202.ap-northeast-1.compute.internal node-role.kubernetes.io/worker=true
   
   # kubectl label nodes ip-100-64-3-152.ap-northeast-1.compute.internal node-role.kubernetes.io/devops=true
   

############################################################################################################################################################
3. Helm 환경 구성
############################################################################################################################################################
   =====================================
   [ helm 3 설치 ]
   =====================================
   # curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
   # sudo chmod 700 get_helm.sh
   # sudo ./get_helm.sh
   # helm version

   =====================================
   [ helm 3 테스트 ]
   =====================================
   # helm repo add stable        https://charts.helm.sh/stable
   # helm repo add gitlab        https://charts.gitlab.io/
   # helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   # helm repo update

   # helm search repo stable
   # helm search repo stable/nginx-ingress -l | grep 1.41.1
	
   
############################################################################################################################################################
# [ ECR 생성 ] Elastic Container Registry
############################################################################################################################################################
4. AWS ECR 생성
	=====================================
	[ ECR 생성 ]
	=====================================
	AWS -> ECR 
	- Repository name	: nginx / busybox / httpd
	- Tag immutability	: Disabled ( 같은 TAG면 OverWirte 하게끔. 이게 편함, 컨테이너 이미지 TAG 매번 바꾸기도 어렵고, 계속 늘거나기만하고, 지우기도 어려움 )
	- Scan on push		: Disabled ( 컨테이너 이미지 Push 하고나면 자동으로 이미지 push 결과 보여줌, 필요 없음. 필요하면 수동으로 봐 )
	- KMS encryption        : Disabled
	
	==> ECR URI	: 592806604814.dkr.ecr.ap-northeast-1.amazonaws.com
	
	=====================================
	[ ECR 연결 테스트 ]
	=====================================
	---------------------------------
	[ AWSCLI verion 1.18.41 사용시 ]
	---------------------------------
	# aws ecr get-login
	
	docker login -u AWS -p KKKKK -e none https://592806604814.dkr.ecr.ap-northeast-1.amazonaws.com
	
	# export ECR_URL=`   aws ecr describe-repositories | jq -r .repositories[].repositoryUri | cut -d"/" -f1 | uniq`
	# export ECR_PASSWD=`aws ecr get-login | cut -d" " -f6`
	# sudo docker login -u AWS -p ${ECR_PASSWD} ${ECR_URL}
		=> ~/.docker/config.json 이 자동으로 생성된다

	# aws ecr create-repository --repository-name http-echo
	# sudo docker pull hashicorp/http-echo:latest
	# sudo docker tag hashicorp/http-echo:latest ${ECR_URL}/http-echo:latest
	# sudo docker push                           ${ECR_URL}/http-echo:latest
	
	# aws ecr create-repository --repository-name busybox
	# sudo docker pull busybox
	# sudo docker tag docker.io/busybox:latest ${ECR_URL}/busybox:latest
	# sudo docker push                         ${ECR_URL}/busybox:latest
	
	# aws ecr create-repository --repository-name httpd
	# sudo docker pull httpd
	# sudo docker tag docker.io/httpd:latest   ${ECR_URL}/httpd:latest
	# sudo docker push                         ${ECR_URL}/httpd:latest
	
	# sh shl/docker.repo.list.sh
	

############################################################################################################################################################
# [ EKS / ECR 연동 테스트 ]
############################################################################################################################################################
5. k8s Deployment 생성 ( 테스트 ) 
   # cd /home/ec2-user/eks/2.eks.new.VPC.ap-northeast-1/2.task/3.APP
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: busybox
     namespace: infra
     labels:
       app: busybox
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: busybox
     template:
       metadata:
         labels:
           app: busybox
       spec:
         restartPolicy: Always
         containers:
         - name: busybox
           image: 592806604814.dkr.ecr.ap-northeast-1.amazonaws.com/busybox:latest
           imagePullPolicy: Always # IfNotPresent
           command:
             - tail
             - -f
             - /dev/null 

   # kubectl create ns infra
   # kubectl apply -f busybox.yaml	
   # kubectl get pod -n infra
	

############################################################################################################################################################
# Route53 - Domain / ACM - SSL 인증서 생성
############################################################################################################################################################
6. Route53 > Register Domain ( Email Link Check )
   => biz-think.net

7. ACM > Provision certificates > Request a public certificate ( DNS Validation )
   => *.biz-think.net
   # https://musma.github.io/2019/09/16/what-to-do-after-you-buy-your-new-domain-on-aws.html
   # 반드시 ( 미국 동부(us-east-1)  ) 에서 구매해야함
   
   DNS Validation
   ===========================================================================================================================
   Name                                               TYPE    Value
   ===========================================================================================================================
    _acaba30c4a35acd45b2ee2ae4b9e4d97.biz-think.net.  CNAME   _a8731c5b17bf191cdbbb57d0a1773e0c.wggjkglgrm.acm-validations.aws. 

   => "biz-think.net" 버튼을 Clink

8. Route53 > HostedZone > biz-think.net
   => _acaba30c4a35acd45b2ee2ae4b9e4d97.biz-think.net 로 CNAME이 등록되어있음

9. ACM > biz-think.net > Status 
   => 35분 정도 기다리면 Status가 변함 ( Pening validation ==> Issued )
   => Issued 상태가 되면 SSL 발급까지 완료된거임.
   => 하단에 ARN 번호를 저장함 ( arn:aws:acm:ap-northeast-1:592806604814:certificate/2f72d9ad-f6cf-430f-a910-7e396bb59e66 )
    

############################################################################################################################################################
# nginx-ingress-controller 생성
############################################################################################################################################################
10. nginx-ingress-controller 설정파일 수정
    # cd /home/ec2-user/eks/2.eks.new.VPC.ap-northeast-1/2.task/2.CHART/1.nginx-ingress-1.41.1
    # vi 3.values.yaml.nginx-ingress-1.41.1.external-acm
      service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:ap-northeast-1:592806604814:certificate/2f72d9ad-f6cf-430f-a910-7e396bb59e66

11. nginx-ingress-controller 생성 ( 외부용 / 내부용 )
    # helm install nginx-ingress-external -n infra -f 3.values.yaml.nginx-ingress-1.41.1.external-acm stable/nginx-ingress --version 1.41.1
    # helm install nginx-ingress-internal -n infra -f 4.values.yaml.nginx-ingress-1.41.1.internal     stable/nginx-ingress --version 1.41.1
    # htlm list -n infra
    
    # kc get svc -n infra | grep external
      nginx-ingress-external-controller        LoadBalancer   10.100.134.227   a9300d7e6bf8445a1837a3ce252904a6-bb46000a4b3ff6ec.elb.ap-northeast-1.amazonaws.com

12. Route53에 External NLB 연결
    => Route53 > Hosted Zone > biz-think.net > Create Record
       - record name            : bff  ( bff.biz-think.net )
       - Value/Route traffic to : Alias to Network LoadBalancer > ap-northeast-1 > a9300d7e6bf8445a1837a3ce252904a6-bb46000a4b3ff6ec.elb.ap-northeast-1.amazonaws.com
       - record type            : A - Routes traffic to an IPv4 ~~
       - Evaluate target health : Yes

13. Sample 배포
    # cd /home/ec2-user/eks/2.eks.new.VPC.ap-northeast-1/2.task/3.APP/01.test.apple_banana
    # kc apply -f 5.1.hello.yaml
    # kc apply -f 5.2.ingress.hello.yaml

14. HTTPS 접속 테스트
    # https://bff.biz-think.net/hello
    # https://bff.biz-think.net/bye
