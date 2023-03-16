#!/bin/bash
sed -ir "s#LISTEN_PEER_URLS=.*#LISTEN_PEER_URLS=\\\"https://10.129.55.65:2380\\\"#g"  etcd.conf
sed -ir "s#LISTEN_CLIENT_URLS=.*#LISTEN_CLIENT_URLS=\\\"https://10.129.55.65:2379,http://127.0.0.1:2379\\\"#g" etcd.conf
sed -ir "s#INITIAL_CLUSTER=.*#INITIAL_CLUSTER=INITIAL_CLUSTER=\\\"etcd1=https://10.129.52.61:2380,etcd2=https://10.129.52.65:2380,etcd3=https://10.129.52.155:2380\\\"#g" etcd.conf
sed -ir "s#ADVERTISE_CLIENT_URLS.*#ADVERTISE_CLIENT_URLS=\\\"https://10.129.55.65:2379\\\"#g" etcd.conf
