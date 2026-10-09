#!/bin/bash

################################################################################
# Fedora Linux Machine Setup Script
# 
# This script automates the setup of a new Fedora Linux machine with common
# tools and configurations for both desktop and server environments.
#
# Usage:
#   ./setup.sh [--mode=desktop|server] [--help]
#
# Parameters:
#   --mode      Setup mode: 'desktop' or 'server' (default: desktop)
#   --help      Display this help message
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MODE="desktop"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
# Validation functions
################################################################################

check_fedora() {
    if ! grep -qi "fedora" /etc/os-release; then
        print_error "This script is designed for Fedora Linux only"
        print_error "Current OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
        exit 1
    fi
    print_success "Running on Fedora Linux"
}

check_sudo() {
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        print_warning "This script may require sudo privileges"
        print_info "You may be prompted for your password"
    fi
}

validate_mode() {
    if [[ ! "$MODE" =~ ^(desktop|server)$ ]]; then
        print_error "Invalid mode: $MODE"
        print_error "Valid modes: desktop, server"
        exit 1
    fi
}

save_configuration() {
    print_header "Saving Configuration"
    
    local config_dir="$HOME/.config/dotfiles"
    local config_file="$config_dir/setup.conf"
    local config_content="mode=$MODE"
    
    # Create config directory if it doesn't exist
    if [[ ! -d "$config_dir" ]]; then
        print_info "Creating configuration directory: $config_dir"
        mkdir -p "$config_dir"
    fi
    
    # Check if config file exists and has the same content
    if [[ -f "$config_file" ]]; then
        if grep -q "^mode=$MODE$" "$config_file"; then
            print_info "Configuration file already up-to-date"
            return 0
        fi
        print_info "Updating existing configuration file..."
    else
        print_info "Creating new configuration file..."
    fi
    
    # Write configuration
    echo "$config_content" > "$config_file"
    print_success "Configuration saved to: $config_file"
}

################################################################################
# Core setup functions
################################################################################

update_system() {
    print_header "Updating System Packages"
    
    print_info "Checking for available updates..."
    if sudo dnf check-update --quiet 2>/dev/null; then
        print_info "System is already up-to-date"
    else
        print_info "Running dnf update..."
        sudo dnf update -y --quiet
        print_success "System packages updated"
    fi
}

install_zsh() {
    print_header "Installing Zsh"
    
    if command -v zsh &> /dev/null; then
        print_info "Zsh is already installed"
        zsh --version
    else
        print_info "Installing zsh..."
        sudo dnf install -y --quiet zsh
        print_success "Zsh installed"
    fi
}

configure_zsh_default() {
    print_header "Configuring Zsh as Default Shell"
    
    local zsh_path=$(which zsh)
    
    if [[ "$SHELL" == "$zsh_path" ]]; then
        print_info "Zsh is already the default shell"
    else
        print_info "Setting zsh as default shell..."
        chsh -s "$zsh_path" $(whoami)
        print_success "Default shell changed to zsh"
        print_info "Changes will take effect in new shell sessions"
    fi
}

install_ohmyzsh() {
    print_header "Installing Oh My Zsh"
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_info "Oh My Zsh is already installed"
    else
        print_info "Downloading and installing Oh My Zsh..."
        
        # Download and run the installation script
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        
        print_success "Oh My Zsh installed"
    fi
}

configure_zshrc() {
    print_header "Configuring .zshrc"
    
    # Check if .zshrc_template exists
    if [[ ! -f "$SCRIPT_DIR/.zshrc_template" ]]; then
        print_error ".zshrc_template not found in $SCRIPT_DIR"
        exit 1
    fi
    
    # Check if .zshrc already exists and is identical to template
    if [[ -f "$HOME/.zshrc" ]]; then
        # if cmp -s "$HOME/.zshrc" "$SCRIPT_DIR/.zshrc_template"; then
        #     print_info ".zshrc is already configured with the template"
        #     return 0
        # fi
        
        # Backup existing .zshrc if it differs from template
        local backup_file="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backing up existing .zshrc..."
        cp "$HOME/.zshrc" "$backup_file"
        print_success "Backup created: $backup_file"
    fi
    
    # Copy template as new .zshrc
    print_info "Copying .zshrc_template to ~/.zshrc..."
    cp "$SCRIPT_DIR/.zshrc_template" "$HOME/.zshrc"
    
    print_success ".zshrc configured"
}

