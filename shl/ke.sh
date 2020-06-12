#!/bin/bash

kubectl exec -ti -n $1 pod/$2 -- sh
