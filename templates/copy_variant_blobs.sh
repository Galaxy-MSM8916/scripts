#!/sbin/sh

BLOBBASE=/tmp/proprietary
IMG_BASE=/tmp/img
BLOCKDEV_PATH=/dev/block/bootdevice/by-name

# Mount /system
mount_fs system

if [ -d $BLOBBASE ]; then

    cd $BLOBBASE

    # copy all the blobs
    for FILE in `find . -type f | cut -c 3-` ; do
        mkdir -p `dirname /system/$FILE`
        ui_print "Copying $FILE to /system/$FILE ..."
        cp $FILE /system/$FILE
    done

    # set permissions on binary files
    for FILE in `find bin -type f | cut -c 3-`; do
        ui_print "Setting /system/$FILE executable ..."
        chmod 755 /system/$FILE
    done
umount_fs system
fi

if [ -d $IMG_BASE ]; then

    for img in `find $IMG_BASE -type f | cut -c 3-` ; do
        ui_print "Flashing `basename ${img}`..."
	img_proper=`basename $img|sed s'/\.img//'g`
	if [ -e ${BLOCKDEV_PATH}/${img_proper} ]; then
            dd if=${img} of=${BLOCKDEV_PATH}/${img_proper}
            ui_print "Wrote ${img_proper} succesfully."
        else
            ui_print "Error: device ${BLOCKDEV_PATH}/${img_proper} does not exist."
            ui_print "Flashing ${img} failed!"
	    exit 1
	fi
    done
fi
