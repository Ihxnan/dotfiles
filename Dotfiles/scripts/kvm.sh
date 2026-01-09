#!/usr/bin/env bash

sudo pacman -Syu

sudo pacman -S qemu-full edk2-ovmf dnsmasq vde2 bridge-utils openbsd-netcat swtpm virt-manager virt-viewer libvirt libvirt-dbus ebtables iptables-nft

sudo systemctl enable --now libvirtd

sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

nmcli connection add type bridge ifname br0 con-name br0
nmcli connection add type bridge-slave ifname enp5s0 master br0

sudo systemctl restart NetworkManager

sudo virsh net-start default

sudo virsh net-autostart default
