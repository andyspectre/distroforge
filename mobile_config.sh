#!/bin/bash

if [ -z "${SCRIPTS_DIR}" ]; then
    echo "SCRIPTS_DIR is not set. Skipping custom configuration."
    exit 1
fi

# Source the common distro utilities
. "${SCRIPTS_DIR}/distro_utils.sh"

# Install required packages and tools inside the container
install_applications() {
    echo "Installing applications inside the container..."

    case ${pkg_manager} in
    "apt")
        sudo apt update && sudo apt full-upgrade -y
        ;;
    "dnf")
        sudo dnf update -y
        ;;
    "pacman")
        sudo pacman -Syu --noconfirm
        sudo pacman -S --noconfirm \
            android-tools \
            scrcpy \
            usbmuxd \
            usbutils
        ;;
    *)
        echo "Error: Unknown package manager: ${pkg_manager}"
        exit 1
        ;;
    esac

    pipx install frida-tools objection
    pipx ensurepath
}


# Execute the configuration steps
install_applications


echo "Mobile configuration script finished."
