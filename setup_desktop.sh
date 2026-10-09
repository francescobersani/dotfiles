#!/bin/bash

################################################################################
# Desktop Setup Script for Fedora
#
# This script installs and configures common tools and applications
# for a desktop environment on Fedora Linux.
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

################################################################################
# Print functions
################################################################################

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

################################################################################
# Desktop Tool Installation Functions
################################################################################

install_development_tools() {
    print_header "Installing Development Tools"
    
    local tools=(
        "git:git"
        "curl:curl"
        "wget:wget"
        "vim:vim"
        "neovim:nvim"
        "htop:htop"
        "tmux:tmux"
        "net-tools:netstat"
        "jq:jq"
    )
    
    local to_install=()
    
    for entry in "${tools[@]}"; do
        local pkg="${entry%%:*}"
        local cmd="${entry##*:}"
        
        if ! command -v "$cmd" &> /dev/null && ! rpm -q "$pkg" &> /dev/null 2>&1; then
            to_install+=("$pkg")
        else
            print_info "$pkg already installed"
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        print_info "Installing missing tools: ${to_install[*]}"
        sudo dnf install -y --quiet "${to_install[@]}" || print_warning "Some tools failed to install"
    else
        print_info "All development tools are already installed"
    fi
    
    print_success "Development tools installation completed"
}

install_terminal_utilities() {
    print_header "Installing Terminal Utilities"
    
    local utils=(
        "fzf:fzf"
        "ripgrep:rg"
        "bat:bat"
        "fd:fd"
        "exa:exa"
        "tree:tree"
    )
    
    local to_install=()
    
    for entry in "${utils[@]}"; do
        local pkg="${entry%%:*}"
        local cmd="${entry##*:}"
        
        if ! command -v "$cmd" &> /dev/null && ! rpm -q "$pkg" &> /dev/null 2>&1; then
            to_install+=("$pkg")
        else
            print_info "$pkg already installed"
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        print_info "Installing missing utilities: ${to_install[*]}"
        sudo dnf install -y --quiet "${to_install[@]}" || print_warning "Some utilities failed to install"
    else
        print_info "All terminal utilities are already installed"
    fi
    
    print_success "Terminal utilities installation completed"
}

install_languages_and_runtimes() {
    print_header "Installing Programming Languages and Runtimes"
    
    local runtimes=(
        "python3:python3"
        "python3-pip:pip3"
        "nodejs:node"
        "go:go"
        "rust-toolset:rustc"
    )
    
    local to_install=()
    
    for entry in "${runtimes[@]}"; do
        local pkg="${entry%%:*}"
        local cmd="${entry##*:}"
        
        if ! command -v "$cmd" &> /dev/null 2>&1 && ! rpm -q "$pkg" &> /dev/null 2>&1; then
            to_install+=("$pkg")
        else
            print_info "$pkg already installed"
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        print_info "Installing missing runtimes: ${to_install[*]}"
        sudo dnf install -y --quiet "${to_install[@]}" || print_warning "Some runtimes failed to install"
    else
        print_info "All programming languages and runtimes are already installed"
    fi
    
    print_success "Programming languages and runtimes installation completed"
}

install_gui_applications() {
    print_header "Installing GUI Applications"
    
    local apps=(
        "firefox"      # Web browser
        "vlc"          # Media player
        "gedit"        # Text editor
        "nautilus"     # File manager
        "evince"       # PDF viewer
    )
    
    local to_install=()
    
    for app in "${apps[@]}"; do
        if ! rpm -q "$app" &> /dev/null 2>&1; then
            to_install+=("$app")
        else
            print_info "$app already installed"
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        print_info "Installing missing applications: ${to_install[*]}"
        sudo dnf install -y --quiet "${to_install[@]}" || print_warning "Some applications failed to install"
    else
        print_info "All GUI applications are already installed"
    fi
    
    print_success "GUI applications installation completed"
}

