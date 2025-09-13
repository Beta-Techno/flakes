#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# NixOS Flake One-Liner Installer
# =============================================================================
# Usage: bash -c "$(curl -fsSL https://raw.githubusercontent.com/Beta-Techno/flakes/main/scripts/init-nixos.sh)"
# =============================================================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly REPO_URL="https://github.com/Beta-Techno/flakes.git"
readonly INSTALL_PATH="/etc/nixos/flakes"
readonly LOG_FILE="/tmp/nixos-setup-$(date +%Y%m%d-%H%M%S).log"

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    NixOS Flake Installer                    ║
║                                                              ║
║  This will install your development environment on NixOS    ║
║  with professional deployment tools and configurations.     ║
║                                                              ║
║  Repository: https://github.com/Beta-Techno/flakes         ║
║  Install Path: /etc/nixos/flakes                           ║
╚══════════════════════════════════════════════════════════════╝

EOF
}

check_nixos() {
    log "INFO" "Checking if running on NixOS..."
    
    if [[ ! -f /etc/nixos/configuration.nix ]]; then
        log "ERROR" "This installer must be run on a NixOS system"
        log "INFO" "Please run this on your NixOS machine"
        exit 1
    fi
    
    log "SUCCESS" "Running on NixOS"
}

install_git() {
    log "INFO" "Checking for git..."
    
    if ! command -v git >/dev/null 2>&1; then
        log "INFO" "Git not found, installing..."
        nix-env -i git
        log "SUCCESS" "Git installed"
    else
        log "SUCCESS" "Git already installed"
    fi
}

clone_repository() {
    log "INFO" "Cloning repository to $INSTALL_PATH..."
    
    # Create parent directory if it doesn't exist
    sudo mkdir -p "$(dirname "$INSTALL_PATH")"
    
    # Remove existing directory if it exists
    if [[ -d "$INSTALL_PATH" ]]; then
        log "INFO" "Removing existing installation..."
        sudo rm -rf "$INSTALL_PATH"
    fi
    
    # Clone the repository
    if sudo git clone "$REPO_URL" "$INSTALL_PATH"; then
        log "SUCCESS" "Repository cloned successfully"
    else
        log "ERROR" "Failed to clone repository"
        exit 1
    fi
    
    # Set proper permissions
    sudo chown -R "$(whoami)" "$INSTALL_PATH"
    log "SUCCESS" "Repository permissions set"
    
    # Debug: Show what was actually cloned
    log "INFO" "Verifying cloned repository..."
    log "INFO" "Install path exists: $([[ -d "$INSTALL_PATH" ]] && echo 'YES' || echo 'NO')"
    log "INFO" "Files in install path: $(ls -la "$INSTALL_PATH" 2>/dev/null || echo 'Cannot list files')"
    if [[ -d "$INSTALL_PATH/scripts" ]]; then
        log "INFO" "Scripts directory exists: YES"
        log "INFO" "Files in scripts directory: $(ls -la "$INSTALL_PATH/scripts" 2>/dev/null || echo 'Cannot list scripts')"
    else
        log "WARNING" "Scripts directory does not exist!"
    fi
}

setup_deployment() {
    log "INFO" "Setting up deployment scripts..."
    
    cd "$INSTALL_PATH"
    
    # Make scripts executable
    if [[ -f "scripts/deploy.sh" ]]; then
        chmod +x scripts/deploy.sh
        log "SUCCESS" "Deployment script made executable"
    else
        log "WARNING" "Deployment script not found"
    fi
    
    if [[ -f "scripts/setup-nixos.sh" ]]; then
        chmod +x scripts/setup-nixos.sh
        log "SUCCESS" "Setup script made executable"
    fi
    
    # Try to create symlink for easy access (optional)
    log "INFO" "Attempting to create deploy symlink..."
    if sudo mkdir -p /usr/local/bin 2>/dev/null; then
        if [[ -f "scripts/deploy.sh" ]]; then
            if sudo ln -sf "$(pwd)/scripts/deploy.sh" /usr/local/bin/deploy 2>/dev/null; then
                log "SUCCESS" "Deploy script symlinked to /usr/local/bin/deploy"
            else
                log "INFO" "Symlink creation skipped (not critical)"
            fi
        else
            log "INFO" "Deploy script not found, skipping symlink"
        fi
    else
        log "INFO" "Could not create /usr/local/bin, skipping symlink"
    fi
}

test_configuration() {
    log "INFO" "Testing flake configuration..."
    
    cd "$INSTALL_PATH"
    
    # Test flake evaluation
    if nix flake check; then
        log "SUCCESS" "Flake configuration is valid"
    else
        log "WARNING" "Flake configuration has issues (this might be expected)"
    fi
    
    # Test building a configuration
    log "INFO" "Testing build of nick-vm configuration..."
    if nixos-rebuild build --flake .#nick-vm; then
        log "SUCCESS" "Configuration builds successfully"
    else
        log "WARNING" "Configuration build failed (this might be expected on first run)"
    fi
}

create_backup() {
    log "INFO" "Creating initial backup..."
    
    local backup_dir="/etc/nixos/backups"
    sudo mkdir -p "$backup_dir"
    
    if [[ -f /etc/nixos/configuration.nix ]]; then
        local backup_file="$backup_dir/initial-$(date +%Y%m%d-%H%M%S).nix"
        sudo cp /etc/nixos/configuration.nix "$backup_file"
        log "SUCCESS" "Initial backup created: $backup_file"
    else
        log "WARNING" "No existing configuration.nix found"
    fi
}

show_completion() {
    cat << EOF

${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}
${GREEN}║                    Installation Complete!                    ║${NC}
${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}

${BLUE}Next Steps:${NC}
1. Review your configuration:
   cd $INSTALL_PATH
   nixos-rebuild build --flake .#nick-vm

2. Deploy your first configuration:
   $INSTALL_PATH/scripts/deploy.sh nick-vm --dry-run

3. If everything looks good, deploy:
   $INSTALL_PATH/scripts/deploy.sh nick-vm

${BLUE}Available Commands:${NC}
- $INSTALL_PATH/scripts/deploy.sh --list-hosts          # Show available configurations
- $INSTALL_PATH/scripts/deploy.sh nick-vm --dry-run # Test deployment
- $INSTALL_PATH/scripts/deploy.sh netbox-01 --verbose      # Deploy with verbose output
- $INSTALL_PATH/scripts/deploy.sh netbox-01 --rollback      # Rollback if needed

${BLUE}Available Hosts:${NC}
- nick-laptop    - Development workstation
- netbox-01      - NetBox IPAM/DCIM server

${BLUE}Useful Aliases (add to your shell config):${NC}
- alias deploy='$INSTALL_PATH/scripts/deploy.sh'
- alias test-deploy='$INSTALL_PATH/scripts/deploy.sh --dry-run'

${YELLOW}Important:${NC}
- Always test with --dry-run first
- Check logs at /tmp/nixos-deploy-*.log
- Backups are stored in /etc/nixos/backups/
- Log file: $LOG_FILE

${GREEN}Your NixOS development environment is ready! 🚀${NC}

EOF
}

main() {
    show_banner
    
    log "INFO" "Starting NixOS flake installation..."
    log "INFO" "Log file: $LOG_FILE"
    
    # Run installation steps
    check_nixos
    install_git
    clone_repository
    setup_deployment
    test_configuration
    create_backup
    
    show_completion
    
    log "SUCCESS" "NixOS flake installation completed!"
}

# Run main function
main "$@"
