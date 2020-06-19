#!/bin/bash

export EKS_CLUSTER=skcc05599
export VPC_ID=$(eksctl utils describe-stacks --region=ap-northeast-2 --cluster=${EKS_CLUSTER} | grep OutputValue | grep vpc | cut -d"\"" -f2)
export SUB_CIDR="128.0.0.0/16"

aws ec2 associate-vpc-cidr-block --vpc-id ${VPC_ID} --cidr-block ${SUB_CIDR}

export AZ1=ap-northeast-2a
export AZ2=ap-northeast-2b
export AZ3=ap-northeast-2c

export CUST_SUBNET_A=$(aws ec2 create-subnet --cidr-block 128.0.64.0/18  --vpc-id ${VPC_ID} --availability-zone ${AZ1} | jq -r .Subnet.SubnetId)
export CUST_SUBNET_B=$(aws ec2 create-subnet --cidr-block 128.0.128.0/18 --vpc-id ${VPC_ID} --availability-zone ${AZ2} | jq -r .Subnet.SubnetId)
export CUST_SUBNET_C=$(aws ec2 create-subnet --cidr-block 128.0.192.0/18 --vpc-id ${VPC_ID} --availability-zone ${AZ3} | jq -r .Subnet.SubnetId)

export RTB_ID_A=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC_ID | jq -r '.RouteTables[] | select(.Tags[].Value | startswith("PrivateRouteTableAPNORTHEAST2A")) | .RouteTableId')
export RTB_ID_B=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC_ID | jq -r '.RouteTables[] | select(.Tags[].Value | startswith("PrivateRouteTableAPNORTHEAST2B")) | .RouteTableId')
export RTB_ID_C=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC_ID | jq -r '.RouteTables[] | select(.Tags[].Value | startswith("PrivateRouteTableAPNORTHEAST2C")) | .RouteTableId')

echo "# VPC_ID        : ${VPC_ID}" 

echo "# CUST_SUBNET_A : ${CUST_SUBNET_A}"
echo "# CUST_SUBNET_B : ${CUST_SUBNET_B}"
echo "# CUST_SUBNET_C : ${CUST_SUBNET_C}"

echo "# RTB_ID_A      : ${RTB_ID_A}"
echo "# RTB_ID_B      : ${RTB_ID_B}"
echo "# RTB_ID_C      : ${RTB_ID_C}"

# Main

aws ec2 create-tags --resources ${CUST_SUBNET_A} --tags Key=Name,Value=${EKS_CLUSTER}-PodSubnetA
aws ec2 create-tags --resources ${CUST_SUBNET_B} --tags Key=Name,Value=${EKS_CLUSTER}-PodSubnetB
aws ec2 create-tags --resources ${CUST_SUBNET_C} --tags Key=Name,Value=${EKS_CLUSTER}-PodSubnetC

aws ec2 create-tags --resources ${CUST_SUBNET_A} --tags Key=kubernetes.io/cluster/${EKS_CLUSTER},Value=shared
aws ec2 create-tags --resources ${CUST_SUBNET_B} --tags Key=kubernetes.io/cluster/${EKS_CLUSTER},Value=shared
aws ec2 create-tags --resources ${CUST_SUBNET_C} --tags Key=kubernetes.io/cluster/${EKS_CLUSTER},Value=shared

aws ec2 associate-route-table --route-table-id ${RTB_ID_A} --subnet-id ${CUST_SUBNET_A}
aws ec2 associate-route-table --route-table-id ${RTB_ID_B} --subnet-id ${CUST_SUBNET_B}
aws ec2 associate-route-table --route-table-id ${RTB_ID_C} --subnet-id ${CUST_SUBNET_C}

kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=failure-domain.beta.kubernetes.io/zone

cat <<EOF | kubectl apply -f -
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
EOF


TMP_FILE=/tmp/skcc05599.${RANDOM}
aws ec2 describe-security-groups  | jq -r --arg VPC "${VPC_ID}" '.SecurityGroups[] | select(.VpcId | startswith($VPC)) | select(.GroupName | contains("skcc05599")) | .GroupId' > ${TMP_FILE}
readarray -t SG_ARRAY < ${TMP_FILE}
rm -rf ${TMP_FILE}

echo "${SG_ARRAY[0]}"
echo "${SG_ARRAY[1]}"
echo "${SG_ARRAY[2]}"

cat <<EOF | kubectl apply -f -
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: ap-northeast-2a
spec:
  subnet: ${CUST_SUBNET_A}
  securityGroups:
  - ${SG_ARRAY[0]}
  - ${SG_ARRAY[1]}
  - ${SG_ARRAY[2]}
EOF

cat <<EOF | kubectl apply -f -
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: ap-northeast-2b
spec:
  subnet: ${CUST_SUBNET_B}
  securityGroups:
  - ${SG_ARRAY[0]}
  - ${SG_ARRAY[1]}
  - ${SG_ARRAY[2]}
EOF

cat <<EOF | kubectl apply -f -
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: ap-northeast-2c
spec:
  subnet: ${CUST_SUBNET_C}
  securityGroups:
  - ${SG_ARRAY[0]}
  - ${SG_ARRAY[1]}
  - ${SG_ARRAY[2]}
EOF
