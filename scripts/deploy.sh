#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# NixOS Deployment Script
# =============================================================================
# Usage: ./scripts/deploy.sh [HOST] [OPTIONS]
# Examples:
#   ./scripts/deploy.sh nick-laptop
#   ./scripts/deploy.sh web-01 --dry-run
#   ./scripts/deploy.sh db-01 --rollback
# =============================================================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FLAKE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly LOG_FILE="/tmp/nixos-deploy-$(date +%Y%m%d-%H%M%S).log"
readonly BACKUP_DIR="/etc/nixos/backups"

# Default values
HOST=""
DRY_RUN=false
ROLLBACK=false
VERBOSE=false
SKIP_BUILD=false

# =============================================================================
# Logging Functions
# =============================================================================

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

# =============================================================================
# Utility Functions
# =============================================================================

show_help() {
    cat << EOF
NixOS Deployment Script

Usage: $0 [HOST] [OPTIONS]

Arguments:
  HOST                    Target host configuration (e.g., nick-laptop, web-01, db-01)

Options:
  -h, --help             Show this help message
  -d, --dry-run          Build configuration without applying
  -r, --rollback         Rollback to previous generation
  -v, --verbose          Enable verbose output
  -s, --skip-build       Skip build step (use with caution)
  --list-hosts           List available host configurations

Examples:
  $0 nick-laptop         Deploy nick-laptop configuration
  $0 web-01 --dry-run    Build web-01 configuration without applying
  $0 db-01 --rollback    Rollback db-01 to previous generation
  $0 --list-hosts        Show available host configurations

Available Hosts:
  - nick-laptop          Development workstation
  - web-01              Web server
  - db-01               Database server

Log file: $LOG_FILE
EOF
}

list_hosts() {
    log "INFO" "Available host configurations:"
    echo "  nick-laptop    - Development workstation"
    echo "  web-01         - Web server"
    echo "  db-01          - Database server"
    echo ""
    log "INFO" "Use --dry-run to test configurations before deploying"
}

validate_host() {
    local host="$1"
    case "$host" in
        "nick-laptop"|"web-01"|"db-01")
            return 0
            ;;
        *)
            log "ERROR" "Invalid host: $host"
            log "INFO" "Use --list-hosts to see available options"
            return 1
            ;;
    esac
}

check_prerequisites() {
    log "INFO" "Checking prerequisites..."
    
    # Check if we're on NixOS
    if [[ ! -f /etc/nixos/configuration.nix ]]; then
        log "ERROR" "This script must be run on a NixOS system"
        exit 1
    fi
    
    # Check if nixos-rebuild is available
    if ! command -v nixos-rebuild >/dev/null 2>&1; then
        log "ERROR" "nixos-rebuild not found. Are you on NixOS?"
        exit 1
    fi
    
    # Check if flake.nix exists
    if [[ ! -f "$FLAKE_ROOT/flake.nix" ]]; then
        log "ERROR" "flake.nix not found in $FLAKE_ROOT"
        exit 1
    fi
    
    # Check if target host configuration exists
    if [[ -n "$HOST" ]]; then
        if ! validate_host "$HOST"; then
            exit 1
        fi
    fi
    
    log "SUCCESS" "Prerequisites check passed"
}

create_backup() {
    local host="$1"
    log "INFO" "Creating backup of current configuration..."
    
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/${host}-$(date +%Y%m%d-%H%M%S).nix"
    
    if [[ -f /etc/nixos/configuration.nix ]]; then
        cp /etc/nixos/configuration.nix "$backup_file"
        log "SUCCESS" "Backup created: $backup_file"
    else
        log "WARNING" "No existing configuration.nix found to backup"
    fi
}

build_configuration() {
    local host="$1"
    log "INFO" "Building configuration for $host..."
    
    if [[ "$VERBOSE" == "true" ]]; then
        nixos-rebuild build --flake "$FLAKE_ROOT#$host" --verbose
    else
        nixos-rebuild build --flake "$FLAKE_ROOT#$host"
    fi
    
    if [[ $? -eq 0 ]]; then
        log "SUCCESS" "Configuration build successful"
    else
        log "ERROR" "Configuration build failed"
        exit 1
    fi
}

deploy_configuration() {
    local host="$1"
    log "INFO" "Deploying configuration for $host..."
    
    if [[ "$VERBOSE" == "true" ]]; then
        nixos-rebuild switch --flake "$FLAKE_ROOT#$host" --verbose
    else
        nixos-rebuild switch --flake "$FLAKE_ROOT#$host"
    fi
    
    if [[ $? -eq 0 ]]; then
        log "SUCCESS" "Configuration deployed successfully"
    else
        log "ERROR" "Configuration deployment failed"
        exit 1
    fi
}

rollback_configuration() {
    local host="$1"
    log "INFO" "Rolling back configuration for $host..."
    
    if [[ "$VERBOSE" == "true" ]]; then
        nixos-rebuild switch --rollback --verbose
    else
        nixos-rebuild switch --rollback
    fi
    
    if [[ $? -eq 0 ]]; then
        log "SUCCESS" "Rollback completed successfully"
    else
        log "ERROR" "Rollback failed"
        exit 1
    fi
}

show_generations() {
    log "INFO" "Available NixOS generations:"
    nix-env --list-generations --profile /nix/var/nix/profiles/system
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -r|--rollback)
                ROLLBACK=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -s|--skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --list-hosts)
                list_hosts
                exit 0
                ;;
            -*)
                log "ERROR" "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$HOST" ]]; then
                    HOST="$1"
                else
                    log "ERROR" "Multiple hosts specified: $HOST and $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate we have a host
    if [[ -z "$HOST" ]]; then
        log "ERROR" "No host specified"
        show_help
        exit 1
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # Create backup
    create_backup "$HOST"
    
    # Handle rollback
    if [[ "$ROLLBACK" == "true" ]]; then
        rollback_configuration "$HOST"
        show_generations
        exit 0
    fi
    
    # Build configuration
    if [[ "$SKIP_BUILD" != "true" ]]; then
        build_configuration "$HOST"
    fi
    
    # Deploy or dry run
    if [[ "$DRY_RUN" == "true" ]]; then
        log "SUCCESS" "Dry run completed successfully"
        log "INFO" "Configuration is ready for deployment"
    else
        deploy_configuration "$HOST"
        show_generations
    fi
    
    log "SUCCESS" "Deployment process completed"
    log "INFO" "Log file: $LOG_FILE"
}

# Run main function with all arguments
main "$@"
