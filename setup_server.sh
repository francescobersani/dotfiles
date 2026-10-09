#!/bin/bash

################################################################################
# Server Setup Script for Fedora
#
# This script installs and configures common tools and services
# for a server environment on Fedora Linux.
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
# Server Tool Installation Functions
################################################################################

install_essential_tools() {
    print_header "Installing Essential Server Tools"
    
    local tools=(
        "git:git"
        "curl:curl"
        "wget:wget"
        "vim:vim"
        "neovim:nvim"
        "htop:htop"
        "tmux:tmux"
        "net-tools:netstat"
        "iproute-tc:tc"
        "jq:jq"
        "rsync:rsync"
        "openssh-clients:ssh"
        "openssh-server:sshd"
    )
    
    local to_install=()
    
    for entry in "${tools[@]}"; do
        local pkg="${entry%%:*}"
        local cmd="${entry##*:}"
        
        if ! command -v "$cmd" &> /dev/null 2>&1 && ! rpm -q "$pkg" &> /dev/null 2>&1; then
            to_install+=("$pkg")
        else
            print_info "$pkg already installed"
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        print_info "Installing missing tools: ${to_install[*]}"
        sudo dnf install -y --quiet "${to_install[@]}" || print_warning "Some tools failed to install"
    else
        print_info "All essential tools are already installed"
    fi
    
    print_success "Essential tools installation completed"
}

configure_ssh() {
    print_header "Configuring SSH Server"
    
    if ! rpm -q openssh-server &> /dev/null 2>&1; then
        print_info "Installing openssh-server..."
        sudo dnf install -y --quiet openssh-server
    else
        print_info "openssh-server is already installed"
    fi
    
    # Check if SSH is enabled
    if sudo systemctl is-enabled sshd &> /dev/null 2>&1; then
        print_info "SSH daemon is already enabled"
    else
        print_info "Enabling SSH daemon..."
        sudo systemctl enable sshd
    fi
    
    # Check if SSH is running
    if sudo systemctl is-active --quiet sshd; then
        print_success "SSH daemon is running"
    else
        print_info "Starting SSH daemon..."
        sudo systemctl start sshd
        print_success "SSH daemon started"
    fi
    
    print_warning "Review /etc/ssh/sshd_config for security settings"
}

install_monitoring_tools() {
    print_header "Installing Monitoring Tools"
    
    local tools=(
        "sysstat:sar"
        "iotop:iotop"
        "nethogs:nethogs"
    )
    
    local to_install=()
    
    for entry in "${tools[@]}"; do
        local pkg="${entry%%:*}"
        local cmd="${entry##*:}"
        
        if ! command -v "$cmd" &> /dev/null 2>&1 && ! rpm -q "$pkg" &> /dev/null 2>&1; then
            to_install+=("$pkg")
        else
            print_info "$pkg already installed"
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        print_info "Installing missing tools: ${to_install[*]}"
        sudo dnf install -y --quiet "${to_install[@]}" || print_warning "Some tools failed to install"
    else
        print_info "All monitoring tools are already installed"
    fi
    
    print_success "Monitoring tools installation completed"
}

