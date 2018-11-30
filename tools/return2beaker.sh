#/bin/bash

HOSTNAME=$1
ssh -lroot $HOSTNAME 'return2beaker.sh' && exit 0

NUM=cat ~/.ssh/known_hosts -n |grep $HOSTNAME |awk '{print $1}'
if [ $? -eq 0 ];then
	sed -i ${NUM}d .ssh/known_hosts
fi
ssh -o stricthostkeychecking=no -lroot $HOSTNAME 'return2beaker.sh'
