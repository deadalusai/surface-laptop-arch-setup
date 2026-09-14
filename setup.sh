#!/usr/bin/env -S bash -e

# Cleaning the TTY.
clear

# Cosmetics (colours for text).
BOLD='\e[1m'
BRED='\e[91m'
BBLUE='\e[34m'  
BGREEN='\e[92m'
BYELLOW='\e[93m'
RESET='\e[0m'

# Pretty print (function).
info_print () {
    echo -e "${BOLD}${BGREEN}[ ${BYELLOW}•${BGREEN} ] $1${RESET}"
}

# Pretty print for input (function).
input_print () {
    echo -ne "${BOLD}${BYELLOW}[ ${BGREEN}•${BYELLOW} ] $1${RESET}"
}

# Alert user of bad input (function).
error_print () {
    echo -e "${BOLD}${BRED}[ ${BBLUE}•${BRED} ] $1${RESET}"
}

# Selecting a kernel to install (function).
kernel_selector () {
    info_print "List of kernels:"
    info_print "1) Surface: Linux kernel with patches applied to support Microsoft Surface hardware and firmware"
    info_print "2) Stable: Vanilla Linux kernel with a few specific Arch Linux patches applied"
    input_print "Please select the number of the corresponding kernel (e.g. 1): " 
    read -r kernel_choice
    case $kernel_choice in
        1 ) kernel="linux-surface"
            return 0;;
        2 ) kernel="linux"
            return 0;;
        * ) error_print "You did not enter a valid selection, please try again."
            return 1
    esac
}

disk_selector () {
    # Choosing the target for the installation.
    info_print "Available disks for the installation:"
    mapfile -t ARR < <(lsblk -dpno NAME,SIZE,MODEL | grep -P "/dev/sd|nvme|vd");
    PS3="Please select the number of the corresponding disk (e.g. 1): "
    select ENTRY in "${ARR[@]}";
    do
        DISK="$(echo "$ENTRY" | awk '{print $1;}')"
        info_print "Arch Linux will be installed on the following disk: $DISK"
        break
    done
}

# Setting up a password for the user account (function).
userpass_selector () {
    input_print "Please enter name for a user account (enter empty to not create one): "
    read -r username
    if [[ -z "$username" ]]; then
        return 0
    fi
    input_print "Please enter a password for $username: "
    read -r -s userpass
    if [[ -z "$userpass" ]]; then
        echo
        error_print "You need to enter a password for $username, please try again."
        return 1
    fi
    echo
    input_print "Please enter the password again: " 
    read -r -s userpass2
    echo
    if [[ "$userpass" != "$userpass2" ]]; then
        echo
        error_print "Passwords don't match, please try again."
        return 1
    fi
    return 0
}

# Setting up a password for the root account (function).
rootpass_selector () {
    input_print "Please enter a password for the root user: "
    read -r -s rootpass
    if [[ -z "$rootpass" ]]; then
        echo
        error_print "You need to enter a password for the root user, please try again."
        return 1
    fi
    echo
    input_print "Please enter the password again: " 
    read -r -s rootpass2
    echo
    if [[ "$rootpass" != "$rootpass2" ]]; then
        error_print "Passwords don't match, please try again."
        return 1
    fi
    return 0
}

# Determine if the user wants to enable secure boot
secureboot_selector () {
    input_print "Enable Secure Boot (Microsoft signing keys)? [y/N]: "
    read -r secureboot_response
    if ! [[ "$secureboot_response" =~ ^(yes|y)$ ]]; then
        secureboot_response = 'yes'
        exit
    fi
}

# Microcode detector (function).
microcode_detector () {
    CPU=$(grep vendor_id /proc/cpuinfo)
    if [[ "$CPU" == *"AuthenticAMD"* ]]; then
        info_print "An AMD CPU has been detected, the AMD microcode will be installed."
        microcode="amd-ucode"
    else
        info_print "An Intel CPU has been detected, the Intel microcode will be installed."
        microcode="intel-ucode"
    fi
}

# User enters a hostname (function).
hostname_selector () {
    input_print "Please enter the hostname: "
    read -r hostname
    if [[ -z "$hostname" ]]; then
        error_print "You need to enter a hostname in order to continue."
        return 1
    fi
    return 0
}

# User chooses the locale (function).
locale_selector () {
    input_print "Please insert the locale you use (format: xx_XX. Enter empty to use en_US, or \"/\" to search locales): " locale
    read -r locale
    case "$locale" in
        '') locale="en_US.UTF-8"
            info_print "$locale will be the default locale."
            return 0;;
        '/') sed -E '/^# +|^#$/d;s/^#| *$//g;s/ .*/ (Charset:&)/' /etc/locale.gen | less -M
                clear
                return 1;;
        *)  if ! grep -q "^#\?$(sed 's/[].*[]/\\&/g' <<< "$locale") " /etc/locale.gen; then
                error_print "The specified locale doesn't exist or isn't supported."
                return 1
            fi
            return 0
    esac
}