install_languages_and_runtimes() {
    print_header "Installing Programming Languages and Runtimes"
    
    local runtimes=(
        "python3:python3"
        "python3-pip:pip3"
        "nodejs:node"
        "go:go"
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

install_container_tools() {
    print_header "Installing Container Tools"
    
    # Check and install Podman
    if command -v podman &> /dev/null; then
        print_info "Podman is already installed"
        podman --version
    else
        print_info "Installing Podman..."
        sudo dnf install -y --quiet podman podman-compose
        print_success "Podman installed"
    fi
    
    # Check if podman socket is enabled for rootless mode
    if systemctl --user is-enabled podman.socket &> /dev/null 2>&1; then
        print_info "Podman socket is already enabled"
    else
        print_info "Enabling podman socket for rootless operation..."
        systemctl --user enable podman.socket || true
    fi

    print_header "Installing Container Tools"
    
    # Check and install and configure Docker
    if command -v docker &> /dev/null; then
        print_info "Docker is already installed"
        docker --version
    else
        print_info "Remove any existing Docker packages if present..."
        sudo dnf remove docker \
            docker-client \
            docker-client-latest \
            docker-common \
            docker-latest \
            docker-latest-logrotate \
            docker-logrotate \
            docker-selinux \
            docker-engine-selinux \
            docker-engine

        sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo groupadd docker
        sudo usermod -aG docker $USER
        newgrp docker

        print_success "Docker installed and configured for non-root usage"
        docker --version
    fi


}

install_web_servers() {
    print_header "Installing Web Server Options"
    
    print_info "Web server options available:"
    print_info "  - Nginx: sudo dnf install -y nginx"
    print_info "  - Apache: sudo dnf install -y httpd"
    print_info "  - Caddy: Available from community repos"
    print_info ""
    print_info "Install based on your preference"
}

install_database_tools() {
    print_header "Installing Database Tools"
    
    print_info "Database tools available:"
    print_info "  - PostgreSQL client: sudo dnf install -y postgresql"
    print_info "  - MySQL client: sudo dnf install -y mysql"
    print_info "  - SQLite: sudo dnf install -y sqlite"
    print_info "  - Redis: sudo dnf install -y redis"
    print_info ""
    print_info "Install based on your requirements"
}

configure_firewall() {
    print_header "Configuring Firewall"
    
    print_info "Firewall status:"
    sudo firewall-cmd --state || print_warning "Firewall not configured"
    
    # Check if firewalld is enabled
    if sudo systemctl is-enabled firewalld &> /dev/null 2>&1; then
        print_info "Firewall is already enabled"
    else
        print_info "Enabling firewall..."
        sudo systemctl enable firewalld
    fi
    
    # Check if firewalld is running
    if sudo systemctl is-active --quiet firewalld; then
        print_info "Firewall is already running"
    else
        print_info "Starting firewall..."
        sudo systemctl start firewalld
        print_success "Firewall started"
    fi
    
    print_warning "Configure firewall rules based on your requirements:"
    print_info "  - List active zones: sudo firewall-cmd --get-active-zones"
    print_info "  - Add service: sudo firewall-cmd --permanent --add-service=http"
    print_info "  - Reload firewall: sudo firewall-cmd --reload"
}

configure_selinux() {
    print_header "Configuring SELinux"
    
    local selinux_status=$(getenforce 2>/dev/null || echo "unknown")
    print_info "Current SELinux status: $selinux_status"
    
    print_warning "SELinux configuration options:"
    print_info "  - Enforcing: sudo setenforce 1"
    print_info "  - Permissive: sudo setenforce 0"
    print_info "  - Permanent changes: /etc/selinux/config"
}

install_system_utilities() {
    print_header "Installing System Utilities"
    
    local utils=(
        "screen:screen"
        "logwatch:logwatch"
        "fail2ban:fail2ban-client"
        "aide:aide"
        "lsof:lsof"
    )
    
    local to_install=()
    
    for entry in "${utils[@]}"; do
        local pkg="${entry%%:*}"
        local cmd="${entry##*:}"
        
        if ! command -v "$cmd" &> /dev/null 2>&1 && ! rpm -q "$pkg" &> /dev/null 2>&1; then
            to_install+=("$pkg")
        else
            print_info "$pkg already installed"
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        print_info "Installing missing utilities: ${to_install[*]}"
        sudo dnf install -y --quiet "${to_install[@]}" || print_warning "Some utilities failed to install"
    else
        print_info "All system utilities are already installed"
    fi
    
    print_success "System utilities installation completed"
}

suggest_hardening_steps() {
    print_header "Security Hardening Suggestions"
    
    echo ""
    echo "Recommended security hardening steps:"
    echo "  1. Update /etc/ssh/sshd_config:"
    echo "     - Disable root SSH login"
    echo "     - Change SSH port (optional)"
    echo "     - Use key-based authentication"
    echo ""
    echo "  2. Configure firewall rules"
    echo "     - Allow only necessary ports"
    echo "     - Block unnecessary services"
    echo ""
    echo "  3. Enable SELinux in enforcing mode"
    echo ""
    echo "  4. Set up log monitoring (logwatch)"
    echo ""
    echo "  5. Configure automatic security updates:"
    echo "     - sudo systemctl enable --now dnf-makecache.timer"
    echo ""
    echo "  6. Regular backups of critical data"
    echo ""
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



################################################################################
# Main execution
################################################################################

main() {
    print_header "Fedora Server Environment Setup"
    
    install_essential_tools
    install_monitoring_tools
    install_languages_and_runtimes
    install_system_utilities
    configure_ssh
    configure_firewall
    configure_selinux
    install_container_tools
    install_web_servers
    install_database_tools
    suggest_hardening_steps
    
    print_header "Server Setup Completed!"
    echo ""
    echo "Installed components:"
    echo "  - Essential server tools (git, curl, vim, htop, tmux, rsync, ssh)"
    echo "  - Monitoring tools (sysstat, iotop, nethogs)"
    echo "  - Programming languages (Python, Node.js, Go)"
    echo "  - Container tools (Podman)"
    echo "  - System utilities (screen, logwatch, fail2ban, aide)"
    echo "  - SSH server configured and enabled"
    echo "  - Firewall and SELinux configured"
    echo ""
    echo "Next steps:"
    echo "  1. Review and configure SSH settings"
    echo "  2. Set up firewall rules for your services"
    echo "  3. Choose and install web server (Nginx/Apache)"
    echo "  4. Choose and install database (PostgreSQL/MySQL/Redis)"
    echo "  5. Implement security hardening recommendations"
    echo ""
}

# Run main function
main
