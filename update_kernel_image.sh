#! /usr/bin/env bash

#convert cpio recovery image to bootfs one

export PATH="$PATH:$(dirname `realpath $0`)/tools"

if [ -z $1 ]; then
    echo "Usage $0 /path/to/image_to_update.tar /path/to/image_with_kernel_dt.img [recovery|boot] [dt|kern]"
    exit
fi

if [ -z $2 ]; then
    echo "Usage $0 /path/to/image_to_update.tar /path/to/image_with_kernel_dt.img [recovery|boot] [dt|kern]"
    exit
fi 

img1=$(realpath $1)
img2=$(realpath $2)
b_img1=$(basename $img1)
b_img2=$(basename $img2)

if [ -z $3 ]; then
    target="boot"
    else
    target=$3
fi 

if [ -z $4 ]; then
    isdt="kern"
    else
    isdt=$4
fi 

tdir=$(mktemp -d)
tdir2=$(mktemp -d)

mkdir $tdir/$target -p
mkdir $tdir2/$target -p

cd $tdir

if [ $? != 0 ]; then
    echo "Error, aborting..."
    exit
fi

echo "Unpacking $1..."

unpackbootimg -i $img1 -o $tdir/$target

if [ $? != 0 ]; then
    echo "Error, aborting..."
    exit
fi

cd $tdir2

echo "Unpacking $2..."
#tar xf $img2 -C $tdir2
cp $img2 $tdir2

if [ $? != 0 ]; then
    echo "Error, aborting..."
    exit
fi

echo "Unpacking $2..."
unpackbootimg -i $img2 -o $tdir2/$target

if [ $? != 0 ]; then
    echo "Error, aborting..."
    exit
fi

if [ $isdt == "kern" ]; then
	echo "Replacing kernel..."
	rm $tdir/$target/${b_img1}-zImage
	cp $tdir2/$target/${b_img2}-zImage $tdir/$target/${b_img1}-zImage
fi

echo "Replacing dt..."
rm $tdir/$target/${b_img1}-dt
cp $tdir2/$target/${b_img2}-dt $tdir/$target/${b_img1}-dt

if [ $? != 0 ]; then
    echo "Error, aborting..."
    exit
fi

echo "Creating $target.img..."
mkbootimg --kernel $tdir/$target/${b_img1}-zImage \
        --ramdisk $tdir/$target/${b_img1}-ramdisk.gz \
        --cmdline 'console=tty0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 androidboot.bootdevice=7824900.sdhci androidboot.selinux=permissive' \
        --base 80000000 --pagesize 2048 \
	--ramdisk_offset 0x02000000 \
	--dt $tdir/$target/${b_img1}-dt -o $tdir/$target/${target}.img
	
mkbootimg --kernel $tdir/$target/${b_img1}-zImage \
        --ramdisk $tdir/$target/${b_img1}-ramdisk.gz \
        --cmdline 'console=tty0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 androidboot.bootdevice=7824900.sdhci androidboot.selinux=permissive' \
        --base 80000000 --pagesize 2048 \
	--ramdisk_offset 0x02000000 \
	--dt $tdir/$target/${b_img1}-dt -o $tdir/$target/${target}_tty0.img
	
mkbootimg --kernel $tdir/$target/${b_img1}-zImage \
        --ramdisk $tdir/$target/${b_img1}-ramdisk.gz \
        --cmdline 'console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 androidboot.bootdevice=7824900.sdhci androidboot.selinux=permissive' \
        --base 80000000 --pagesize 2048 \
	--ramdisk_offset 0x02000000 \
	--dt $tdir/$target/${b_img1}-dt -o $tdir/$target/${target}_ttyHSL0.img


	
#	--tags_offset 0x01E00000  \
#        --second_offset 0x00f00000 \

if [ $? != 0 ]; then
    echo "Error, aborting..."
    exit
fi
        
file_out=$(echo $img1  | sed s/.tar/_bootfs.tar/g)


echo "Creating tar file..."
tar cf $file_out -C $tdir/$target/ $target.img
mv $tdir/$target/${target}_ttyHSL0.img $(dirname $img1)
mv $tdir/$target/${target}_tty0.img $(dirname $img1)
if [ $? != 0 ]; then
    echo "Error, aborting..."
    exit
fi
rm -r $tdir
echo "Done. Written to $file_out ."
