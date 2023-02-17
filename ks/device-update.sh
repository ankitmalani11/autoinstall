#!/bin/bash

if [ -d "/sys/firmware/efi" ]
then
    echo " "
    echo "System booted in UEFI mode"
    echo " "
    echo "adding UEFI specific parition in user-data file"

sed -n -i '/storage:/q;p' /autoinstall.yaml

tee -a /autoinstall.yaml <<EOF
storage:
    config:
# Partition table
    - {ptable: gpt, path: /dev/DEV_ROOT, wipe: superblock, preserve: false, name: '', grub_device: false, type: disk, id: disk-sda}
# EFI boot partition
    - {device: disk-sda, size: 500M, flag: boot, number: 1, preserve: false, grub_device: true, type: partition, id: sda-grub-efi}
    - {fstype: fat32, volume: sda-grub-efi, preserve: false, type: format, id: boot-efi}
# Linux boot partition
    - {device: disk-sda, size: 2G, wipe: superblock, flag: '', number: 2, preserve: false, grub_device: false, type: partition, id: sda-boot}
    - {fstype: ext4, volume: sda-boot, preserve: false, type: format, id: sda-boot-fs}
# Partition for LVM, VG
    - {device: disk-sda, size: -1, wipe: superblock, flag: '', number: 3, preserve: false, grub_device: false, type: partition, id: sda-lvm}
    - {name: vg0, devices: [ sda-lvm ], preserve: false, type: lvm_volgroup, id: vg0}
# LV for root, swap and data
    - {name: root, volgroup: vg0, size: 15G, wipe: superblock, preserve: false, type: lvm_partition, id: lv-vg0-root}
    - {fstype: ext4, volume: lv-vg0-root, preserve: false, type: format, id: vg0-root}
    - {name: swap, volgroup: vg0, size: 2G, wipe: superblock, preserve: false, type: lvm_partition, id: lv-vg0-swap}
    - {fstype: swap, volume: lv-vg0-swap, preserve: false, type: format, id: vg0-swap}
    - {name: data, volgroup: vg0, size: -1, wipe: superblock, preserve: false, type: lvm_partition, id: lv-vg0-data}
    - {fstype: ext4, volume: lv-vg0-data, preserve: false, type: format, id: vg0-data}
# Mount Points:
    - {path: /, device: vg0-root, type: mount, id: m-root}
    - {path: '', device: vg0-swap, type: mount, id: m-swap}
    - {path: /data, device: vg0-data, type: mount, id: m-data}
    - {path: /boot, device: sda-boot-fs, type: mount, id: m-boot}
    - {path: /boot/efi, device: boot-efi, type: mount, id: m-boot-efi }
    swap:
      swap: 0
updates: security
user-data:
    chpasswd:
        expire: false
        list:
EOF
echo '        -   root: $6$rounds=4096$owyF/FOGCJmUz.s2$vVpJh.SVoTHqmgnqM82KT1cLgKGY5H2LZcerg9AkhvFFmbGSyNMnNG3n439bU5vWZ6.J0EbMPxYsNp4EMdXBX1' >> /autoinstall.yaml
#        -   root: $6$rounds=4096$owyF/FOGCJmUz.s2$vVpJh.SVoTHqmgnqM82KT1cLgKGY5H2LZcerg9AkhvFFmbGSyNMnNG3n439bU5vWZ6.J0EbMPxYsNp4EMdXBX1
tee -a /autoinstall.yaml <<EOF
    disable_root: false
version: 1
...
EOF

else
    echo " "
    echo "System booted in BIOS mode"
    echo " "
    echo "adding BIOS specific parition in user-data file"

sed -n -i '/storage:/q;p' /autoinstall.yaml

tee -a /autoinstall.yaml <<EOF
storage:
    config:
# Partition table
    - {ptable: gpt, path: /dev/DEV_ROOT, wipe: superblock, preserve: false, name: '', grub_device: true, type: disk, id: disk-sda}
# BIOS boot Partition
    - {device: disk-sda, size: 1M, flag: bios_grub, number: 1, preserve: false, grub_device: false, type: partition, id: sda-grub-bios}
# Linux boot partition
    - {device: disk-sda, size: 2G, wipe: superblock, flag: '', number: 2, preserve: false, grub_device: false, type: partition, id: sda-boot}
    - {fstype: ext4, volume: sda-boot, preserve: false, type: format, id: sda-boot-fs}
# Partition for LVM, VG
    - {device: disk-sda, size: -1, wipe: superblock, flag: '', number: 3, preserve: false, grub_device: false, type: partition, id: sda-lvm}
    - {name: vg0, devices: [ sda-lvm ], preserve: false, type: lvm_volgroup, id: vg0}
# LV for root, swap and data
    - {name: root, volgroup: vg0, size: 15G, wipe: superblock, preserve: false, type: lvm_partition, id: lv-vg0-root}
    - {fstype: ext4, volume: lv-vg0-root, preserve: false, type: format, id: vg0-root}
    - {name: swap, volgroup: vg0, size: 2G, wipe: superblock, preserve: false, type: lvm_partition, id: lv-vg0-swap}
    - {fstype: swap, volume: lv-vg0-swap, preserve: false, type: format, id: vg0-swap}
    - {name: data, volgroup: vg0, size: -1, wipe: superblock, preserve: false, type: lvm_partition, id: lv-vg0-data}
    - {fstype: ext4, volume: lv-vg0-data, preserve: false, type: format, id: vg0-data}
# Mount Points:
    - {path: /, device: vg0-root, type: mount, id: m-root}
    - {path: '', device: vg0-swap, type: mount, id: m-swap}
    - {path: /data, device: vg0-data, type: mount, id: m-data}
    - {path: /boot, device: sda-boot-fs, type: mount, id: m-boot}
updates: security
user-data:
    chpasswd:
        expire: false
        list:
EOF
echo '        -   root: $6$rounds=4096$owyF/FOGCJmUz.s2$vVpJh.SVoTHqmgnqM82KT1cLgKGY5H2LZcerg9AkhvFFmbGSyNMnNG3n439bU5vWZ6.J0EbMPxYsNp4EMdXBX1' >> /autoinstall.yaml

tee -a /autoinstall.yaml <<EOF
    disable_root: false
version: 1
...
EOF

fi

echo "*************updating /dev/[sda/sdb..../any]*********************"
echo "updating disk indentifier"
DEV_ROOT=$(lsblk | grep disk | awk '{print $1}' | head -n 1)

sed -i "s/DEV_ROOT/$DEV_ROOT/g" /autoinstall.yaml

