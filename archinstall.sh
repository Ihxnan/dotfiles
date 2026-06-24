#!/bin/bash

set -e

# Log file setup
LOG_FILE="/tmp/archinstall.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
BOLD='\033[0;1m'
NC='\033[0;0m'

echo -e "${BLUE}=== Installation started at $(date) ===${NC}"

if [[ ! -d /run/archiso ]]; then
    echo -e "${RED}Error: Please run this script in the Arch Linux ISO environment!${NC}"
    exit 1
fi

if ! ping -c 2 -W 3 ping.archlinux.org >/dev/null 2>&1; then
    echo -e "${RED}Error: No network connection detected!${NC}"
    echo -e "${YELLOW}Please ensure you have a network connection before running this script.${NC}"
    echo -e "${YELLOW}You can use 'iwctl' to connect to WiFi or 'ip link' to check network interfaces.${NC}"
    exit 1
fi

# Redirect stdin to terminal (required for curl ... | bash mode)
exec </dev/tty

clear
echo -e "${BLUE}┌────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│             Arch Linux Auto Install                  │${NC}"
echo -e "${BLUE}│          Automated Installation Script              │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${BOLD}${YELLOW}═══ Available Disks ═══${NC}"
lsblk -d -o NAME,SIZE,MODEL | grep -v loop
echo ""
echo -n -e "${BOLD}Target disk${NC} (default: ${YELLOW}/dev/sda${NC}): "
read DISK_INPUT
DISK="${DISK_INPUT:-/dev/sda}"

if [[ ! -b "$DISK" ]]; then
    echo -e "${RED}Error: $DISK is not a valid block device!${NC}"
    echo -e "${YELLOW}Available disks:${NC}"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    exit 1
fi

if [[ $DISK =~ nvme|mmcblk ]]; then
    DISK1="${DISK}p1"
    DISK2="${DISK}p2"
    DISK3="${DISK}p3"
else
    DISK1="${DISK}1"
    DISK2="${DISK}2"
    DISK3="${DISK}3"
fi

echo -e "\n${BOLD}${YELLOW}═══ System Info ═══${NC}"
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

echo -n "Swap partition size for hibernation (e.g., '8G', press Enter for auto = RAM size): "
read SWAP_SIZE_INPUT

echo -e "\n${BOLD}${YELLOW}═══ Install Mode ═══${NC}"
echo -n "Install alongside existing OS? (preserve partitions) (y/N): "
read DUAL_BOOT

if [[ $DUAL_BOOT == [Yy] ]]; then
    echo -e "\n${YELLOW}Current partition layout on $DISK:${NC}"
    lsblk -o NAME,SIZE,FSTYPE,LABEL $DISK
    echo ""
    echo -n "Existing EFI partition (e.g., $DISK1): "
    read EFI_PART_INPUT
    EFI_PART="${EFI_PART_INPUT}"
    echo -n "Target Arch ROOT partition (e.g., $DISK2): "
    read ROOT_PART_INPUT
    ROOT_PART="${ROOT_PART_INPUT}"
    echo -n "Existing SWAP partition (leave empty to skip): "
    read SWAP_PART

    if [[ ! -b "$EFI_PART" ]]; then
        echo -e "${RED}Error: $EFI_PART is not a valid block device!${NC}"
        exit 1
    fi
    if [[ ! -b "$ROOT_PART" ]]; then
        echo -e "${RED}Error: $ROOT_PART is not a valid block device!${NC}"
        exit 1
    fi
    if [[ $(lsblk -no FSTYPE "$EFI_PART") != "vfat" ]]; then
        echo -e "${RED}Error: $EFI_PART is not FAT32 (required for EFI)!${NC}"
        exit 1
    fi
    if [[ -n "$SWAP_PART" && ! -b "$SWAP_PART" ]]; then
        echo -e "${RED}Error: $SWAP_PART is not a valid block device!${NC}"
        exit 1
    fi
