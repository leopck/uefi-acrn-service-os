#!/bin/bash

main() {

	local CHROOT=$1

	# Create workspace
	mkdir -p ${CHROOT}/tmp/workspace
	local WS=${CHROOT}/tmp/workspace

	# Setting local variables for ingredients
	local ACRN_BIN=${CHROOT}/usr/lib/acrn/acrn.efi
	local EFI_BOOT=${CHROOT}/boot
	local SOS_BOOTARGS=/usr/share/acrn/samples/nuc/acrn.conf
	KERNEL_PATH=$(find ${CHROOT}/usr/lib/kernel -maxdepth 1 -name '*clearlinux.iot*')
	KERNEL_NAME=$(basename -- ${KERNEL_PATH})

	# Checking file existence
	if [ ! -f ${ACRN_BIN} ]
	then
		echo "ACRN binary is not found."
		exit 1
	fi

	#Create acrn directory inside boot/efi directory 
	mkdir -p ${EFI_BOOT}/EFI/acrn

	#Change default loader to acrn
	echo "default acrn" > ${EFI_BOOT}/loader/loader.conf

	#Copy the acrn efi application into the boot directory
	cp ${ACRN_BIN} ${EFI_BOOT}/EFI/acrn

	#partUUID=$(cat `find {$EFI_BOOT}/loader/entries -maxdepth 1 -name '*Clear-linux*'`  | cut -d' ' -f2 --output-delimiter=\n | grep root)
	partUUID=$(cat {$EFI_BOOT}/loader/entries/Clear-linux-iot-lts2018-sos*  | cut -d' ' -f2 --output-delimiter=\n | grep root)
	cat {$EFI_BOOT}/loader/entries/Clear-linux-iot-lts2018-sos*  | cut -d' ' -f2 --output-delimiter=\n | grep root > ${EFI_BOOT}/file

	#Create boot entry for the ACRN Service OS on the EFI partition
	echo "title sq - The ACRN Service OS
	linux   /EFI/org.clearlinux/kernel-${KERNEL_NAME}
	options console=tty0 console=ttyS2,115200n8 i915.nuclear_pageflip=1 ${partUUID} rw rootfstype=ext4 ignore_loglevel no_timer_check consoleblank=0 i915.tsd_init=7 i915.tsd_delay=2000 i915.avail_planes_per_pipe=0x01010F i915.domain_plane_owners=0x011111110000 i915.enable_guc_loading=0 i915.enable_guc_submission=0 i915.enable_preemption=1 i915.context_priority_mode=2 i915.enable_gvt=1 i915.enable_initial_modeset=1 i915.enable_guc=0 hvlog=2M@0x1FE00000 cma=64M@0-" > ${WS}/acrn.conf

	#Copy the acrn.conf file to the EFI partition we mounted earlier:
	cp ${WS}/acrn.conf ${EFI_BOOT}/loader/entries

	# Configure the EFI firmware to boot the ACRN hypervisor by default
	#efibootmgr -c -l "/EFI/acrn/acrn.efi" -d /dev/mmcblk0 -p 1 -L "ACRN LeafHill Hypervisor" -u "bootloader=/EFI/org.clearlinux/bootloaderx64.efi uart=mmio@0x92230000"

	# Create stitched image
	#touch ${CHROOT}${WS}/hv_cmdline
	#chroot ${CHROOT} /usr/bin/iasimage create -o ${WS}/iasImage -i 0x40300 -d ${WS}/bxt_dbg_priv_key.pem ${WS}/hv_cmdline ${ACRN_BIN} ${SOS_BOOTARGS} ${KERNEL_PATH}

}

main $@
