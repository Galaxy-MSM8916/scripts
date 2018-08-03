#!/sbin/sh
mount_fs system

if [ -e /system/build.prop ]; then

    zram_size=##zram_size

    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

    # calculate maximum to 75% of actual memory (in B)
    maximum_disk_size=$(expr $((${MemTotal}*1024)) \* 75 \/ 100)

    # calculate zram disk size
    zram_disk_size=$((1024*1024*${zram_size}))

    # validate disk size
    if [ "$zram_disk_size" -gt "$maximum_disk_size" ]; then
        ui_print "Error: zram size of ${zram_size}MiB is greater than 75% of available RAM"
        ui_print "Use a smaller zram enabler zip"
        ui_print "Aborting..."
        ui_print ""
	exit 1
    fi

    ui_print "Removing old zram props..."
    ui_print ""
    ui_print "Removing ro.config.zram..."
    ui_print ""
    sed -i s'/ro.config.zram=[a-z]*//'g /system/build.prop
    ui_print "Removing ro.config.zram.enabled..."
    ui_print ""
    sed -i s'/ro.config.zram.enabled=[a-z]*//'g /system/build.prop
    ui_print "Removing ro.config.zram.size..."
    ui_print ""
    sed -i s'/ro.config.zram.size=[0-9]*//'g /system/build.prop

    ui_print "Enabling zram..."
    ui_print ""
    
    echo "ro.config.zram.enabled=true" >> /system/build.prop

    if [ $? != 0 ]; then
        ui_print "Failed to add prop."
        ui_print ""
    fi

    ui_print "Setting zram size to ${zram_size} MiB..."
    ui_print ""
    echo "ro.config.zram.size=${zram_size}" >> /system/build.prop

    if [ $? != 0 ]; then
        ui_print "Failed to add prop."
        ui_print ""
    fi
fi
umount_fs system