else
    echo -e "\n${YELLOW}=== GRUB Options ===${NC}"
    echo -e "${YELLOW}--removable writes to EFI/BOOT/BOOTX64.EFI (fallback path).${NC}"
    echo -e "${YELLOW}Recommended for removable disks or problematic UEFI firmware.${NC}"
    echo -n "Use --removable? (y/N): "
    read GRUB_REMOVABLE
    if [[ $GRUB_REMOVABLE != [Yy] ]]; then
        echo -n "Bootloader ID (default: Arch): "
        read GRUB_ID_INPUT
        GRUB_ID="${GRUB_ID_INPUT:-Arch}"
    fi
fi

# Detect RAM size for swap default
RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
RAM_GB=$(( (RAM_MB + 1023) / 1024 ))

# Calculate swap partition size
if [[ -z "$SWAP_SIZE_INPUT" ]]; then
    SWAP_SIZE_MB=$RAM_MB
else
    if [[ $SWAP_SIZE_INPUT =~ ^[0-9]+[Gg]$ ]]; then
        SWAP_SIZE_MB=$(( ${SWAP_SIZE_INPUT%[Gg]} * 1024 ))
    elif [[ $SWAP_SIZE_INPUT =~ ^[0-9]+[Mm]$ ]]; then
        SWAP_SIZE_MB=${SWAP_SIZE_INPUT%[Mm]}
    else
        SWAP_SIZE_MB=$(( SWAP_SIZE_INPUT * 1024 ))
    fi
fi

echo -e "\n${BOLD}${YELLOW}═══ Configuration Summary ═══${NC}"
printf "  %-14s %b\n" "Disk" "${YELLOW}$DISK${NC}"
if [[ $DUAL_BOOT == [Yy] ]]; then
    printf "  %-14s %b\n" "Mode" "${YELLOW}Dual-boot${NC}"
    printf "  %-14s %b\n" "EFI" "${YELLOW}$EFI_PART${NC} (preserved)"
    printf "  %-14s %b\n" "ROOT" "${YELLOW}$ROOT_PART${NC} (will be formatted)"
else
    printf "  %-14s %b\n" "Mode" "${YELLOW}Fresh install${NC}"
    if [[ $GRUB_REMOVABLE == [Yy] ]]; then
        printf "  %-14s %b\n" "GRUB" "${YELLOW}--removable${NC}"
    else
        printf "  %-14s %b\n" "GRUB" "${YELLOW}--bootloader-id=$GRUB_ID${NC}"
    fi
fi
printf "  %-14s %b\n" "Hostname" "${YELLOW}$HOSTNAME${NC}"
printf "  %-14s %b\n" "User" "${YELLOW}$USERNAME${NC}"
printf "  %-14s %b\n" "Timezone" "${YELLOW}$TIMEZONE${NC}"
printf "  %-14s %b\n" "Locale" "${YELLOW}en_US.UTF-8${NC}"
if [[ $ADD_ZH_CN == [Yy] ]]; then
    printf "  %-14s %b\n" "zh_CN" "${YELLOW}Yes${NC}"
fi
if [[ $DUAL_BOOT == [Yy] && -n "$SWAP_PART" ]]; then
    printf "  %-14s %b\n" "Swap" "${YELLOW}$SWAP_PART${NC} (preserved)"
elif [[ $DUAL_BOOT == [Yy] ]]; then
    printf "  %-14s %b\n" "Swap" "${YELLOW}none (no hibernation)${NC}"
    GRUB_RESUME=""
else
    if [[ -z "$SWAP_SIZE_INPUT" ]]; then
        printf "  %-14s %b\n" "Swap" "${YELLOW}${RAM_GB}G (auto = RAM size)${NC}"
    else
        printf "  %-14s %b\n" "Swap" "${YELLOW}$SWAP_SIZE_INPUT${NC}"
    fi
fi

echo ""
echo -e "  ${RED}─── ⚠ WARNING ───${NC}"
if [[ $DUAL_BOOT == [Yy] ]]; then
    echo -e "  ${RED}$ROOT_PART will be formatted as Btrfs!${NC}"
    echo -e "  ${YELLOW}$EFI_PART${NC} (EFI, preserved)"
    if [[ -n "$SWAP_PART" ]]; then
        echo -e "  ${YELLOW}$SWAP_PART${NC} (swap, will be formatted)"
    fi
else
    echo -e "  ${RED}$DISK will be COMPLETELY FORMATTED, all data will be LOST!${NC}"
