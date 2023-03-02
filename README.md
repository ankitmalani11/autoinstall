Ubuntu 22 Autoinstall Steps <br />
Please check README.txt for more info. <br />

# Installing required packages for repacking iso image: <br />
apt install xorriso genisoimage isolinux 	<br />

# Download Ubuntu iso:	<br />
wget https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/jammy-live-server-amd64.iso	<br />
or 	<br />
wget https://releases.ubuntu.com/22.04.1/ubuntu-22.04.1-live-server-amd64.iso	<br />

# Extract ISO:	<br />
mkdir -p /opt/ubuntu_custom_iso	<br />
mount -t iso9660 -o loop jammy-live-server-amd64.iso  /mnt/	<br />
# it will mount iso in readonly mode, we will copy the files to modify it	<br />
cd /mnt	<br />
tar cf - . | (cd /opt/ubuntu_custom_iso; tar xfp -)	<br />
chmod -R +w /opt/ubuntu_custom_iso	<br />
cd /opt/	<br />

# Create user-data directory: sample user-data and device-update script is in github repo	<br />
mkdir -p ubuntu_custom_iso/ks	<br />
touch ubuntu_custom_iso/ks/meta-data	<br />
cp user-data ubuntu_custom_iso/ks/	<br />
cp device-update.sh ubuntu_custom_iso/ks/	<br />

# Update the cloud-init user-data config in grub.cfg for autoinstall    	<br />
sed -i 's|\/casper\/vmlinuz|\/casper\/vmlinuz quiet autoinstall ds=nocloud\\;s=\/cdrom\/ks\/|g' boot/grub/grub.cfg	<br />

# Disabling checksum	<br />
md5sum ubuntu_custom_iso/.disk/info > ubuntu_custom_iso/md5sum.txt	<br />

# Extract MBR and EFI	<br />
ISO=jammy-live-server-amd64.iso	<br />
fdisk -l $ISO	<br />
mkdir img	<br />
dd if=$ISO bs=1 count=432 of=img/boot_mbr.img	<br />
#dd if=jammy-live-server-amd64.iso bs=512 skip=3863644 count=10068 of=img/boot_efi.img 	<br />
dd if=$ISO bs=512 skip=$(fdisk -l $ISO | grep "EFI" | awk '{print $2}') count=$(fdisk -l $ISO | grep "EFI" | awk '{print $4}') of=img/boot_efi.img	<br />

# Create ISO	<br />
xorriso -as mkisofs -r -V "Ubuntu 22 Custom ISO" \	<br />
    --grub2-mbr img/boot_mbr.img \	<br />
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \	<br />
    -J -l -append_partition 2 0xEF img/boot_efi.img -appended_part_as_gpt \	<br />
    -c boot.catalog -b /boot/grub/i386-pc/eltorito.img \	<br />
    -no-emul-boot -boot-load-size 4 -boot-info-table \	<br />
    -eltorito-alt-boot -e '--interval:appended_partition_2:all::' \	<br />
    -no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \	<br />
    -o ubuntu-22-autoinstall.iso ubuntu_custom_iso	<br />
