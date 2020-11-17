#!/bin/bash

kubectl logs -n $1 pod/$2
