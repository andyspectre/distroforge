#!/bin/bash

if [ -z "${SCRIPTS_DIR}" ]; then
    echo "SCRIPTS_DIR is not set. Skipping custom configuration."
    exit 1
fi

# Source the common distro utilities
. "${SCRIPTS_DIR}/distro_utils.sh"

# Configure system locales
configure_locales() {
    echo "Configuring locales..."

    case ${pkg_manager} in
    "apt")
        # Install locales package and locales-all (precompiled)
        sudo apt install -y locales locales-all
        # Ensure the en_US.UTF-8 locale is uncommented
        sudo sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
        # Generate the locale
        sudo locale-gen
        # Set system-wide default locale (ALL categories to en_US.UTF-8)
        echo 'LANG=en_US.UTF-8' | sudo tee /etc/default/locale
        echo 'LC_ALL=en_US.UTF-8' | sudo tee -a /etc/default/locale
        ;;
    "dnf")
        # Configure locales for Fedora/RHEL
        echo "Configuring locales for Fedora/RHEL..."
        # TODO
        ;;
    "pacman")
        # Configure locales for Arch/Manjaro
        echo "Configuring locales for Arch/Manjaro..."
        # TODO
        ;;
    *)
        echo "Error: Unknown package manager: ${pkg_manager}"
        return 1
        ;;
    esac

    # Add locale settings to shell config if not already present
    for setting in "export LANG=en_US.UTF-8" "export LC_ALL=en_US.UTF-8" "export PERL_UNICODE=S"; do
        if ! grep -q "^${setting}$" "${shell_config_file}"; then
            echo "${setting}" >>"${shell_config_file}"
        fi
    done

    echo "Locale configuration completed"
}

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
            curl \
            file \
            git \
            pipx \
            shellcheck \
            shfmt \
            stow \
            tmux \
            vim-gtk3 \
            xclip \
            zsh
        ;;
    "dnf")
        sudo dnf update -y

        # Install other packages
        sudo dnf install -y \
            curl \
            file \
            git \
            pipx \
            shellcheck \
            shfmt \
            stow \
            tmux \
            vim-X11 \
            xclip \
            zsh
        ;;
    "pacman")
        sudo pacman -Syu --noconfirm

        # Install other packages
        sudo pacman -S --noconfirm \
            base-devel \
            curl \
            git \
            gvim \
            python-pipx \
            shellcheck \
            shfmt \
            stow \
            tmux \
            which \
            xclip \
            zsh
        # Install yay for AUR packages
        echo "Installing yay for AUR packages..."
        cd "${HOME}" || return
        git clone https://aur.archlinux.org/yay.git
        cd yay || return
        makepkg -si --noconfirm
        ;;
    *)
        echo "Error: Unknown package manager: ${pkg_manager}"
        exit 1
        ;;
    esac

    # Install Oh My Zsh
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Install pipx applications
    echo "Installing pipx applications..."
    pipx install bashate
    pipx ensurepath
}

# Configure the evironment
configure_environment() {
    echo "Configuring environment..."

    # Set zsh as default shell
    echo "Setting zsh as default shell..."
    sudo chsh -s /usr/bin/zsh "${USER}"

    # Setup dotfile
    echo "Setting up dotfiles and configuration files..."
    if [ -z "${dotfiles_path}" ]; then
        echo "dotfiles_path is not set. Skipping dotfiles configuration."
        return
    else
        echo "Preparing to stow dotfiles from ${dotfiles_path}"
        # Backup config files, to avoid getting conflicts with stow, especially during first installation when .zshrc or .bashrc are not yet managed by stow.
        for config in .bashrc .tmux.conf .vimrc .zshrc; do
            # If it is a regular file and not a symlink, back it up
            if [ -f "${HOME}/${config}" ] && [ ! -L "${HOME}/${config}" ]; then
                echo "Backing up ${config}"
                i=0
                while [ -e "${HOME}/${config}.bak$(printf "%02d" "${i}")" ]; do
                    i=$((i + 1))
                done
                mv "${HOME}/${config}" "${HOME}/${config}.bak$(printf "%02d" "${i}")"
            fi
            # Stow automatically handles files that it maneges, but we are not sure if these symlinks are actually managed by stow, so we remove them
            if [ -L "${HOME}/${config}" ]; then
                echo "Removing symlink ${config}"
                rm "${HOME}/${config}"
            fi
        done

        cd "${dotfiles_path}" || exit
        # Check if files to be stowed exist
        for config in bash zsh vim tmux; do
            if [ ! -d "${dotfiles_path}/${config}" ]; then
                echo "Directory ${dotfiles_path}/${config} does not exist. Skipping stow for ${config}."
                continue
            fi
            stow -t "${HOME}" "${config}"
            echo "Stowed ${config} configuration files."
        done
        echo "Dotfiles and configuration files set up successfully."

    fi
}

install_vim_plug() {
    echo "Installing vim-plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    # Install the plugins defined in vimrc
    if [ "${distro}" = "arch" ]; then
        gvim +PlugInstall +qall
    elif [ "${distro}" = "ubuntu" ] || [ "${distro}" = "debian" ] || [ "${distro}" = "kali" ]; then
        vim +PlugInstall +qall
    elif [ "${distro}" = "fedora" ] || [ "${distro}" = "rhel" ]; then
        vimx +PlugInstall +qall
    else
        echo "Error: Unsupported distribution for vim-plug installation."
        exit 1
    fi
}

# Execute the configuration steps
configure_locales
install_applications
configure_environment
install_vim_plug

echo "Common configuration script finished."
