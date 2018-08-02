#!/sbin/sh
mount_fs system
BOOT_PARTITION=/dev/block/bootdevice/by-name/boot
if [ -e /system/boot.img.bak ]; then
    ui_print "Restoring boot image..."
    ui_print ""
    dd if=/system/boot.img.bak of=$BOOT_PARTITION

    if [ $? != 0 ]; then
        ui_print "Failed to restore boot image."
        ui_print ""
        exit 1
    fi
    rm /system/boot.img.bak
else
        ui_print "No backup boot image found."
        ui_print ""
fi
umount_fs system
