#!/bin/bash
# Common utility functions shared between scripts

distro=""
pkg_manager=""


# Check the linux distribution and set the package manager
set_pkg_manager() {
    if [ -f /etc/os-release ]; then
        distro=$(grep -E "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
        case ${distro} in
        "ubuntu" | "debian" | "kali")
            pkg_manager="apt"
            ;;
        "fedora" | "rhel")
            pkg_manager="dnf"
            ;;
        "arch" | "manjaro")
            pkg_manager="pacman"
            ;;
        *)
            echo "Unsupported distribution: ${distro}"
            exit 1
            ;;
        esac
        echo "${pkg_manager}"
    else
        echo "Cannot determine distribution"
        exit 1
    fi
}

set_pkg_manager

# Export variables to make them available to sourcing scripts
export pkg_manager
export distro
