# Installing required packages for repacking iso image:
apt install xorriso genisoimage isolinux

# Download Ubuntu iso:
wget https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/jammy-live-server-amd64.iso
or 
wget https://releases.ubuntu.com/22.04.1/ubuntu-22.04.1-live-server-amd64.iso

# Extract ISO:
mkdir -p /opt/ubuntu_custom_iso
mount -t iso9660 -o loop jammy-live-server-amd64.iso  /mnt/
# it will mount iso in readonly mode, we will copy the files to modify it
cd /mnt
tar cf - . | (cd /opt/ubuntu_custom_iso; tar xfp -)
chmod -R +w /opt/ubuntu_custom_iso
cd /opt/

# Create user-data directory: sample user-data and device-update script is in github repo
mkdir -p ubuntu_custom_iso/ks
touch ubuntu_custom_iso/ks/meta-data
cp user-data ubuntu_custom_iso/ks/
cp device-update.sh ubuntu_custom_iso/ks/
chmod +x ubuntu_custom_iso/ks/device-update.sh

# Update the cloud-init user-data config in grub.cfg for autoinstall    
sed -i 's|\/casper\/vmlinuz|\/casper\/vmlinuz quiet autoinstall ds=nocloud\\;s=\/cdrom\/ks\/|g' boot/grub/grub.cfg

# Disabling checksum
md5sum ubuntu_custom_iso/.disk/info > ubuntu_custom_iso/md5sum.txt

# Extract MBR and EFI
ISO=jammy-live-server-amd64.iso
fdisk -l $ISO
mkdir img
dd if=$ISO bs=1 count=432 of=img/boot_mbr.img
#dd if=jammy-live-server-amd64.iso bs=512 skip=3863644 count=10068 of=img/boot_efi.img
dd if=$ISO bs=512 skip=$(fdisk -l $ISO | grep "EFI" | awk '{print $2}') count=$(fdisk -l $ISO | grep "EFI" | awk '{print $4}') of=img/boot_efi.img

# Create ISO
xorriso -as mkisofs -r -V "Ubuntu 22 Custom ISO" \
    --grub2-mbr img/boot_mbr.img \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -J -l -append_partition 2 0xEF img/boot_efi.img -appended_part_as_gpt \
    -c boot.catalog -b /boot/grub/i386-pc/eltorito.img \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e '--interval:appended_partition_2:all::' \
    -no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
    -o ubuntu-22-autoinstall.iso ubuntu_custom_iso

# Sample user-data has below details for login 
user:  ubuntu  
password: ubuntu 
Note: you can change it as per your requirement  
