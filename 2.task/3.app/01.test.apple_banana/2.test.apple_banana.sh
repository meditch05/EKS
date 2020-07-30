#!/bin/bash

# setting ingress host
INGRESS_SVC_EXTERNAL=`kubectl -n infra get svc nginx-ingress-external-controller | grep -v ^NAME | awk '{print $4}'`
INGRESS_SVC_INTERNAL=`kubectl -n infra get svc nginx-ingress-internal-controller | grep -v ^NAME | awk '{print $4}'`

echo ""
echo "##### TEST URL - EXTERNAL NLB #####"
echo "curl -H \"Host: external.ffptest.com\" http://$INGRESS_SVC_EXTERNAL/apple"
echo "curl -H \"Host: external.ffptest.com\" http://$INGRESS_SVC_EXTERNAL/banana"

echo ""
echo "##### TEST URL - INTERNAL NLB #####"
echo "curl -H \"Host: internal.ffptest.com\" http://$INGRESS_SVC_INTERNAL/apple"
echo "curl -H \"Host: internal.ffptest.com\" http://$INGRESS_SVC_INTERNAL/banana"
