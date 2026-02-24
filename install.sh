#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
BOLD='\033[0;1m'
NC='\033[0;0m'

if [[ ! -d /run/archiso ]]; then
    echo -e "${RED}Error: Please run this script in the Arch Linux ISO environment!${NC}"
    exit 1
fi

if ! ping -c 1 -W 2 ping.archlinux.org >/dev/null 2>&1; then
    echo -e "${RED}Error: No network connection detected!${NC}"
    echo -e "${YELLOW}Please ensure you have a network connection before running this script.${NC}"
    echo -e "${YELLOW}You can use 'iwctl' to connect to WiFi or 'ip link' to check network interfaces.${NC}"
    exit 1
fi

echo -e "${BLUE}=== Arch Linux Automated Installation Script ===${NC}"

echo -e "${BLUE}=== Configuration ===${NC}"

echo -n "Target disk (default: /dev/sda): "
read DISK_INPUT
DISK="${DISK_INPUT:-/dev/sda}"

echo -n "Hostname (default: archlinux): "
read HOSTNAME_INPUT
HOSTNAME="${HOSTNAME_INPUT:-archlinux}"

while [[ -z "$USERNAME_INPUT" ]]; do
    echo -n -e "Username (${BOLD}required${NC}): "
    read USERNAME_INPUT
    if [[ -z "$USERNAME_INPUT" ]]; then
        echo -e "${RED}Error: Username cannot be empty!${NC}"
    fi
done
USERNAME="$USERNAME_INPUT"

while [[ -z "$PASSWORD_INPUT" ]]; do
    echo -n -e "Password (${BOLD}required${NC}): "
    read -s PASSWORD_INPUT
    if [[ -z "$PASSWORD_INPUT" ]]; then
        echo -e "\n${RED}Error: Password cannot be empty!${NC}"
    fi
done
PASSWORD="$PASSWORD_INPUT"

echo -n -e "\nTimezone (default: Asia/Shanghai): "
read TIMEZONE_INPUT
TIMEZONE="${TIMEZONE_INPUT:-Asia/Shanghai}"

echo -n "Add Chinese locale zh_CN.UTF-8? (y/N): "
read ADD_ZH_CN

echo -e "\n${BLUE}=== Configuration Summary ===${NC}"
echo -e "Target disk: ${YELLOW}$DISK${NC}"
echo -e "Hostname: ${YELLOW}$HOSTNAME${NC}"
echo -e "Username: ${YELLOW}$USERNAME${NC}"
echo -e "Timezone: ${YELLOW}$TIMEZONE${NC}"
echo -e "Locale: ${YELLOW}en_US.UTF-8${NC}"
if [[ $ADD_ZH_CN == [Yy] ]]; then
    echo -e "Add Chinese support: ${YELLOW}Yes${NC}"
else
    echo -e "Add Chinese support: ${YELLOW}No${NC}"
fi

echo -e "\n${RED}=== WARNING: This script will format $DISK, all data will be lost! ===${NC}"
echo -n "Confirm and continue? (y/N): "
read confirm
if [[ $confirm != [Yy] ]]; then
    echo -e "${RED}Installation cancelled.${NC}"
    exit 1
fi

echo -e "${BLUE}=== Synchronizing system time ===${NC}"
timedatectl set-ntp true
echo -e "${GREEN}System time synchronized.${NC}"

echo -e "${BLUE}=== Configuring mirrors ===${NC}"
reflector -a 12 -c cn -f 10 --sort rate --save /etc/pacman.d/mirrorlist
echo -e "${GREEN}Mirrors configured.${NC}"

echo -e "${BLUE}=== Updating keyring ===${NC}"
pacman -Sy --noconfirm archlinux-keyring
echo -e "${GREEN}Keyring updated.${NC}"

echo -e "${BLUE}=== Partitioning $DISK ===${NC}"

echo -e "${YELLOW}Clearing disk partition table...${NC}"
sgdisk --zap $DISK

echo -e "${YELLOW}Creating EFI partition (100MB)...${NC}"
sgdisk -n 1:0:+100M -t 1:ef00 -c 1:"EFI" $DISK

echo -e "${YELLOW}Creating ROOT partition...${NC}"
sgdisk -n 2:0:0 -t 2:8300 -c 2:"ROOT" $DISK

partprobe $DISK
echo -e "${GREEN}Partition table created.${NC}"

echo -e "${BLUE}=== Formatting partitions ===${NC}"
echo -e "${YELLOW}Formatting EFI partition as FAT32...${NC}"
mkfs.fat -F32 ${DISK}1
echo -e "${GREEN}EFI partition formatted.${NC}"

echo -e "${YELLOW}Formatting ROOT partition as Btrfs...${NC}"
mkfs.btrfs -f ${DISK}2
echo -e "${GREEN}ROOT partition formatted.${NC}"

echo -e "${YELLOW}Creating Btrfs subvolumes...${NC}"
mount -t btrfs ${DISK}2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt
echo -e "${GREEN}Btrfs subvolumes created (@ and @home).${NC}"

