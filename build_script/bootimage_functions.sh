#!/bin/bash
# Copyright (C) 2017 Vincent Zvikaramba
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function create_scripts {

if [ "x$DISTRIBUTION" == "xlineage" ] ||  [ "x$DISTRIBUTION" == "xlineage-go" ] || [ "x$DISTRIBUTION" == "xrr" ]; then
    kern_base="CAF"
else
    kern_base="AOSP"
fi
dist_str="$kern_base $ver kernel only guaranteed to boot on $kern_base $ver based systems"
plat_short=`echo $platform_version|cut -c -3`

cat <<SWAP_K_F > ${boot_pkg_dir}/${install_target_dir}/installbegin/swap_kernel.sh
#!/sbin/sh

#convert cpio recovery image to bootfs one

error_msg="Error creating boot image! Aborting..."

BOOT_PARTITION=/dev/block/bootdevice/by-name/boot
BOOT_IMG=/tmp/blobs/boot.img

BIN_PATH=/tmp/install/bin/

BOOT_PARTITION_BASENAME=\$(basename \$BOOT_PARTITION)
BOOT_IMG_BASENAME=\$(basename \$BOOT_IMG)

BOOT_PARTITION_TMPDIR=\$(mktemp -d)
BOOT_IMG_TMPDIR=\$(mktemp -d)

ui_print ""
ui_print "==========================================="
ui_print ""
ui_print "Kernel swapper v1.0"
ui_print ""
ui_print "$dist_str"
ui_print ""
sleep 1
ui_print "CAF = CodeAuroraForums (Qualcomm source)"
ui_print "AOSP = Upstream Google source code"
ui_print ""
ui_print "==========================================="
ui_print ""

sleep 1

mount_fs system

ui_print "Backing up boot partition to /system/boot.img.bak ..."
ui_print ""
dd if=\$BOOT_PARTITION of=/system/boot.img.bak

if [ \$? != 0 ]; then
    ui_print "Failed to back up boot image."
    ui_print ""
fi

display_id=\`cat /system/build.prop |grep ro.build.display.id\`
dist=\`echo \$display_id | grep -o $DISTRIBUTION\`
plat=\`echo \$display_id | grep -o $plat_short\`

umount_fs system

if [ -n "\$dist" ] && [ -n "\$plat" ]; then
    ui_print
    ui_print "Detected android distribution ${distroTxt}/${DISTRIBUTION}-${ver} on platform ${platform_version}"
    ui_print
    ui_print "Flashing boot image without repacking..."
    dd if=\$BOOT_IMG of=\$BOOT_PARTITION
    if [ \$? != 0 ]; then
        ui_print
        ui_print "Failed to back up boot image."
        ui_print
        exit 1
    fi
else
    ui_print "Unpacking \$BOOT_PARTITION..."
    \$BIN_PATH/unpackbootimg -i \$BOOT_PARTITION -o \$BOOT_PARTITION_TMPDIR/

    if [ \$? != 0 ]; then
        ui_print \$error_msg
        ui_print ""
        exit 1
    fi

    ui_print "Unpacking \$BOOT_IMG..."
    \$BIN_PATH/unpackbootimg -i \$BOOT_IMG -o \$BOOT_IMG_TMPDIR/

    if [ \$? != 0 ]; then
        ui_print \$error_msg
        ui_print ""
        exit 1
    fi

    ui_print "Replacing kernel..."
    rm \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-zImage
    cp \$BOOT_IMG_TMPDIR/\${BOOT_IMG_BASENAME}-zImage \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-zImage

    ui_print "Replacing dt..."
    rm \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-dt
    cp \$BOOT_IMG_TMPDIR/\${BOOT_IMG_BASENAME}-dt \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-dt

    if [ \$? != 0 ]; then
        ui_print \$error_msg
        ui_print ""
        exit 1
    fi

    base=\`cat \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-base\`
    ramdisk_offset=\`cat \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-ramdisk_offset\`
    pagesize=\`cat \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-pagesize\`
    #cmdline="\`cat \$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-cmdline\`"
    cmdline="\`cat \$BOOT_IMG_TMPDIR/\${BOOT_IMG_BASENAME}-cmdline\`"
    zImage=\$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-zImage
    ramdisk=\$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-ramdisk.gz
    dt=\$BOOT_PARTITION_TMPDIR/\${BOOT_PARTITION_BASENAME}-dt
    file_out=\$BOOT_PARTITION_TMPDIR/boot.img

    ui_print "Repacking boot image..."
    \$BIN_PATH/mkbootimg --kernel \$zImage --ramdisk \$ramdisk --cmdline "\$cmdline" \\
        --base \$base --pagesize \$pagesize --ramdisk_offset \$ramdisk_offset \\
        --dt \$dt -o \$file_out

    if [ \$? != 0 ]; then
        ui_print \$error_msg
        ui_print ""
        exit 1
    fi

    ui_print "Making bootimage SEAndroid enforcing..."
    echo -n "SEANDROIDENFORCE" >> \${file_out}

    ui_print "Flashing boot image..."
    dd if=\$file_out of=\$BOOT_PARTITION

    if [ \$? != 0 ]; then
        ui_print \$error_msg
        ui_print ""
        exit 1
    fi
fi

ui_print "Cleaning up..."
ui_print ""
rm -r \$BOOT_PARTITION_TMPDIR
rm -r \$BOOT_IMG_TMPDIR

ui_print "Successfully flashed new boot image."
ui_print ""
SWAP_K_F
}
