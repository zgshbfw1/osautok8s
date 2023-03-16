#!/bin/sh
export mypass=GRau6zipwGMpuSWk

expect -c "
spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@$i
  expect {
    \"*yes/no*\" {send \"yes\r\"; exp_continue}
    \"*password*\" {send \"$mypass\r\"; exp_continue}
    \"*Password*\" {send \"$mypass\r\";}
  }"

