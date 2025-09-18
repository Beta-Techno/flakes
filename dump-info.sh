#!/usr/bin/env bash

# Comprehensive Nix Flakes Repository Information Dumper
# This script dumps all relevant information from the repository for agent analysis

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  NIX FLAKES REPOSITORY INFORMATION DUMP${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Function to print section headers
print_section() {
    echo -e "\n${GREEN}=== $1 ===${NC}"
    echo ""
}

# Function to print subsection headers
print_subsection() {
    echo -e "\n${YELLOW}--- $1 ---${NC}"
}

# Function to safely read and display file contents
show_file() {
    local file="$1"
    local title="$2"
    
    if [[ -f "$file" ]]; then
        print_subsection "$title"
        echo "File: $file"
        echo "Size: $(wc -c < "$file") bytes"
        echo "Lines: $(wc -l < "$file")"
        echo ""
        cat "$file"
        echo ""
    else
        echo -e "${RED}File not found: $file${NC}"
    fi
}

# Function to show directory structure
show_directory() {
    local dir="$1"
    local title="$2"
    
    if [[ -d "$dir" ]]; then
        print_subsection "$title"
        echo "Directory: $dir"
        echo ""
        find "$dir" -type f -name "*.nix" -o -name "*.yaml" -o -name "*.yml" -o -name "*.sh" -o -name "*.org" -o -name "*.md" -o -name "*.txt" | sort
        echo ""
    else
        echo -e "${RED}Directory not found: $dir${NC}"
    fi
}

# Repository Overview
print_section "REPOSITORY OVERVIEW"
echo "Repository Path: $SCRIPT_DIR"
echo "Git Status:"
git status --porcelain || echo "Not a git repository or git not available"
echo ""
echo "Git Remote:"
git remote -v 2>/dev/null || echo "No git remotes configured"
echo ""
echo "Current Branch:"
git branch --show-current 2>/dev/null || echo "No git branch information"
echo ""
echo "Last Commit:"
git log -1 --oneline 2>/dev/null || echo "No git history"
echo ""

# Main Configuration Files
print_section "MAIN CONFIGURATION FILES"

show_file "flake.nix" "Main Flake Configuration"
show_file "README.md" "Repository README"
show_file "TODO.md" "TODO List"

# Repository Catalog
print_section "REPOSITORY CATALOG"
show_file "catalog/repos.yaml" "Repository Catalog"

# Documentation
print_section "DOCUMENTATION"
show_directory "docs" "Documentation Files"
for doc in docs/*.org; do
    if [[ -f "$doc" ]]; then
        show_file "$doc" "Documentation: $(basename "$doc")"
    fi
done

# Inventory Files
print_section "INVENTORY CONFIGURATIONS"
show_file "inventories/prod.nix" "Production Inventory"
show_file "inventories/staging.nix" "Staging Inventory"

# NixOS Configurations
print_section "NIXOS CONFIGURATIONS"
show_directory "nixos" "NixOS Configuration Structure"

# Show key NixOS files
for host_file in nixos/hosts/servers/*.nix; do
    if [[ -f "$host_file" ]]; then
        show_file "$host_file" "Server Host: $(basename "$host_file" .nix)"
    fi
done

for host_file in nixos/hosts/workstations/*.nix; do
    if [[ -f "$host_file" ]]; then
        show_file "$host_file" "Workstation Host: $(basename "$host_file" .nix)"
    fi
done

# NixOS Roles
print_subsection "NixOS Roles"
for role_file in nixos/roles/*.nix; do
    if [[ -f "$role_file" ]]; then
        show_file "$role_file" "Role: $(basename "$role_file" .nix)"
    fi
done

# NixOS Profiles
print_subsection "NixOS Profiles"
for profile_file in nixos/profiles/*.nix; do
    if [[ -f "$profile_file" ]]; then
        show_file "$profile_file" "Profile: $(basename "$profile_file" .nix)"
    fi
done

# NixOS Services
print_subsection "NixOS Services"
for service_dir in nixos/services/*/; do
    if [[ -d "$service_dir" ]]; then
        service_name=$(basename "$service_dir")
        for service_file in "$service_dir"*.nix; do
            if [[ -f "$service_file" ]]; then
                show_file "$service_file" "Service: $service_name/$(basename "$service_file" .nix)"
            fi
        done
    fi
done

# Home Manager Configurations
print_section "HOME MANAGER CONFIGURATIONS"
show_directory "home" "Home Manager Structure"

# Show home host configurations
for host_file in home/hosts/*.nix; do
    if [[ -f "$host_file" ]]; then
        show_file "$host_file" "Home Host: $(basename "$host_file" .nix)"
    fi
done

# Show editor configurations
print_subsection "Editor Configurations"
for editor_dir in home/editors/*/; do
    if [[ -d "$editor_dir" ]]; then
        editor_name=$(basename "$editor_dir")
        echo "Editor: $editor_name"
        for editor_file in "$editor_dir"*; do
            if [[ -f "$editor_file" ]]; then
                show_file "$editor_file" "Editor Config: $editor_name/$(basename "$editor_file")"
            fi
        done
    fi
done

# Modules
print_section "MODULE DEFINITIONS"
show_directory "modules" "Module Structure"

# Show key module files
for module_file in modules/core/*.nix; do
    if [[ -f "$module_file" ]]; then
        show_file "$module_file" "Core Module: $(basename "$module_file" .nix)"
    fi
done

for module_file in modules/tools/*.nix; do
    if [[ -f "$module_file" ]]; then
        show_file "$module_file" "Tool Module: $(basename "$module_file" .nix)"
    fi
done

for module_file in modules/gui/*.nix; do
    if [[ -f "$module_file" ]]; then
        show_file "$module_file" "GUI Module: $(basename "$module_file" .nix)"
    fi
done

for module_file in modules/editors/*.nix; do
    if [[ -f "$module_file" ]]; then
        show_file "$module_file" "Editor Module: $(basename "$module_file" .nix)"
    fi
done

for module_file in modules/platform/*/*.nix; do
    if [[ -f "$module_file" ]]; then
        platform=$(basename "$(dirname "$module_file")")
        show_file "$module_file" "Platform Module: $platform/$(basename "$module_file" .nix)"
    fi
done

# Nix Library and Toolsets
print_section "NIX LIBRARY AND TOOLSETS"
show_file "nix/toolsets.nix" "Development Toolsets"
show_file "nix/lib/mkHost.nix" "Host Creation Library"
show_file "nix/lib/utils.nix" "Utility Functions"

# Profiles
print_section "PROFILES"
show_file "profiles/default-darwin.nix" "Default Darwin Profile"
show_file "profiles/default-linux.nix" "Default Linux Profile"

# Packages
print_section "PACKAGE DEFINITIONS"
show_directory "pkgs" "Package Structure"

for pkg_file in pkgs/cli/*.nix; do
    if [[ -f "$pkg_file" ]]; then
        show_file "$pkg_file" "CLI Package: $(basename "$pkg_file" .nix)"
    fi
done

for pkg_file in pkgs/shells/*.nix; do
    if [[ -f "$pkg_file" ]]; then
        show_file "$pkg_file" "Shell Package: $(basename "$pkg_file" .nix)"
    fi
done

# Scripts
print_section "SCRIPTS"
show_directory "scripts" "Script Files"

for script_file in scripts/*.sh; do
    if [[ -f "$script_file" ]]; then
        show_file "$script_file" "Script: $(basename "$script_file")"
    fi
done

# Assets
print_section "ASSETS"
echo "Assets directory structure:"
find assets -type f 2>/dev/null | sort || echo "No assets directory or no files found"
echo ""

# Secrets (structure only, not contents)
print_section "SECRETS STRUCTURE"
if [[ -d "secrets" ]]; then
    echo "Secrets directory structure (contents not shown for security):"
    find secrets -type d | sort
    echo ""
else
    echo "No secrets directory found"
fi

# Nix Flake Information
print_section "NIX FLAKE METADATA"
echo "Flake inputs:"
nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes | to_entries[] | "\(.key): \(.locked.url // .locked.path // "unknown")"' || echo "Could not read flake metadata"
echo ""

echo "Available flake outputs:"
nix flake show --json 2>/dev/null | jq -r 'keys[]' || echo "Could not read flake outputs"
echo ""

# System Information
print_section "SYSTEM INFORMATION"
echo "Current system: $(uname -a)"
echo "Nix version: $(nix --version 2>/dev/null || echo "Nix not available")"
echo "Home Manager version: $(home-manager --version 2>/dev/null || echo "Home Manager not available")"
echo ""

# File Statistics
print_section "REPOSITORY STATISTICS"
echo "Total files by type:"
find . -type f \( -name "*.nix" -o -name "*.yaml" -o -name "*.yml" -o -name "*.sh" -o -name "*.org" -o -name "*.md" \) | wc -l | xargs echo "Configuration files:"
find . -name "*.nix" | wc -l | xargs echo "Nix files:"
find . -name "*.yaml" -o -name "*.yml" | wc -l | xargs echo "YAML files:"
find . -name "*.sh" | wc -l | xargs echo "Shell scripts:"
find . -name "*.org" | wc -l | xargs echo "Org files:"
find . -name "*.md" | wc -l | xargs echo "Markdown files:"
echo ""

echo "Repository size:"
du -sh . 2>/dev/null || echo "Could not calculate repository size"
echo ""

# Summary
print_section "SUMMARY"
echo "This Nix flakes repository contains:"
echo "- Home Manager configurations for macOS (MacBook Air/Pro)"
echo "- NixOS configurations for servers and workstations"
echo "- Modular configuration system with reusable components"
echo "- Development toolchains and package definitions"
echo "- Infrastructure as code with inventory-driven deployments"
echo "- Repository catalog for managing multiple projects"
echo "- Comprehensive documentation and deployment scripts"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  END OF INFORMATION DUMP${NC}"
echo -e "${CYAN}========================================${NC}"
