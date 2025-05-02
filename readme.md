# Distroforge

A collection of shell scripts to forge [Distrobox](https://github.com/89luca89/distrobox) containers with specific development environments and tools. Totally a work in progress.

## Features

- Automated container creation from `distrobox.ini` configurations
- Tag-based container configuration (Java, PostgreSQL, Kali Linux, etc.)
- Common development tools installation across containers
- Dotfiles management and configuration using GNU Stow
- Support for multiple Linux distributions (Debian/Ubuntu, Fedora, Arch Linux)

## Prerequisites

- Distrobox installed on your system
- Bash shell
- sudo privileges
- GNU Stow (for dotfiles management)

## Installation

Clone this repository:

```bash
git clone https://github.com/andyspectre/distroforge.git
cd distroforge
```

## Usage
Create and configure all containers defined in the local distrobox.ini:

```
./distroforge.sh
```

Create and configure a specific container:

```
./distroforge.sh --name <container_name>
```

Use a different distrobox.ini file:

```
./distroforge.sh --name <container_name> --file /path/to/distrobox.ini
```

Configure the container with your dotfiles:

```
./distroforge.sh --name <container_name> --dotfiles /path/to/dotfiles
```

The dotfiles should be somewhere on your host, and the structure should be something like this (if unclear check this resource: https://brandon.invergo.net/news/2012-05-26-using-gnu-stow-to-manage-your-dotfiles.html):

```
dotfiles/
├── bash/
│   └── .bashrc
├── vim/
│   └── .vimrc
├── tmux/
│   └── .tmux.conf
└── zsh/
    └── .zshrc
```

## Container Tags
Containers can be tagged in distrobox.ini to receive specific configurations. Just add the tags you want to a container and run distroforge.sh against your distrobox ini. 

For example:

```
# tags: generic java
[javadev-distrobox]
home="${HOME}"/Distrobox/javadev-distrobox
hostname="$(uname -n)"
image=quay.io/toolbx-images/debian-toolbox:12
additional_flags="-p=8200-8300:8200-8300 -p 5005:5005 -p 9010:9010"
replace=true
start_now=true
```

Available tags at the moment:

- `generic`: Basic development tools and shell configuration
- `java`: Java development environment with JDK and IntelliJ IDEA
- `kali`: Kali Linux with additional security tools
- `mobile`: Android development and reverse engineering tools
- `postgresql`: PostgreSQL database server

### Generic

Takes care of generic configurations like locales, dotfiles, shell and it installs these apps:

- bashate
- curl
- file
- git
- ohmyzsh
- pipx
- shellcheck
- shfmt
- stow
- tmux
- vim-gtk3
- vim-plug
- xclip
- yay
- zsh

### Java

It sets up a Java development environment and exports Intellij IDEA so that is available on the host app menu.

- dconf-gsettings-backend
- gsettings-desktop-schemas
- libcanberra-gtk-module
- libcanberra-gtk3-module
- libglib2.0-bin
- maven
- Adoptium Temurin JDK21
- IntelliJ IDEA Community Edition

### Kali

Will export Burp Pro so that is available on the host app menu.

- Burp Suite Pro
- dconf-gsettings-backend
- ffuf
- gsettings-desktop-schemas
- iproute2
- iptables
- jython
- kali-linux-headless
- libcanberra-gtk3-module
- libglib2.0-bin
- nuclei
- openconnect
- openresolv
- pipx
- seclists
- testssl.sh
- vpn-slice
- wireguard

### Mobile

- android-tools
- scrcpy
- usbmuxd
- usbutils
- frida-tools
- objection

### Postgresql

- dconf-gsettings-backend
- gsettings-desktop-schemas
- libcanberra-gtk-module
- libcanberra-gtk3-module
- libglib2.0-bin
- postgresql
- postgresql-common