fi
echo -n "Confirm and continue? (y/N): "
read confirm
if [[ $confirm != [Yy] ]]; then
    echo -e "${RED}Installation cancelled.${NC}"
    exit 1
fi

echo -e "\n${BOLD}${BLUE}─── Preparing ───${NC}"
echo -e "${BLUE}=== Detecting CPU vendor ===${NC}"
if grep -q GenuineIntel /proc/cpuinfo; then
    UCODE="intel-ucode"
elif grep -q AuthenticAMD /proc/cpuinfo; then
    UCODE="amd-ucode"
else
    UCODE="intel-ucode"
fi
echo -e "${GREEN}Detected CPU microcode package: $UCODE${NC}"

echo -e "${BLUE}=== Synchronizing system time ===${NC}"
timedatectl set-ntp true
echo -e "${GREEN}System time synchronized.${NC}"

echo -e "${BLUE}=== Configuring mirrors ===${NC}"
reflector -a 12 -c cn -f 10 --sort rate --save /etc/pacman.d/mirrorlist
echo -e "${GREEN}Mirrors configured.${NC}"

echo -e "${BLUE}=== Updating keyring ===${NC}"
pacman -Sy --noconfirm archlinux-keyring
echo -e "${GREEN}Keyring updated.${NC}"

if [[ $DUAL_BOOT == [Yy] ]]; then

    echo -e "\n${BOLD}${BLUE}─── Partition & Mount ───${NC}"
    echo -e "${BLUE}=== Formatting ROOT partition ===${NC}"
    echo -e "${YELLOW}Formatting $ROOT_PART as Btrfs...${NC}"
    mkfs.btrfs -f $ROOT_PART
    echo -e "${GREEN}ROOT partition formatted.${NC}"

    if [[ -n "$SWAP_PART" ]]; then
        echo -e "${YELLOW}Formatting $SWAP_PART as swap...${NC}"
        mkswap $SWAP_PART
        echo -e "${GREEN}SWAP partition formatted.${NC}"
    fi

    echo -e "${YELLOW}Creating Btrfs subvolumes...${NC}"
    mount -t btrfs $ROOT_PART /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    umount /mnt
    echo -e "${GREEN}Btrfs subvolumes created (@ and @home).${NC}"

    echo -e "${BLUE}=== Mounting partitions ===${NC}"
    if [[ -n "$SWAP_PART" ]]; then
        swapon $SWAP_PART
    fi
    mount -t btrfs -o subvol=/@,compress=zstd $ROOT_PART /mnt
    mount --mkdir -t btrfs -o subvol=/@home,compress=zstd $ROOT_PART /mnt/home
    mount --mkdir $EFI_PART /mnt/efi

else

    echo -e "${BLUE}=== Partitioning $DISK ===${NC}"

    echo -e "${YELLOW}Clearing disk partition table...${NC}"
    sgdisk --zap $DISK

    echo -e "${YELLOW}Waiting for kernel to reread partition table...${NC}"
    sleep 2

    echo -e "${YELLOW}Creating EFI partition (512MB)...${NC}"
    sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" $DISK

    echo -e "${YELLOW}Creating SWAP partition (${SWAP_SIZE_MB}M)...${NC}"
    sgdisk -n 2:0:+${SWAP_SIZE_MB}M -t 2:8200 -c 2:"SWAP" $DISK

    echo -e "${YELLOW}Creating ROOT partition...${NC}"
    sgdisk -n 3:0:0 -t 3:8300 -c 3:"ROOT" $DISK

    partprobe $DISK
    udevadm settle
    echo -e "${GREEN}Partition table created.${NC}"

    echo -e "\n${BOLD}${BLUE}─── Format & Mount ───${NC}"

    echo -e "${BLUE}=== Formatting partitions ===${NC}"
    echo -e "${YELLOW}Formatting EFI partition as FAT32...${NC}"
    mkfs.fat -F32 $DISK1
    echo -e "${GREEN}EFI partition formatted.${NC}"

    echo -e "${YELLOW}Formatting SWAP partition...${NC}"
    mkswap $DISK2
    echo -e "${GREEN}SWAP partition formatted.${NC}"

    echo -e "${YELLOW}Formatting ROOT partition as Btrfs...${NC}"
    mkfs.btrfs -f $DISK3
    echo -e "${GREEN}ROOT partition formatted.${NC}"

    echo -e "${YELLOW}Creating Btrfs subvolumes...${NC}"
    mount -t btrfs $DISK3 /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    umount /mnt
    echo -e "${GREEN}Btrfs subvolumes created (@ and @home).${NC}"

    echo -e "${BLUE}=== Mounting partitions ===${NC}"
    swapon $DISK2
    mount -t btrfs -o subvol=/@,compress=zstd $DISK3 /mnt
    mount --mkdir -t btrfs -o subvol=/@home,compress=zstd $DISK3 /mnt/home
    mount --mkdir $DISK1 /mnt/efi

