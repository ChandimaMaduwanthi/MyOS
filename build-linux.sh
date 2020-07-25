#!/bin/sh

# This script assembles the MyOS bootloader, kernel 
# with NASM, and then creates floppy and CD images (on Linux)

# Only the root user can mount the floppy disk image as a virtual
# drive (loopback mounting), in order to copy across the files

# (If you need to blank the floppy image: 'mkdosfs disk_images/myos.flp')


if test "`whoami`" != "root" ; then
	echo "You must be logged in as root to build (for loopback mounting)"
	echo "Enter 'su' or 'sudo bash' to switch to root"
	exit
fi


if [ ! -e disk_images/myos.flp ]
then
	echo ">>> Creating new MyOS floppy image..."
	mkdosfs -C disk_images/myos.flp 1440 || exit
fi


echo ">>> Assembling bootloader..."

nasm -O0 -w+orphan-labels -f bin -o bootload.bin bootload.asm || exit


echo ">>> Assembling MyOS kernel..."


nasm -O0 -w+orphan-labels -f bin -o kernel.bin kernel.asm || exit


echo ">>> Adding bootloader to floppy image..."

dd status=noxfer conv=notrunc if=bootload.bin of=disk_images/myos.flp || exit


echo ">>> Copying MyOS kernel..."

rm -rf tmp-loop

mkdir tmp-loop && mount -o loop -t vfat disk_images/myos.flp tmp-loop && cp kernel.bin tmp-loop/

sleep 0.2

echo ">>> Unmounting loopback floppy..."

umount tmp-loop || exit

rm -rf tmp-loop


echo ">>> Creating CD-ROM ISO image..."

rm -f disk_images/myos.iso
mkisofs -quiet -V 'MYOS' -input-charset iso8859-1 -o disk_images/myos.iso -b myos.flp disk_images/ || exit

echo '>>> Done!'

