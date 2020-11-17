#######################################################################################
# Cert Manager - SSL 발급
#######################################################################################
1. SSL 발급
   # https://aws.amazon.com/ko/premiumsupport/knowledge-center/acm-certificate-renewal/
   # https://aws.amazon.com/ko/premiumsupport/knowledge-center/terminate-https-traffic-eks-acm/
   # https://sarc.io/index.php/aws/1745-aws-5-ssl-tls

   * Cert Manager -> Request a certificate -> Request a public certificate
     - Step 1 : Add domain Names         = Domain Name : *.tbiz-atcl.net / tbiz-atcl.net  두개를 등록 ( 와일드카드 인증서 발급 )
     - Step 2 : Select validation method = Domain validation ( Email Validation 하면 webmaster@tbiz-atcl.net 등 5개로 메일보내는데, 메일 서버구성안하면 validation이 불가능함 )
     - Step 3 : Add tags                 = owner / skcc05599
     - Step 4 : Review
     - Step 5 : Validation
       => Validation Status 는 Pending Validation 상태임. 아래 처럼 Validation 하라고 나오는데,
          - Name  : _608501c42ca76bee7ca86da963959131.tbiz-atcl.net.
	  - Type  : CNAME
	  - Value : _e1e28d22e8b964d8200413bd2c7cefa9.jfrzftwwjs.acm-validations.aws.

       => "Create Record in Route53" 을눌러서 Hosted Zone에 CNAME을 생성하면됨. ( 수작업으로 Copy&Paste 하는거 보다 나음 )
          - Route53 -> Hosted Zone -> Domain -> tbiz-atcl.net 에 들어가서 보면 아래 처럼 등록되어있음
	    * Record Name             : _608501c42ca76bee7ca86da963959131.tbiz-atcl.net.
	    * Value/Route traffic to  : IP Address or another value depending on the record type
	                                _e1e28d22e8b964d8200413bd2c7cefa9.jfrzftwwjs.acm-validations.aws.
	    * Record Type             : CNAME - Routes traffic to another domain name and to some AWS resources 

       => Hosted Zone 등록시 대랽 35분 정도 걸렸으니 기다려.( 메시지도 아래 처럼 나옴 ) 
         ( The DNS record was written to your Route 53 hosted zone. It can take 30 minutes or longer for the changes to propagate and for AWS to validate the domain and issue the certificate. ) 

   * Cert Manager -> *.tbiz-atcl.net 에서 Refresh 눌러서 Status가 "Pending validation" 에서 "Issued" 로 바뀌는지 봐라 
     => Issued 로 변경되면 Validation 성공한 것임.

     * 하단에 ARN 을 저장 ( 또는 aws iam list-server-certificates )
     => arn:aws:acm:ap-northeast-2:847322629192:certificate/08a537cc-4d72-42f5-89c5-e27e5605dbbb


2. nginx-ingress-external 재생성  
   ### https://aws.amazon.com/ko/premiumsupport/knowledge-center/terminate-https-traffic-eks-acm/

   # cd ~/EKS/2.task/2.CHART/1.nginx-ingress-1.41.1 
   # helm uninstall nginx-ingress-external -n infra
   # diff 1.values.yaml.nginx-ingress-1.41.1.external 3.values.yaml.nginx-ingress-1.41.1.external-acm
   262a263,269
   >       service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
   >       service.beta.kubernetes.io/aws-load-balancer-ssl-ports: https
   >       service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:ap-northeast-2:847322629192:certificate/08a537cc-4d72-42f5-89c5-e27e5605dbbb
   >       service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
   >       service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "60"
   >       service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
   >
   296c303
   <       https: https
   ---
   >       https: http

   # ==>  NLB에서 SSL Termination을 수행하므로, HTTPS 요청을 HTTP로 돌려주면 됨 ( Ingress의 http 설정을 타고 서비스 되도록 ) 

   # helm install nginx-ingress-external -n infra -f 1.values.yaml.nginx-ingress-1.41.1.external-acm stable/nginx-ingress --version 1.41.1
   # kubectl get svc -n infra | grep nginx-ingress | grep amazonaws.com | awk '{print $4}'
   aeb6475caa21f4982aa0bee0e73d815a-bf54f7e77c8b0c29.elb.ap-northeast-2.amazonaws.com

   * EC2 -> Load Balancing -> Load Balancers -> Listeners -> TLS : 443 에 SSL Certificate 확인
     - SSL Certificate : Default: 08a537cc-4d72-42f5-89c5-e27e5605dbbb (ACM)


3. Route53 -> Hosted Zone -> 각 A Type SubDomain 에 연결된 NLB 주소를 새로 생성한 NLB로 수정
   - api.tbiz-atcl.net
   - bff.tbiz-atcl.net
   - external.tbiz-atcl.net
   - gitlab.tbiz-atcl.net
   - jenkins.tbiz-atcl.net


4. PC에서 접속/인증서 정보확인
   - Chrome -> https://jenkins.tbiz-atcl.net  -> 자물쇠 -> 인증서 정보
     * 발급대상 : tbiz-atcl.net
     * 발급자   : Amazon
     * 유효기간 : 2020-08-10 ~ 201-09-10

5. 각 MSA 서비스 별로 ingress를 수정해줄 필요는 없음
   - NLB에서 SSL Termination 하고나서 HTTPS 로 들어온 요청을 nginx-ingress 의 http 로 넘기기 때문에
     MSA 서비스의 ingress / service / pod는 전혀 손 안데도 됨.

   - https://github.com/kubernetes/ingress-nginx/issues/5206

# Annotaion Reference
  -> https://kubernetes.io/ko/docs/concepts/services-networking/service/
  -> https://kubernetes.io/ko/docs/concepts/cluster-administration/cloud-providers/

  -> https://velog.io/@umi0410/eks-k8s-elb
  -> https://www.digitalocean.com/community/questions/how-to-set-up-nginx-ingress-for-load-balancers-with-proxy-protocol-support


  -> https://github.com/kubernetes/ingress-nginx/issues/5051 #( ********************)
     # kc edit cm/ingress-controller-leader-external-nginx  -n infra
     data:
       use-forwarded-headers: "true"
       compute-full-forwarded-for: "true"
       use-proxy-protocol: "true"

  -> https://kubernetes.github.io/ingress-nginx/user-guide/miscellaneous/

  -> https://m.blog.naver.com/PostView.nhn?blogId=alice_k106&logNo=221505569455&proxyReferer=https:%2F%2Fwww.google.co.kr%2F
