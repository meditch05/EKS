#!/bin/bash

declare -a SG_ARRAY=("sg-1" "sg-2" "sg-3")


#for SG in ${SGs}
#do
#  SG_ARRAY[${INDEX}]=${SG}
#  INDEX=$(( ${INDEX} +1))
#done

TMP_FILE=/tmp/skcc05599.${RANDOM}


aws ec2 describe-security-groups  | jq -r '.SecurityGroups[] | select(.VpcId | startswith("vpc-0e3a2fec981fa4624")) | select(.GroupName | contains("skcc05599")) | .GroupId' > ${TMP_FILE}

cat ${TMP_FILE}

readarray -t SG_ARRAY < ${TMP_FILE}

rm -rf ${TMP_FILE}


echo "${SG_ARRAY[@]}"
echo "${SG_ARRAY[0]}"
echo "${SG_ARRAY[1]}"
echo "${SG_ARRAY[2]}"