install_docker() {
    print_header "Installing Docker"
    
    if command -v docker &> /dev/null; then
        print_info "Docker is already installed"
        docker --version
        
        if sudo systemctl is-active --quiet docker; then
            print_info "Docker daemon is running"
        else
            print_info "Starting Docker daemon..."
            sudo systemctl start docker
        fi
        
        # Check if user is in docker group
        if groups "$(whoami)" | grep -q docker; then
            print_info "User is already in docker group"
        else
            print_warning "Adding user to docker group..."
            sudo usermod -aG docker "$(whoami)"
            print_warning "You need to log out and back in for group changes to take effect"
        fi
        
        return 0
    fi
    
    print_info "Installing Docker..."
    sudo dnf install -y --quiet dnf-plugins-core
    
    if ! grep -q "docker-ce" /etc/yum.repos.d/*.repo 2>/dev/null; then
        print_info "Adding Docker repository..."
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    else
        print_info "Docker repository already configured"
    fi
    
    sudo dnf install -y --quiet docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    print_info "Enabling Docker daemon..."
    sudo systemctl enable docker
    sudo systemctl start docker
    
    print_info "Adding current user to docker group..."
    sudo usermod -aG docker "$(whoami)"
    
    print_warning "You need to log out and back in for docker group changes to take effect"
    print_success "Docker installation completed"
}

configure_git() {
    print_header "Configuring Git (Optional)"
    
    print_info "Git configuration:"
    print_info "  Configure user name: git config --global user.name 'Your Name'"
    print_info "  Configure user email: git config --global user.email 'your.email@example.com'"
    print_info "  View config: git config --global --list"
}

################################################################################
# Template function for future tools/configurations
# Copy and customize this function as needed for new setup requirements
################################################################################

template_future_tool() {
    print_header "Template: Future Tool Installation"
    
    # TODO: Implement tool installation/configuration logic
    # This function serves as a template for future additions
    
    # Example pattern:
    # 1. Check if tool is already installed
    # 2. Install if needed
    # 3. Configure if required
    # 4. Enable/start services if applicable
    # 5. Report status
    
    print_info "This is a template function for future tools"
    print_info "Copy and customize this function for new requirements"
}


setup_gnome_settings() {
    print_header "Configuring GNOME Settings"

    print_info "Loading GNOME settings (input-sources) from dconf configuration file..."
    dconf load / < dconf/dconf-input-sourcessettings.ini

}

################################################################################
# Desktop-specific configuration
################################################################################

configure_fonts() {
    print_header "Configuring Fonts"
    
    local fonts=(
        "google-noto-fonts"
        "google-noto-fonts-extra"
        "google-noto-emoji-fonts"
        "dejavu-fonts"
        "liberation-fonts"
    )
    
    local to_install=()
    
    for font in "${fonts[@]}"; do
        if ! rpm -q "$font" &> /dev/null 2>&1; then
            to_install+=("$font")
        else
            print_info "$font already installed"
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        print_info "Installing missing fonts: ${to_install[*]}"
        sudo dnf install -y --quiet "${to_install[@]}" || print_warning "Some fonts failed to install"
    else
        print_info "All system fonts are already installed"
    fi
    
    print_success "Fonts configuration completed"
}

################################################################################
# Main execution
################################################################################

main() {
    print_header "Fedora Desktop Environment Setup"
    
    install_development_tools
    install_terminal_utilities
    install_languages_and_runtimes
    install_gui_applications
    configure_fonts
    install_docker
    configure_git
    
    print_header "Desktop Setup Completed!"
    echo ""
    echo "Installed components:"
    echo "  - Development tools (git, curl, vim, neovim, htop, tmux, etc.)"
    echo "  - Terminal utilities (fzf, ripgrep, bat, fd, exa, tree)"
    echo "  - Programming languages (Python, Node.js, Go, Rust)"
    echo "  - GUI applications (Firefox, VLC, Gedit, Nautilus, Evince)"
    echo "  - Docker with docker-compose"
    echo "  - System fonts"
    echo ""
}

# Run main function
main