fi

echo -e "\n${BOLD}${BLUE}─── Installing Base System ───${NC}"
echo -e "${GREEN}=== Installing base system ===${NC}"
if [[ $DUAL_BOOT == [Yy] ]]; then
    DUAL_PKGS="os-prober"
fi
pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware btrfs-progs \
    grub efibootmgr networkmanager sudo neovim $UCODE \
    zram-generator $DUAL_PKGS --noconfirm

echo -e "${GREEN}=== Generating fstab ===${NC}"
genfstab -U /mnt >>/mnt/etc/fstab

echo -e "\n${BOLD}${BLUE}─── System Config ───${NC}"
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

echo -e "${YELLOW}Setting hostname and hosts...${NC}"
arch-chroot /mnt /bin/bash -c "
    echo $HOSTNAME > /etc/hostname
    printf '127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$HOSTNAME\n' > /etc/hosts
"
echo -e "${GREEN}Hostname and hosts configured.${NC}"

echo -e "${YELLOW}Setting root password...${NC}"
arch-chroot /mnt /bin/bash -c "
    echo \"root:$PASSWORD\" | chpasswd
"
echo -e "${GREEN}Root password set.${NC}"

echo -e "${YELLOW}Creating user $USERNAME...${NC}"
arch-chroot /mnt /bin/bash -c "
    useradd -m -G wheel "$USERNAME"
    echo \"$USERNAME:$PASSWORD\" | chpasswd
"
echo -e "${GREEN}User $USERNAME created and added to wheel group.${NC}"

echo -e "${YELLOW}Configuring sudo...${NC}"
arch-chroot /mnt /bin/bash -c "
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
"
echo -e "${GREEN}Sudo configured for wheel group.${NC}"

echo -e "\n${BOLD}${BLUE}─── Bootloader ───${NC}"
echo -e "${YELLOW}Installing GRUB bootloader...${NC}"
if [[ $DUAL_BOOT == [Yy] ]]; then
    arch-chroot /mnt /bin/bash -c "
        grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Arch --recheck
        ln -s /efi/grub /boot/grub
    "
else
    GRUB_FLAGS="--target=x86_64-efi --efi-directory=/efi --boot-directory=/efi --recheck"
    if [[ $GRUB_REMOVABLE == [Yy] ]]; then
        GRUB_FLAGS="$GRUB_FLAGS --removable"
    else
        GRUB_FLAGS="$GRUB_FLAGS --bootloader-id=$GRUB_ID"
    fi
    arch-chroot /mnt /bin/bash -c "
        grub-install $GRUB_FLAGS
        ln -s /efi/grub /boot/grub
    "
fi
echo -e "${GREEN}GRUB installed.${NC}"

echo -e "\n${BOLD}${BLUE}─── Memory & Swap ───${NC}"
echo -e "${YELLOW}Configuring ZRAM...${NC}"
arch-chroot /mnt /bin/bash -c "
    echo -e '[zram0]\nzram-size = ram\ncompression-algorithm = zstd' > /etc/systemd/zram-generator.conf
"
echo -e "${GREEN}ZRAM configured.${NC}"

echo -e "${YELLOW}Resolving swap partition...${NC}"
udevadm settle
if [[ $DUAL_BOOT == [Yy] && -n "$SWAP_PART" ]]; then
    SWAP_UUID=$(blkid -s UUID -o value $SWAP_PART)
    GRUB_RESUME="resume=UUID=$SWAP_UUID"
    echo -e "Swap partition: ${YELLOW}$SWAP_PART (UUID: $SWAP_UUID)${NC}"