configure_ohmyzsh_custom() {
    print_header "Configuring Oh My Zsh Custom Directory"
    
    local custom_dir="$HOME/.oh-my-zsh/custom"
    
    if [[ ! -d "$custom_dir" ]]; then
        print_warning "Oh My Zsh custom directory not found"
        return 0
    fi
    
    if [[ ! -d "$SCRIPT_DIR/ohmyzsh_custom" ]] || [[ -z "$(ls -A "$SCRIPT_DIR/ohmyzsh_custom")" ]]; then
        print_info "No custom Oh My Zsh configurations to copy"
        return 0
    fi
    
    print_info "Checking for new or updated custom Oh My Zsh configurations..."
    local files_copied=0
    
    # Copy only files that don't exist or are different in destination
    for src_file in "$SCRIPT_DIR/ohmyzsh_custom"/*; do
        if [[ ! -e "$src_file" ]]; then
            continue
        fi
        
        local filename=$(basename "$src_file")
        local dest_file="$custom_dir/$filename"
        
        if [[ ! -f "$dest_file" ]]; then
            print_info "Copying new file: $filename"
            cp -r "$src_file" "$dest_file"
            ((files_copied++))
        elif ! cmp -s "$src_file" "$dest_file"; then
            print_info "Updating modified file: $filename"
            cp -r"$src_file" "$dest_file"
            ((files_copied++))
        else
            print_info "File already up-to-date: $filename"
        fi
    done
    
    if [[ $files_copied -gt 0 ]]; then
        print_success "Custom configurations updated ($files_copied file(s) copied/updated)"
    else
        print_info "Custom configurations already up-to-date"
    fi
}

source_mode_script() {
    print_header "Running ${MODE^} Setup"
    
    local mode_script="$SCRIPT_DIR/setup_${MODE}.sh"
    
    if [[ ! -f "$mode_script" ]]; then
        print_warning "Setup script not found: $mode_script"
        print_info "Skipping mode-specific setup"
        return 0
    fi
    
    if [[ ! -x "$mode_script" ]]; then
        print_info "Making script executable..."
        chmod +x "$mode_script"
    fi
    
    print_info "Sourcing $mode_script..."
    bash "$mode_script"
    print_success "${MODE^} setup completed"
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

print_completion_message() {
    print_header "Setup Completed Successfully!"
    
    echo ""
    echo "Summary:"
    echo "--------"
    echo "  Mode:           ${MODE^}"
    echo "  Zsh:            Installed and set as default"
    echo "  Oh My Zsh:      Configured"
    echo "  .zshrc:         Configured from template"
    echo ""
    
    if [[ -f "$HOME/.zshrc.backup."* ]]; then
        echo "  Backups:        Created (*.backup.*)"
    fi
    
    echo ""
    echo "Next Steps:"
    echo "-----------"
    echo "  1. Start a new terminal session to use zsh"
    echo "  2. Review ~/.zshrc for any additional customizations"
    echo "  3. Explore Oh My Zsh plugins at: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins"
    echo ""
    
    if command -v zsh &> /dev/null; then
        echo "Current Zsh Version:"
        zsh --version
    fi
}

################################################################################
# Help function
################################################################################

show_help() {
    cat << EOF
Fedora Linux Machine Setup Script

USAGE:
    ./setup.sh [OPTIONS]

OPTIONS:
    --mode=MODE        Setup mode: 'desktop' or 'server' (default: desktop)
    --help             Display this help message

EXAMPLES:
    ./setup.sh                    # Setup with desktop mode (default)
    ./setup.sh --mode=server      # Setup with server mode

DESCRIPTION:
    This script automates the setup of a new Fedora Linux machine with:
    - System package updates
    - Zsh shell installation and configuration
    - Oh My Zsh installation
    - .zshrc configuration from template
    - Mode-specific tools and configurations

Requires:
    - Fedora Linux
    - Internet connection for downloading Oh My Zsh
    - sudo privileges for system package installation

EOF
    exit 0
}

################################################################################
# Argument parsing
################################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mode=*)
                MODE="${1#*=}"
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                print_error "Unknown option: $1"
                print_info "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

################################################################################
# Main execution
################################################################################

main() {
    parse_arguments "$@"
    
    print_header "Fedora Linux Setup"
    
    check_fedora
    check_sudo
    validate_mode
    save_configuration
    
    print_info "Mode: ${MODE^}"
    echo ""
    
    update_system
    install_zsh
    configure_zsh_default
    install_ohmyzsh
    configure_zshrc
    configure_ohmyzsh_custom
    echo "culo"
    source_mode_script

    if [[ "$MODE" == "desktop" ]]; then
        source setup_desktop.sh
    fi
    
        if [[ "$MODE" == "server" ]]; then
        source setup_server.sh
    fi
    
    print_completion_message
}

# Run main function
main "$@"