echo -e "${BLUE}=== Mounting partitions ===${NC}"
mount -t btrfs -o subvol=/@,compress=zstd ${DISK}2 /mnt
mount --mkdir -t btrfs -o subvol=/@home,compress=zstd ${DISK}2 /mnt/home
mount --mkdir ${DISK}1 /mnt/efi

echo -e "${GREEN}=== Installing base system ===${NC}"
pacstrap -K /mnt base base-devel linux-zen linux-firmware btrfs-progs --noconfirm
pacstrap /mnt grub efibootmgr networkmanager sudo vim nano intel-ucode zram-generator fastfetch --noconfirm

echo -e "${GREEN}=== Generating fstab ===${NC}"
genfstab -U /mnt >>/mnt/etc/fstab

echo -e "${GREEN}=== Configuring system ===${NC}"
echo -e "${YELLOW}Configuring timezone...${NC}"
arch-chroot /mnt /bin/bash -c "
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    hwclock --systohc
"
echo -e "${GREEN}Timezone configured.${NC}"

echo -e "${YELLOW}Configuring locale...${NC}"
arch-chroot /mnt /bin/bash -c "
    sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
    if [[ \"$ADD_ZH_CN\" == [Yy] ]]; then
        sed -i 's/^#zh_CN.UTF-8/zh_CN.UTF-8/' /etc/locale.gen
    fi
    echo 'LANG=en_US.UTF-8' > /etc/locale.conf
    locale-gen
"
echo -e "${GREEN}Locale configured.${NC}"

echo -e "${YELLOW}Setting hostname...${NC}"
arch-chroot /mnt /bin/bash -c "
    echo $HOSTNAME > /etc/hostname
"
echo -e "${GREEN}Hostname set to $HOSTNAME.${NC}"

echo -e "${YELLOW}Setting root password...${NC}"
arch-chroot /mnt /bin/bash -c "
    echo \"root:$PASSWORD\" | chpasswd
"
echo -e "${GREEN}Root password set.${NC}"

echo -e "${YELLOW}Creating user $USERNAME...${NC}"
arch-chroot /mnt /bin/bash -c "
    useradd -m -G wheel $USERNAME
    echo \"$USERNAME:$PASSWORD\" | chpasswd
"
echo -e "${GREEN}User $USERNAME created and added to wheel group.${NC}"

echo -e "${YELLOW}Configuring sudo...${NC}"
arch-chroot /mnt /bin/bash -c "
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
"
echo -e "${GREEN}Sudo configured for wheel group.${NC}"

echo -e "${YELLOW}Installing GRUB bootloader...${NC}"
arch-chroot /mnt /bin/bash -c "
    grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/efi --removable --recheck
    ln -s /efi/grub /boot/grub
"
echo -e "${GREEN}GRUB installed.${NC}"

echo -e "${YELLOW}Configuring ZRAM...${NC}"
arch-chroot /mnt /bin/bash -c "
    echo -e '[zram0]\nzram-size = ram\ncompression-algorithm = zstd' > /etc/systemd/zram-generator.conf
"
echo -e "${GREEN}ZRAM configured.${NC}"

echo -e "${YELLOW}Configuring GRUB parameters...${NC}"
arch-chroot /mnt /bin/bash -c "
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"zswap.enabled=0 loglevel=5\"/' /etc/default/grub
"
echo -e "${GREEN}GRUB parameters optimized.${NC}"

echo -e "${YELLOW}Generating GRUB configuration...${NC}"
arch-chroot /mnt /bin/bash -c "
    grub-mkconfig -o /boot/grub/grub.cfg
"
echo -e "${GREEN}GRUB configuration generated.${NC}"

echo -e "${YELLOW}Enabling NetworkManager...${NC}"
arch-chroot /mnt /bin/bash -c "
    systemctl enable NetworkManager
"
echo -e "${GREEN}NetworkManager enabled.${NC}"

echo -e "${YELLOW}=== Installation completed ===${NC}"
umount -R /mnt
echo -e "${GREEN}Installation finished successfully!${NC}"

echo -e "${YELLOW}System will reboot in 10 seconds...${NC}"
echo -e "${YELLOW}Press Enter to reboot immediately, or press 'n' to cancel.${NC}"

for i in {10..1}; do
    echo -ne "\r${BLUE}Rebooting in $i seconds...${NC}"
    if read -t 1 -n 1 input; then
        if [[ -z "$input" ]]; then
            echo -e "\n${GREEN}Rebooting immediately...${NC}"
            reboot
            exit 0
        elif [[ "$input" == [Nn] ]]; then
            echo -e "\n${YELLOW}Reboot cancelled.${NC}"
            echo -e "${YELLOW}You can reboot manually by running 'reboot' command.${NC}"
            exit 0
        fi
    fi
done

echo -e "\n${GREEN}Rebooting now...${NC}"
reboot
