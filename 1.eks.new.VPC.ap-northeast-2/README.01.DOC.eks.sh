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
   0.21.0
  
   # eksctl create cluster -f 1.create-cluster.1.16.ap-northeast-2.eks-skcc05599.yaml
   # sh 2.create.subcidr.sh 
   # eksctl create nodegroup -f 3.ap-northeast-2.eks-skcc05599-2worker.managed.yaml
   # eksctl create nodegroup -f 4.ap-northeast-2.eks-skcc05599-1devops.managed.t3a.large.yaml
  
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
   
   # kubectl label nodes ip-10-5-119-102.ap-northeast-2.compute.internal node-role.kubernetes.io/worker=true
   # kubectl label nodes ip-10-5-191-251.ap-northeast-2.compute.internal node-role.kubernetes.io/worker=true
   
   # kubectl label nodes ip-10-5-167-97.ap-northeast-2.compute.internal  node-role.kubernetes.io/devops=true
   

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
   # helm repo add stable        https://kubernetes-charts.storage.googleapis.com/
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
5. k8s Deployment 생성
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
	

############################################################################################################################################################
6. EKS 활용 테스트
############################################################################################################################################################
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
			# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=tbiz-atcl.net/O=tbiz-atcl.net"
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
	- host: tbiz-atcl.net
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
	- host: sub.tbiz-atcl.net
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
	- host: www.tbiz-atcl.net
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
	ingress.extensions/nlb-example       tbiz-atcl.net       10.5.101.252,10.5.144.181   80      157m
	ingress.extensions/nlb-example-sub   sub.tbiz-atcl.net   10.5.101.252,10.5.144.181   80      3m16s
	ingress.extensions/nlb-example-www   www.tbiz-atcl.net   10.5.101.252,10.5.144.181   80      3m16s
	
	# kc get svc -n infra
	NAME                                          TYPE           CLUSTER-IP       EXTERNAL-IP                                                                          PORT(S)                      AGE
	ingress-nginx-nginx-ingress-controller        LoadBalancer   172.20.136.226   a822107b5a264463eaa31a707df7b36b-f72f20a7a37688cb.elb.ap-northeast-2.amazonaws.com   80:30425/TCP,443:30470/TCP   16m
	ingress-nginx-nginx-ingress-default-backend   ClusterIP      172.20.29.200    <none>                                                                               80/TCP                       16m
	
	
	* 접속 TEST
	# curl -H "Host: tbiz-atcl.net" http://a822107b5a264463eaa31a707df7b36b-f72f20a7a37688cb.elb.ap-northeast-2.amazonaws.com/banana
	# curl -H "Host: tbiz-atcl.net" http://a822107b5a264463eaa31a707df7b36b-f72f20a7a37688cb.elb.ap-northeast-2.amazonaws.com/apple
	

############################################################################################################################################################
7. Route53 / Domain Regist / Set Hosted Zone ( Add SubDomain of EKS Ingress )
############################################################################################################################################################
	============================================	
	[ Route53 에서 Domain 생성 ]
	※ https://docs.aws.amazon.com/ko_kr/Route53/latest/DeveloperGuide/migrate-dns-domain-in-use.html
	============================================
	
	* AWS -> Route 53 -> Domain registration -> Register Domain -> "tbiz-atcl.net" 생성
	  => Domain Name : tbiz-atcl.net
	  => Type        : Public Hosted Zone ( EKS Cluster의 Public Subnet 선택 )	  

	* AWS -> Route 53 -> Registered Domain -> Domain명 -> Name Servers 에 있는 DNS Server List 와
            * ns-1515.awsdns-61.org
            * ns-1007.awsdns-61.net
            * ns-1974.awsdns-54.co.uk
            * ns-6.awsdns-00.com
	
        * AWS -> Route 53 -> Hosted Zones -> Domain명 -> Hosted zone details 의 Names Server List가 같아야 한다. ( 다르면 별지승ㄹ 다 해도 인터넷망에서 연결 안됨 )

	============================================	
	[ Route53 에서 Hosted Zone 생성 ]  external.tbiz-atcl.net 으로 호출시 NLB로 연결되도록
	※ https://medium.com/@labcloud/aws-route-53-%EC%97%90-%EB%8F%84%EB%A9%94%EC%9D%B8-%EB%93%B1%EB%A1%9D%ED%95%98%EC%97%AC-%EC%82%AC%EC%9A%A9%ED%95%98%EA%B8%B0-e2d9da2e864d
	============================================ 
	* AWS -> Route 53 -> Hosted zone -> Create Hosted Zone -> Create Record Set -> Simple Routing  -> Define simple record
          => Record Name            : external ( external.tbiz-atcl.net 에 대한 설정. Ingress로 등록한 SubDomain은 모두 동일하게 등록해야 NLB로 연결됨 )
	  => Value/Route traffic to : Alias to Network Load Balacer
	  => Choose Region          : Asia Pactific (Seoul) [ap-northeast-2]
	  => Rrcord type            : A - Routes traffic to an IPv4 address and some AWS resources
	
	* PC에 브라우저 열고 http://external.tbiz-atcl.net/apple  페이지 Open
	* PC에 브라우저 열고 http://external.tbiz-atcl.net/banana 페이지 Open
	* 핸드폰에서 브라우저 열고 http://external.tbiz-atcl.net/apple  페이지 Open
	* 핸드폰에서 브라우저 열고 http://external.tbiz-atcl.net/banana 페이지 Open
	  
	  
	============================================
	= 35분 정도면 굴입한 Domain이 Global 하게 등록됨.
	============================================
	
	1. 일단 Route53에서 구매한 Domain의 등록 상태를 확인
	   # AWS -> Route53 -> Registered domains -> "Domain name status code" 확인 ( 도메인 생성한 직후는 "addPeriod" 임 )
	     => https://www.icann.org/resources/pages/epp-status-codes-2014-06-16-en 에서 확인해보면
	        최초 Domain을 등록시에 몇일 걸릴수 있다고함 ( 이때 삭제하면 돈 돌려준데 )
			
			=> "This is an informative status set for the first several days of your domain's registration. There is no issue with your domain name."
			
		    => "This grace period is provided after the initial registration of a domain name.
		        If the registrar deletes the domain name during this period,
				the registry may provide credit to the registrar for the cost of the registration."
				
	   ※ DNS 갱신내용이 전파되는데는 최대 2~3일까지 걸릴수도 있다고 한다. ( 이때까지의 EPP 코드가 "addReriod" 임. ICANN에서 정의한 EPP CODE  )
	      => EPP Code : Extensible Provisioning Protocol
		  => https://www.icann.org/resources/pages/epp-status-codes-2014-06-16-en ( Serveral Days
	      => https://notice.tistory.com/2358
	   

############################################################################################################################################################
8. ACM을 사용한 SSL 인증서 구매 / EKS Ingress 설정
############################################################################################################################################################
	# https://musma.github.io/2019/09/16/what-to-do-after-you-buy-your-new-domain-on-aws.html
	# 반드시 ( 미국 동부(us-east-1)  ) 에서 구매해야함



