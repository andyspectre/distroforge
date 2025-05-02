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
            maven
        ;;
    "dnf")
        sudo dnf update -y

        # Install other packages
        sudo dnf install -y \
            maven
        ;;
    "pacman")
        sudo pacman -Syu --noconfirm

        # Install other packages
        sudo pacman -S --noconfirm \
            maven
        ;;
    *)
        echo "Error: Unknown package manager: ${pkg_manager}"
        exit 1
        ;;
    esac

}

# Configure the evironment
java_env_config() {
    echo "Configuring environment..."
    # Download and install JDK 21 LTS from Adoptium
    echo "Downloading and installing JDK 21 LTS from Adoptium..."
    curl -fLO https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.6%2B7/OpenJDK21U-jdk_x64_linux_hotspot_21.0.6_7.tar.gz && tar -xf OpenJDK21U-jdk_x64_linux_hotspot_21.0.6_7.tar.gz && sudo mv jdk-21.0.6+7 /opt/
    # Set JAVA_HOME and PATH
    echo "Setting JAVA_HOME and PATH..."
    if [ -f "${HOME}.bashrc" ]; then
        echo "export JAVA_HOME=/opt/jdk-21.0.6+7" >>~/.bashrc
        echo "export PATH=\$PATH:\$JAVA_HOME/bin" >>~/.bashrc

    elif [ -f "${HOME}.zshrc" ]; then
        echo "export JAVA_HOME=/opt/jdk-21.0.6+7" >>~/.zshrc
        echo "export PATH=\$PATH:\$JAVA_HOME/bin" >>~/.zshrc
    else
        echo "No .bashrc or .zshrc file found in home directory. JAVA_HOME and PATH not set."
    fi

}

# Create IntelliJ IDEA desktop entry and export the app
idea_config() {
    # Install IntelliJ IDEA Community Edition
    echo "Installing IntelliJ IDEA Community Edition..."
    curl -fLO https://download.jetbrains.com/idea/ideaIC-2025.1.tar.gz && tar -xf ideaIC-2025.1.tar.gz && sudo mv idea-IC-251.23774.435 /opt/ && sudo ln -s /opt/idea-IC-251.23774.435/bin/idea /usr/local/bin/idea

    # Create applications directory if it doesn't exist
    if [ ! -d ~/.local/share/applications ]; then
        mkdir -p ~/.local/share/applications
    fi
    # Create the desktop entry for IntelliJ IDEA
    # Check if the desktop entry already exists
    if [ -f ~/.local/share/applications/idea.desktop ]; then
        echo "IntelliJ IDEA desktop entry already exists. Skipping creation."
    else
        echo "Creating IntelliJ IDEA desktop entry..."
        cat <<EOF >~/.local/share/applications/idea.desktop
[Desktop Entry]
Name=IntelliJ IDEA
GenericName=Java IDE
Exec=idea %U
Icon=/opt/idea-IC-251.23774.435/bin/idea.png
Type=Application
StartupNotify=false
StartupWMClass=jetbrains-idea-ce
Categories=TextEditor;Development;IDE;
MimeType=application/x-code-workspace;
Actions=new-empty-window;
Keywords=idea;
EOF
    fi

    echo "Exporting IntelliJ IDEA app..."
    distrobox-export --app idea
}

# Execute the configuration steps
install_applications
java_env_config
idea_config

echo "Java configuration script finished."
