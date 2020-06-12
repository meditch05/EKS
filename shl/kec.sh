#!/bin/bash

kubectl exec -ti -n $1 pod/$2 -c $3 -- sh
