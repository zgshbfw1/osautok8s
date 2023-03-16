#!/bin/bash

for i in 10.129.52.142 10.129.52.162  10.129.52.194
do

   ssh root@"${i}"  "sh /root/scripts/clear_node.sh"

done

