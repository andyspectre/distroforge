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
        sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install \
            dconf-gsettings-backend \
            ffuf \
            gsettings-desktop-schemas \
            iproute2 \
            iptables \
            kali-linux-headless \
            libcanberra-gtk3-module \
            libglib2.0-bin \
            nuclei \
            openconnect \
            openresolv \
            pipx \
            seclists \
            testssl.sh \
            wireguard

        ;;
    "dnf")
        echo "Sorry, this script is only compatible with kali-rolling."
        exit 1
        ;;
    "pacman")
        echo "Sorry, this script is only compatible with kali-rolling."
        exit 1
        ;;
    *)
        echo "Error: Unknown package manager: ${pkg_manager}"
        exit 1
        ;;
    esac

    sudo pipx install "vpn-slice[dnspython,setproctitle]"
    sudo pipx ensurepath
}

install_burp() {
    echo "Installing Burp Suite..."
    # Make sure to download Burp within the container home directory
    cd "${HOME}" || return
    # Download and install Burp Suite
    curl -fLo "BurpSuitePro" "https://portswigger.net/burp/releases/download?product=pro&version=2025.3.2&type=linux"
    chmod +x BurpSuitePro
    sudo DEBIAN_FRONTEND=noninteractive ./BurpSuitePro

    # Create applications directory if it doesn't exist
    if [ ! -d ~/.local/share/applications ]; then
        mkdir -p ~/.local/share/applications
    fi

    # Create a desktop entry for Burp Suite
    if [ -f ~/.local/share/applications/BurpSuitePro.desktop ]; then
        echo "Burp Suite desktop entry already exists. Skipping creation."
    else
        cat <<EOF >~/.local/share/applications/BurpSuitePro.desktop
[Desktop Entry]
Type=Application
Name=Burp Suite Professional
Exec="/opt/BurpSuitePro/BurpSuitePro" %U
Icon=/opt/BurpSuitePro/.install4j/BurpSuitePro.png
Categories=Application;
StartupWMClass=install4j-burp-StartBurp
EOF
    fi

    # Create a desktop entry for Burp Chromium
    if [ -f ~/.local/share/applications/ChromiumBurp.desktop ]; then
        echo "Burp Chromium desktop entry already exists. Skipping creation."
    else
        cat <<EOF >~/.local/share/applications/ChromiumBurp.desktop
        [Desktop Entry]
Version=1.0
Name=Chromium Web Browser
GenericName=Web Browser
Exec=/usr/bin/chromium %U
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=chromium
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml_xml;application/x-mimearchive;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=chromium-browser
StartupNotify=true
Keywords=browser
EOF
    fi

    # Download Jython
    curl -fLO "https://repo1.maven.org/maven2/org/python/jython-standalone/2.7.4/jython-standalone-2.7.4.jar"

    echo "Exporting Burp Suite Pro app..."
    distrobox-export --app BurpSuitePro

    echo "Exporting Burp Chromium app..."
    distrobox-export --app chromium

}

# Execute the configuration steps
install_applications
install_burp

echo "Kali configuration script finished."
