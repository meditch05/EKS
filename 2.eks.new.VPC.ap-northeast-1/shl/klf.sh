#!/bin/bash

kubectl logs -f -n $1 pod/$2