elif [[ $DUAL_BOOT == [Yy] ]]; then
    echo -e "${YELLOW}No swap partition, hibernation disabled.${NC}"
    GRUB_RESUME=""
else
    SWAP_UUID=$(blkid -s UUID -o value $DISK2)
    GRUB_RESUME="resume=UUID=$SWAP_UUID"
    echo -e "Swap partition: ${YELLOW}$DISK2 (UUID: $SWAP_UUID)${NC}"
fi
echo -e "${GREEN}Swap partition resolved.${NC}"

echo -e "\n${BOLD}${BLUE}─── Package Manager ───${NC}"
echo -e "${YELLOW}Configuring pacman and AUR helper...${NC}"
arch-chroot /mnt /bin/bash -c "
    sed -i 's/^#Color$/Color/' /etc/pacman.conf
    echo -e '[multilib]\nInclude = /etc/pacman.d/mirrorlist\n[archlinuxcn]\nSigLevel = Never\nServer = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch' >> /etc/pacman.conf
    pacman -Sy --noconfirm archlinux-keyring
    pacman -Syu --noconfirm
    pacman -S --noconfirm paru
    sed -i 's/^#BottomUp/BottomUp/' /etc/paru.conf
"
echo -e "${GREEN}Pacman and AUR helper configured.${NC}"

echo -e "\n${BOLD}${BLUE}─── Kernel & Boot Params ───${NC}"
echo -e "${YELLOW}Configuring GRUB parameters...${NC}"
if [[ $DUAL_BOOT == [Yy] ]]; then
    arch-chroot /mnt /bin/bash -c "
        echo 'EDITOR=nvim' >> /etc/environment
        sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"zswap.enabled=0 loglevel=5 $GRUB_RESUME\"/' /etc/default/grub
        sed -i '/^GRUB_DISABLE_OS_PROBER=/d' /etc/default/grub
        echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
    "
else
    arch-chroot /mnt /bin/bash -c "
        echo 'EDITOR=nvim' >> /etc/environment
        sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"zswap.enabled=0 loglevel=5 $GRUB_RESUME\"/' /etc/default/grub
    "
fi
echo -e "${GREEN}GRUB parameters optimized.${NC}"

echo -e "${YELLOW}Generating GRUB configuration...${NC}"
arch-chroot /mnt /bin/bash -c "
    grub-mkconfig -o /boot/grub/grub.cfg
"
echo -e "${GREEN}GRUB configuration generated.${NC}"

echo -e "${YELLOW}Adding resume hook and rebuilding initramfs...${NC}"
arch-chroot /mnt /bin/bash -c "
    sed -i 's/^HOOKS=(\(.*\) filesystems \(.*\))/HOOKS=(\1 filesystems resume \2)/' /etc/mkinitcpio.conf
    mkinitcpio -P
"
echo -e "${GREEN}Initramfs rebuilt with resume support.${NC}"

echo -e "${YELLOW}Enabling NetworkManager...${NC}"
arch-chroot /mnt /bin/bash -c "
    systemctl enable NetworkManager
"
echo -e "${GREEN}NetworkManager enabled.${NC}"

echo -e "\n${BOLD}${BLUE}─── Installation Complete ───${NC}"
echo -e "${YELLOW}=== Installation completed ===${NC}"
cp "$LOG_FILE" /mnt/root/install.log
umount -R /mnt
echo -e "${GREEN}Installation finished successfully!${NC}"

echo -e "${YELLOW}System will reboot in 10 seconds...${NC}"
echo -e "${YELLOW}Press Enter to reboot immediately, or press 'n' to cancel.${NC}"

for i in $(seq 10 -1 1); do
    echo -ne "\r${BLUE}Rebooting in $i seconds...${NC}"
    if read -t 1 -n 1 input; then
        if [[ -z "$input" ]]; then
            echo -e "\n${GREEN}Rebooting immediately...${NC}"
            reboot
        elif [[ "$input" == [Nn] ]]; then
            echo -e "\n${YELLOW}Reboot cancelled.${NC}"
            echo -e "${YELLOW}You can reboot manually by running 'reboot' command.${NC}"
            exit 0
        fi
    fi
done

echo -e "\n${GREEN}Rebooting now...${NC}"
reboot
