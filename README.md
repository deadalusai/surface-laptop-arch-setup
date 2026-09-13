# Arch Setup Script for Surface Devices

Based primarily on [easy-arch](https://github.com/classy-giraffe/easy-arch) is a **bash script** that
boostraps [Arch Linux](https://archlinux.org/). Check there for updates.

This script originally written to set up an AMD Surface Laptop 3 with Arch, Gnome, and some default programs.

Easy Arch sets a more secure system by default (BTRFS, LUKS2 Encryption), so re-consider that next time.

## Usage

1. Boot an Arch Live environment.
2. Run `bash <(curl -q https://raw.githubusercontent.com/deadalusai/surface-laptop-arch-setup/refs/heads/master/setup.sh)`.
3. Follow the instructions.
4. Reboot with `reboot`.

## Filesystem

This script sets up an `ext4` root filesystem with a `Fat32`-formatted EFI boot partition and a swap partition.

## Core Software

This script is trimmed down to install and configure a specific software set:

- *Kernel*
  This script installs the [surface-linux](https://github.com/linux-surface/linux-surface) kernel which 
  includes patches to support Surface devices. It also installs the standard Arch Linux kernel as a fallback option.
    
- *Boot Manager*
  This script installs [systemd-boot](https://wiki.archlinux.org/title/Systemd-boot) as the boot manager.
  It also installs [plymouth](https://wiki.archlinux.org/title/Plymouth) for a nice boot splash-screen experience.
  
- *Networking*
  This script installs [Network Manager](https://wiki.archlinux.org/title/NetworkManager).
  It also configures systemd-resolved as the [default DNS resolver](https://wiki.archlinux.org/title/NetworkManager#systemd-resolved) (Þ)

(Þ) This works around an issue with gpg being unable to resolve DNS queries due to relying directly on `/etc/resolv.conf`.

## Desktop Experience

This script installs the latest Gnome DE, with some unwanted packages removed and some custom configurations pre-applied.

## User Software

This script also installs the following user software:

- *1Password* [Flathub](https://flathub.org/en/apps/com.onepassword.OnePassword)
- *Dropbox*   [Flathub](https://flathub.org/en/apps/com.dropbox.Client)
- *MS Edit*   [Github](https://github.com/microsoft/edit)