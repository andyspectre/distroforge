#!/bin/bash
# shellcheck disable=SC2034

distro=""
pkg_manager=""

if [ -z "${SCRIPTS_DIR}" ]; then
    echo "SCRIPTS_DIR is not set. Skipping custom configuration."
    exit 1
fi

# Source the common distro utilities
. "${SCRIPTS_DIR}/distro_utils.sh"

# Install required packages and tools inside the container
install_applications() {
    echo "Installing packages inside the container..."

    # Update package lists
    echo "Updating package lists"
    case ${pkg_manager} in
    "apt")
        sudo apt update && sudo apt full-upgrade -y

        # Install other packages
        sudo apt install -y \
            dconf-gsettings-backend \
            gsettings-desktop-schemas \
            libcanberra-gtk-module \
            libcanberra-gtk3-module \
            libglib2.0-bin \
            postgresql-common &&
            sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh &&
            sudo apt install -y postgresql
        ;;
    "dnf")
        sudo dnf update -y

        # Install other packages
        # TODO
        ;;
    "pacman")
        sudo pacman -Syu --noconfirm

        # Install other packages
        # TODO
        ;;
    *)
        echo "Error: Unknown package manager: ${pkg_manager}"
        exit 1
        ;;
    esac
}

start_postgresql() {
    # Enable PostgreSQL service
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
}

# Execute the configuration steps
install_applications
start_postgresql

echo "Postgresql configuration script finished."