# User chooses the console keyboard layout (function).
keyboard_selector () {
    input_print "Please insert the keyboard layout to use in console (Enter empty to use US, or \"/\" to look up for keyboard layouts): "
    read -r kblayout
    case "$kblayout" in
        '') kblayout="us"
            info_print "The standard US keyboard layout will be used."
            return 0;;
        '/') localectl list-keymaps
             clear
             return 1;;
        *) if ! localectl list-keymaps | grep -Fxq "$kblayout"; then
               error_print "The specified keymap doesn't exist."
               return 1
           fi
        info_print "Changing console layout to $kblayout."
        loadkeys "$kblayout"
        return 0
    esac
}

# Welcome screen.
echo -ne "${BOLD}${BYELLOW}
================================================================================================ 
      ___           ___           ___           ___         ___           ___           ___      
     /  /\         /__/\         /  /\         /  /\       /  /\         /  /\         /  /\     
    /  /:/_        \  \:\       /  /::\       /  /:/_     /  /::\       /  /:/        /  /:/_    
   /  /:/ /\        \  \:\     /  /:/\:\     /  /:/ /\   /  /:/\:\     /  /:/        /  /:/ /\   
  /  /:/ /::\   ___  \  \:\   /  /:/~/:/    /  /:/ /:/  /  /:/~/::\   /  /:/  ___   /  /:/ /:/_  
 /__/:/ /:/\:\ /__/\  \__\:\ /__/:/ /:/___ /__/:/ /:/  /__/:/ /:/\:\ /__/:/  /  /\ /__/:/ /:/ /\ 
 \  \:\/:/~/:/ \  \:\ /  /:/ \  \:\/:::::/ \  \:\/:/   \  \:\/:/__\/ \  \:\ /  /:/ \  \:\/:/ /:/ 
  \  \::/ /:/   \  \:\  /:/   \  \::/~~~~   \  \::/     \  \::/       \  \:\  /:/   \  \::/ /:/  
   \__\/ /:/     \  \:\/:/     \  \:\        \  \:\      \  \:\        \  \:\/:/     \  \:\/:/   
     /__/:/       \  \::/       \  \:\        \  \:\      \  \:\        \  \::/       \  \::/    
     \__\/         \__\/         \__\/         \__\/       \__\/         \__\/         \__\/    
================================================================================================ 
${RESET}"

# Setting up keyboard layout.
until keyboard_selector; do : ; done

# Select the installation disk
disk_selector

# Setting up the kernel.
until kernel_selector; do : ; done

# Select whether to enable secure boot
secureboot_selector

# User choses the locale.
until locale_selector; do : ; done

# User choses the hostname.
until hostname_selector; do : ; done

# User sets up the user/root passwords.
until userpass_selector; do : ; done
until rootpass_selector; do : ; done

# Warn user about deletion of old partition scheme.
input_print "This will delete the current partition table on $DISK once installation starts. Continue? [y/N]: "
read -r disk_response
if ! [[ "${disk_response,,}" =~ ^(yes|y)$ ]]; then
    error_print "Quitting."
    exit
fi
info_print "Wiping $DISK."
wipefs -af "$DISK" &>/dev/null
sgdisk -Zo "$DISK" &>/dev/null

# Creating new partitions
BOOT_PART_END="$(( 1024 + 1 ))MiB"
SWAP_PART_END="$(( 4096 + 1024 + 1 ))MiB"

info_print "Creating the partitions on $DISK."
parted -s "$DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB "$BOOT_PART_END" \
    set 1 esp on \
    mkpart SWAP linux-swap "$BOOT_PART_END" "$SWAP_PART_END" \
    mkpart ROOTFS "$SWAP_PART_END" 100%

ESP="/dev/disk/by-partlabel/ESP"
SWAP="/dev/disk/by-partlabel/SWAP"
ROOTFS="/dev/disk/by-partlabel/ROOTFS"

info_print "Informing the Kernel about the disk changes."
partprobe "$DISK"

info_print "Formatting the EFI Partition (FAT32)."
mkfs.fat -F 32 "$ESP"

info_print "Formatting the Swap Partition."
mkswap "$SWAP"

info_print "Formatting the Root Partition (ext4)."
mkfs.ext4 "$ROOTFS"

# Mounting the filesystem
info_print "Mounting the filesystems"
mount "$ROOTFS" /mnt
mount "$ESP"    /mnt/boot/ --mkdir -o "fmask=0137,dmask=0027"
swapon "$SWAP"

# Checking the microcode to install.
microcode_detector

