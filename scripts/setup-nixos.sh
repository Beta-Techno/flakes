#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# NixOS Flake Setup Script
# =============================================================================
# Usage: ./scripts/setup-nixos.sh [REPO_URL] [INSTALL_PATH]
# Examples:
#   ./scripts/setup-nixos.sh
#   ./scripts/setup-nixos.sh https://github.com/yourusername/yourrepo
#   ./scripts/setup-nixos.sh https://github.com/yourusername/yourrepo /etc/nixos/flakes
# =============================================================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Default values
REPO_URL=""
INSTALL_PATH="/etc/nixos/flakes"

log() {
    local level="$1"
    shift
    local message="$*"
    
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
}

show_help() {
    cat << EOF
NixOS Flake Setup Script

Usage: $0 [REPO_URL] [INSTALL_PATH]

Arguments:
  REPO_URL               Git repository URL (optional, will prompt if not provided)
  INSTALL_PATH           Installation path (default: /etc/nixos/flakes)

Examples:
  $0                                    # Interactive setup
  $0 https://github.com/user/repo       # Clone to default location
  $0 https://github.com/user/repo ~/flakes  # Clone to home directory

This script will:
1. Check if running on NixOS
2. Install git if not present
3. Clone your flake repository
4. Set up deployment scripts
5. Test flake configuration
6. Create initial backup

EOF
}

check_nixos() {
    log "INFO" "Checking if running on NixOS..."
    
    if [[ ! -f /etc/nixos/configuration.nix ]]; then
        log "ERROR" "This script must be run on a NixOS system"
        log "INFO" "Please run this on your NixOS machine"
        exit 1
    fi
    
    log "SUCCESS" "Running on NixOS"
}

install_git() {
    log "INFO" "Checking for git..."
    
    if ! command -v git >/dev/null 2>&1; then
        log "INFO" "Git not found, installing..."
        nix-env -iA nixpkgs.git
        log "SUCCESS" "Git installed"
    else
        log "SUCCESS" "Git already installed"
    fi
}

get_repo_url() {
    if [[ -z "$REPO_URL" ]]; then
        echo ""
        log "INFO" "Please provide your flake repository URL:"
        echo "  Example: https://github.com/yourusername/yourrepo"
        echo "  Example: git@github.com:yourusername/yourrepo.git"
        echo ""
        read -p "Repository URL: " REPO_URL
        
        if [[ -z "$REPO_URL" ]]; then
            log "ERROR" "Repository URL is required"
            exit 1
        fi
    fi
}

clone_repository() {
    log "INFO" "Cloning repository to $INSTALL_PATH..."
    
    # Create parent directory if it doesn't exist
    sudo mkdir -p "$(dirname "$INSTALL_PATH")"
    
    # Clone the repository
    if sudo git clone "$REPO_URL" "$INSTALL_PATH"; then
        log "SUCCESS" "Repository cloned successfully"
    else
        log "ERROR" "Failed to clone repository"
        exit 1
    fi
    
    # Set proper permissions
    sudo chown -R "$USER:$USER" "$INSTALL_PATH"
    log "SUCCESS" "Repository permissions set"
}

setup_deployment() {
    log "INFO" "Setting up deployment scripts..."
    
    cd "$INSTALL_PATH"
    
    # Make deploy script executable
    if [[ -f "scripts/deploy.sh" ]]; then
        chmod +x scripts/deploy.sh
        log "SUCCESS" "Deployment script made executable"
    else
        log "WARNING" "Deployment script not found at scripts/deploy.sh"
    fi
    
    # Create symlink for easy access
    if [[ "$INSTALL_PATH" == "/etc/nixos/flakes" ]]; then
        sudo ln -sf "$INSTALL_PATH/scripts/deploy.sh" /usr/local/bin/deploy
        log "SUCCESS" "Deploy script symlinked to /usr/local/bin/deploy"
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
    log "INFO" "Testing build of nick-laptop configuration..."
    if nixos-rebuild build --flake .#nick-laptop; then
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

show_next_steps() {
    cat << EOF

${GREEN}Setup Complete!${NC}

${BLUE}Next Steps:${NC}
1. Review your configuration:
   cd $INSTALL_PATH
   nixos-rebuild build --flake .#nick-laptop --dry-run

2. Deploy your first configuration:
   $INSTALL_PATH/scripts/deploy.sh nick-laptop --dry-run

3. If everything looks good, deploy:
   $INSTALL_PATH/scripts/deploy.sh nick-laptop

${BLUE}Available Commands:${NC}
- deploy.sh --list-hosts          # Show available configurations
- deploy.sh nick-laptop --dry-run # Test deployment
- deploy.sh netbox-01 --verbose      # Deploy with verbose output
- deploy.sh netbox-01 --rollback      # Rollback if needed

${BLUE}Useful Aliases:${NC}
Add these to your shell configuration:
  alias deploy='$INSTALL_PATH/scripts/deploy.sh'
  alias test-deploy='$INSTALL_PATH/scripts/deploy.sh --dry-run'

${YELLOW}Remember:${NC}
- Always test with --dry-run first
- Check logs at /tmp/nixos-deploy-*.log
- Backups are stored in /etc/nixos/backups/

EOF
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                log "ERROR" "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$REPO_URL" ]]; then
                    REPO_URL="$1"
                elif [[ -z "$INSTALL_PATH" ]]; then
                    INSTALL_PATH="$1"
                else
                    log "ERROR" "Too many arguments"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    log "INFO" "Starting NixOS flake setup..."
    
    # Run setup steps
    check_nixos
    install_git
    get_repo_url
    clone_repository
    setup_deployment
    test_configuration
    create_backup
    
    show_next_steps
    
    log "SUCCESS" "NixOS flake setup completed!"
}

main "$@"
