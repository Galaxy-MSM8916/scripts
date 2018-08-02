#!/sbin/sh

BLOBBASE=/tmp/proprietary

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