base_packages=(
    base
    "$kernel"
    "$kernel"-headers
    linux-firmware
    "$microcode"
    networkmanager
    plymouth
    msedit
    sudo
)

if [[ $secureboot_response = yes ]]; then
    base_packages+=(sbctl)
fi

if [[ "$kernel" == "linux-surface" ]]; then
    info_print "Adding linux-surface kernel repository."
    curl -s https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc | pacman-key --add -
    
    info_print "Verifying the linux-surface kernel signing key fingerprint."
    pacman-key --finger 56C464BAAC421453
    
    info_print "Signing the linux-surface kernel signing key locally."
    pacman-key --lsign-key 56C464BAAC421453
    
    info_print "Updating /etc/pacman.conf and refreshing metadata."
    cat >> /etc/pacman.conf <<EOF

[linux-surface]
Server = https://pkg.surfacelinux.com/arch/
EOF
    base_packages+=(iptsd libcamera libcamera-tools)
fi

# Pacstrap (setting up a base sytem onto the new root).
info_print "Installing the base system (${base_packages[@]})"
pacstrap -K /mnt ${base_packages[@]}

# Setting up the hostname.
info_print "Setting hostname."
echo "$hostname" > /mnt/etc/hostname

# Generating /etc/fstab.
info_print "Generating a new fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Configure selected locale and console keymap for UTF-8
echo "$locale.UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo "LANG=$locale" > /mnt/etc/locale.conf
cat > /mnt/etc/vconsole.conf <<EOF
KEYMAP=$kblayout
EOF

# Setting up the network.
info_print "Installing and enabling NetworkManager."
systemctl enable NetworkManager --root=/mnt &>/dev/null

# Setting up DNS
info_print "Setting systemd-resolvd as DNS resolver"
systemctl enable systemd-resolved --root=/mnt &>/dev/null
cat > /mnt/etc/NetworkManager/conf.d/dns.conf <<EOF
[main]
dns=systemd-resolved
EOF

# Setting up bluetooth
info_print "Enabling Bluetooth."
systemctl enable bluetooth --root=/mnt &>/dev/null

# Configuring /etc/mkinitcpio.conf.
info_print "Configuring /etc/mkinitcpio.conf."
cat > /mnt/etc/mkinitcpio.conf <<EOF
HOOKS=(base systemd plymouth autodetect microcode modconf kms keyboard sd-vconsole block filesystems fsck)
EOF

# Configuring the system.
info_print "Configuring the system (timezone, system clock, initramfs)."
arch-chroot /mnt /bin/bash -e <<EOF
# Regenerate initramfs
mkinitcpio -P

# Set up msedit as "edit"
ln -sf /usr/bin/msedit /usr/bin/edit

# Setting up timezone.
ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime &>/dev/null

# Setting up clock.
hwclock --systohc

# Generating locales.
locale-gen &>/dev/null
EOF

# Configuring the boot loader
info_print "Configuring the boot loader (systemd-boot)."
arch-chroot -S /mnt /bin/bash -e <<EOF
# Installing systemd-boot.
bootctl install

cat > /boot/loader/loader.conf <<TEXT
default arch
timeout 0
console-mode max
TEXT

cat > /boot/loader/entries/arch.conf <<TEXT
title Arch (${kernel})
linux /vmlinuz-${kernel}
initrd /${microcode}.img
initrd /initramfs-${kernel}.img
options root=PARTUUID=$(blkid -s PARTUUID -o value "$ROOTFS") rw loglevel=3 quiet splash
TEXT
EOF


if [[ $secureboot_response = yes ]]; then
    
# Configuring secure boot
info_print "Setting up Secure Boot"
arch-chroot -S /mnt /bin/bash -e <<EOF
# Enroll secure boot keys
sbctl create-keys
sbctl enroll-keys --microsoft
# Sign boot images
sbctl sign /boot/EFI/BOOT/BOOTX64.EFI
sbctl sign /boot/EFI/systemd/systemd-bootx64.efi
sbctl sign /boot/vmlinuz-${kernel}
EOF

fi

# Setting root password.
info_print "Setting root password."
echo "root:$rootpass" | arch-chroot /mnt chpasswd

# Setting user password.
if [[ -n "$username" ]]; then
    info_print "Adding the user $username to the system with root privilege."
    echo "%wheel ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/wheel
    arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$username"
    info_print "Setting user password for $username."
    echo "$username:$userpass" | arch-chroot /mnt chpasswd
fi

# Pacman eye-candy features.
info_print "Enabling colours, animations, and parallel downloads for pacman."
sed -Ei 's/^#(Color)$/\1\nILoveCandy/;s/^#(ParallelDownloads).*/\1 = 10/' /mnt/etc/pacman.conf

# Finishing up.
info_print "Done, you may now wish to reboot (further changes can be done by arch-chroot'ing into /mnt)."
exit
