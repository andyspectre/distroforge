#!/bin/bash
# Common utility functions shared between scripts

distro=""
pkg_manager=""
shell_config_file=""


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

# Function to determine the shell profile
get_shell_config_file() {
    # Check current shell environment first
    if [ -n "${ZSH_VERSION}" ]; then
        shell_config_file="${HOME}/.zshrc"
    elif [ -n "${BASH_VERSION}" ]; then
        shell_config_file="${HOME}/.bashrc"
    else
        # Fallback to $SHELL if environment vars not set
        case "$(basename "${SHELL}")" in
            zsh)  shell_config_file="${HOME}/.zshrc" ;;
            bash) shell_config_file="${HOME}/.bashrc" ;;
            *)    shell_config_file="${HOME}/.profile" ;;
        esac
    fi
}

set_pkg_manager
get_shell_config_file

# Export variables to make them available to sourcing scripts
export pkg_manager
export distro
export shell_config_file
