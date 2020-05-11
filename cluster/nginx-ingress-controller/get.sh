# kubernetes.github.io/ingress-nginx/deploy/#aws
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/deploy.yaml                                                   -O nginx-ic.yaml
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/204739fb6650c48fd41dc9505f8fd9ef6bc768e1/deploy/static/provider/aws/deploy-tls-termination.yaml -O nginx-ic-tls.yaml

# git 
# git clone https://github.com/nginxinc/kubernetes-ingress.git
