#!/bin/bash

wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -O /usr/bin/cfssl
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -O /usr/bin/cfssl-json
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -O /usr/bin/cfssl-certinfo
chmod +x /usr/bin/cfssl*

cfssl gencert -initca ca-csr.json | cfssljson -bare ./pem/ca

cfssl gencert -ca=./pem/ca.pem -ca-key=./pem/ca-key.pem -config=ca-config.json -profile=peer etcd-peer-csr.json | cfssljson -bare ./pem/etcd-peer

cfssl gencert -ca=./pem/ca.pem -ca-key=./pem/ca-key.pem -config=ca-config.json -profile=client client-csr.json | cfssljson -bare ./pem/client

cfssl gencert -ca=./pem/ca.pem -ca-key=./pem/ca-key.pem -config=ca-config.json -profile=server apiserver-csr.json | cfssljson -bare ./pem/apiserver

cfssl gencert -ca=./pem/ca.pem -ca-key=./pem/ca-key.pem -config=ca-config.json -profile=server kubelet-csr.json | cfssljson -bare ./pem/kubelet

cfssl gencert -ca=./pem/ca.pem -ca-key=./pem/ca-key.pem -config=ca-config.json -profile=client kube-proxy-csr.json | cfssljson -bare ./pem/kube-proxy-client

sleep 1

# cfssl-certinfo -cert ./pem/apiserver.pem

# cfssl-certinfo -domain www.baidu.com

# mkd5sum filename

#echo 'LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUR3akNDQXFxZ0F3SUJBZ0lVTmY1bktlSGNaaDArUEdhWkhTS1VZbG9wNWp3d0RRWUpLb1pJ
# aHZjTkFRRUwKQlFBd1lERUxNQWtHQTFVRUJoTUNRMDR4RURBT0JnTlZCQWdUQjJKbGFXcHBibWN4RURBT0JnTlZCQWNUQjJKbAphV3BwYm1jeEN6QUpCZ
# 05WQkFvVEFtOWtNUXd3Q2dZRFZRUUxFd052Y0hNeEVqQVFCZ05WQkFNVENVOXNaR0p2CmVVVmtkVEFlRncweE9URXlNRFV4TWpFMU1EQmFGdzB6T1RFeE
# 16QXhNakUxTURCYU1GOHhDekFKQmdOVkJBWVQKQWtOT01SQXdEZ1lEVlFRSUV3ZGlaV2xxYVc1bk1SQXdEZ1lEVlFRSEV3ZGlaV2xxYVc1bk1Rc3dDUVl
# EVlFRSwpFd0p2WkRFTU1Bb0dBMVVFQ3hNRGIzQnpNUkV3RHdZRFZRUURFd2hyT0hNdGJtOWtaVENDQVNJd0RRWUpLb1pJCmh2Y05BUUVCQlFBRGdnRVBB
# RENDQVFvQ2dnRUJBTlJIZ1FUZ2pTcllPdGRMOTBSWGcvdVk0VWNEUDRLWXd4MCsKSWVNVVhnTTFGZ2dvUDZ5aUJIOC9hbjhwR2xIY3QzYVVGWWpwTllzb
# XhSZXRHRWpzbWk0ZzFkOEZCMGZvck9vNgpDM3lmVTBqbVhEeGorMHc1MUlnRFp5WDB3OVJMb0VtanBUN0JLRXN2Zmhxc3VMaW9LUWhja0Z1ZHhKZW1ybz
# F4CkJ5Tm1za2hBRHVETFBUdGhwMWVtMFZESEdIbUoxUHRPdEpsbGlQY1orMWgxcTMvbXJFMFlSV054a3ltOWlLbkMKaFB1MHlIVUIwRkoyNlNLaCtBVHI
# rUS9Za08vTHY0KzRMRzlKaDB3akVxYURjRFNRcmcwdC9OVXUvVVFXV2hvYQppNStsbmlaYmFXSEt5MzRRU2U5Yms3SDN2N0Z3Y0JwTTBIaW5Fbms0L2NX
# OWtBV2F2T0VDQXdFQUFhTjFNSE13CkRnWURWUjBQQVFIL0JBUURBZ1dnTUJNR0ExVWRKUVFNTUFvR0NDc0dBUVVGQndNQ01Bd0dBMVVkRXdFQi93UUMKT
# UFBd0hRWURWUjBPQkJZRUZLWTh0SUg2SVZCRXl6dTJLRDRpU2JvNERtbWhNQjhHQTFVZEl3UVlNQmFBRk1jSgo4VHM4Y3NSS3NPQ2hFNWhzMForQUZ6K3
# pNQTBHQ1NxR1NJYjNEUUVCQ3dVQUE0SUJBUUNwdFpyZVExcTBoclExCjQ1Y0h6OVJaQ3Z2cWNsV1duOVdzYk85Z1M3c3JaR3RDR0FZL2pmeTFwaExpTUt
# NOURESUYwSnBFVWdLaVJIMTIKMEhZMStRTUp2WWhNaXRFYlhTbk1seVMvM3dOOGR2VEIxOWdSZ1VKTUFJYnZ3TXg3dDlVVXZOV2M1dU9ES29LYQpUdHZG
# MXcyRVNLdVgrYWZEaE1iNzB6eFY0SmlpZlYxNTIveWRMSk9sbkMwV2lpeUptSjJRY1FrUmNxNzErak81CmRQVTlUQi96c2lYMVBRTTJlM3RwbjA0T3VBR
# lhvWGZ3U1Zvc0hYem1'|base64 -d > 1.pem


# cfssl-certinfo -cert 1.pem
