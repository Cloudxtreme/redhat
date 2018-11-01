#!/bin/bash

# virtulization setup
egrep -q '^flags.*(vmx|svm)' /proc/cpuinfo
if [ $? -eq 0 ]; then
	# yum install -y @virtualization for fedorra
	yum install -y qemu-kvm libvirt libvirt-python \
		libguestfs-tools virt-install \
		virt-manager virt-viewer
	systemctl enable libvirtd && systemctl start libvirtd
	lsmod | grep kvm >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "KVM kernel modules are not loaded" && exit
	fi
else
	echo "CPU not support virtualization." && exit
fi

#gbd-kernel build
SOURCEDIR=gdb-linux

if [ -f $SOURCEDIR/.git/config ]; then
	pushd $SOURCEDIR/; git pull  > /dev/null 2>&1; popd
else
	git clone https://github.com/torvalds/linux $SOURCEDIR --depth=1 > /dev/null 2>&1
fi

pushd $SOURCEDIR

cp /boot/config-`uname -r` .config

# CONFIG_GDB_SCRIPTS enable
sed -i "s/^.*CONFIG_GDB_SCRIPTS.*$/CONFIG_GDB_SCRIPTS=y/" .config
# CONFIG_FRAME_POINTER enable
sed -i "s/^.*CONFIG_FRAME_POINTER.*$/CONFIG_FRAME_POINTER=y/" .config
# CONFIG_DEBUG_INFO_REDUCED disable
sed -i "s/^.*CONFIG_DEBUG_INFO_REDUCED.*$/#CONFIG_DEBUG_INFO_REDUCED is not set/" .config
# CONFIG_RANDOMIZE_BASE disable 
sed -i "s/^.*CONFIG_RANDOMIZE_BASE.*$/#CONFIG_RANDOMIZE_BASE is not set/" .config

make O=/root/build-gdb-kernel/ oldconfig && make -j $(($(lscpu -p=cpu -b | grep -v "#" | wc -l)*2))

popd

qemu-img create qemu-image.img 3g
mkfs.ext4 qemu-image.img
qemu-system-x86_64 -kernel bzImage -hda qemu-image.img -append "root=/dev/sda console=ttyS0" --enable-kvm --nographic
#qemu-system-x86_64 -kernel bzImage -drive file=qemu-image.img,index=0,media=disk,format=raw -append "root=/dev/sda" --enable-kvm

