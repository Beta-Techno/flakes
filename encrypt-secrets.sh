#!/usr/bin/env bash
# Encrypt secrets from plaintext source
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
SECRETS_DIR="$REPO_ROOT/secrets"

cd "$REPO_ROOT"

# Check if plaintext source exists
if [ ! -f "$SECRETS_DIR/prod.yaml.plaintext" ]; then
    echo "Error: $SECRETS_DIR/prod.yaml.plaintext not found"
    exit 1
fi

# Get all Age recipients from nixos/keys/age/*.txt files
if [ -d "$REPO_ROOT/nixos/keys/age" ] && [ "$(ls -A "$REPO_ROOT/nixos/keys/age"/*.txt 2>/dev/null)" ]; then
    echo "Using Age recipients from nixos/keys/age/*.txt files..."
    # Read all public keys from the age key files
    RECIPIENTS=$(cat "$REPO_ROOT/nixos/keys/age"/*.txt | grep -v '^$' | tr '\n' ',' | sed 's/,$//')
    if [ -z "$RECIPIENTS" ]; then
        echo "❌ No Age keys found in nixos/keys/age/*.txt files"
        exit 1
    fi
    echo "Found keys for: $(ls "$REPO_ROOT/nixos/keys/age"/*.txt | xargs -n1 basename | sed 's/\.txt$//' | tr '\n' ' ')"
elif [ -f "$REPO_ROOT/.sops.yaml" ]; then
    echo "Using Age recipients from .sops.yaml (fallback)..."
    # Extract recipients from .sops.yaml using grep (more reliable than yq)
    RECIPIENTS=$(grep -o 'age1[a-zA-Z0-9]*' "$REPO_ROOT/.sops.yaml" | tr '\n' ',' | sed 's/,$//')
    if [ -z "$RECIPIENTS" ]; then
        echo "❌ No Age keys found in .sops.yaml"
        exit 1
    fi
elif [ -f "$SECRETS_DIR/prod.yaml" ]; then
    echo "Using existing Age recipients from encrypted file..."
    # Extract recipients from existing encrypted file
    RECIPIENTS=$(sops exec-file "$SECRETS_DIR/prod.yaml" 'echo "$SOPS_AGE_RECIPIENTS"')
else
    echo "No age key files, .sops.yaml, or existing encrypted file found."
    echo "You need to either:"
    echo "1. Add public keys to nixos/keys/age/*.txt files, or"
    echo "2. Create a .sops.yaml file with your Age recipients, or"
    echo "3. Specify Age recipients manually:"
    echo "   Example: SOPS_AGE_RECIPIENTS='age1...' $0"
    exit 1
fi

# Encrypt the plaintext file
echo "Encrypting secrets..."
# Temporarily move .sops.yaml to avoid config conflicts
if [ -f "$REPO_ROOT/.sops.yaml" ]; then
    mv "$REPO_ROOT/.sops.yaml" "$REPO_ROOT/.sops.yaml.tmp"
fi

# Encrypt using environment variables
SOPS_AGE_RECIPIENTS="$RECIPIENTS" sops --input-type yaml --output-type yaml -e "$SECRETS_DIR/prod.yaml.plaintext" > "$SECRETS_DIR/prod.yaml"

# Restore .sops.yaml
if [ -f "$REPO_ROOT/.sops.yaml.tmp" ]; then
    mv "$REPO_ROOT/.sops.yaml.tmp" "$REPO_ROOT/.sops.yaml"
fi

echo "✅ Secrets encrypted successfully!"
echo "📁 Encrypted file: $SECRETS_DIR/prod.yaml"
echo "🔒 Plaintext source: $SECRETS_DIR/prod.yaml.plaintext (ignored by git)"