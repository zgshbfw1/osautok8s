#!/bin/bash

for i in 10.129.51.132 10.129.51.117
do

   ssh root@"${i}"  "sh /root/scripts/clear_node.sh"

done
