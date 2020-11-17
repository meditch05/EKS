# vi /etc/sysconfig/network-scripts/ifcfg-enp0s3

TYPE=Ethernet 
PROXY_METHOD=none 
BROWSER_ONLY=no 
BOOTPROTO=dhcp 
DEFROUTE=yes 
IPV4_FAILURE_FATAL=no 
IPV6INIT=no 
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=enp0s3
# UUID=6dd2c1e0-9f1f-4a98-a4a6-484cf8750370
DEVICE=enp0s3
ONBOOT=yes


1. Repo 설정 파일 백업 / 생성
# cd /etc/yum.repos.d/
# mkdir BAK
# mv *.repo BAK
# vi CentOS-Kakao.repo

[base]
name=CentOS-$releasever - Base
baseurl=http://ftp.daumkakao.com/centos/$releasever/os/$basearch/
gpgcheck=0 
s
[updates]
name=CentOS-$releasever - Updates
baseurl=http://ftp.daumkakao.com/centos/$releasever/updates/$basearch/
gpgcheck=0

[extras]
name=CentOS-$releasever - Extras
baseurl=http://ftp.daumkakao.com/centos/$releasever/extras/$basearch/
gpgcheck=0
