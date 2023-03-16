#!/bin/bash

for i in $(kubectl get csr|awk -F'[ ]+' 'NR>1{print $1}');do kubectl certificate approve $i;done
