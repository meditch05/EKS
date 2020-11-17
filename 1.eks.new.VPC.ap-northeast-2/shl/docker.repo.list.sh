#!/bin/bash

export ECR_URL=`   aws ecr describe-repositories | jq -r .repositories[].repositoryUri | cut -d"/" -f1 | uniq`
export ECR_PASSWD=`aws ecr get-login | cut -d" " -f6`

export IMAGE_REPOS=`     aws ecr describe-repositories | jq -r .repositories[].repositoryUri`

for IMAGE_URI in ${IMAGE_REPOS}
do
   REPOSITORY_NAME=`echo $IMAGE_URI | cut -d"/" -f2`
   aws ecr list-images --repository-name ${REPOSITORY_NAME} | jq -r .imageIds[].imageTag | while read TAG
   do
      echo $IMAGE_URI:${TAG} 
   done
done
