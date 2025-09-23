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

# Get all Age recipients from existing encrypted file or from .sops.yaml
if [ -f "$SECRETS_DIR/prod.yaml" ]; then
    echo "Using existing Age recipients from encrypted file..."
    # Extract recipients from existing encrypted file
    RECIPIENTS=$(sops exec-file "$SECRETS_DIR/prod.yaml" 'echo "$SOPS_AGE_RECIPIENTS"')
elif [ -f "$REPO_ROOT/.sops.yaml" ]; then
    echo "Using Age recipients from .sops.yaml..."
    # Extract recipients from .sops.yaml using grep (more reliable than yq)
    RECIPIENTS=$(grep -o 'age1[a-zA-Z0-9]*' "$REPO_ROOT/.sops.yaml" | tr '\n' ',' | sed 's/,$//')
    if [ -z "$RECIPIENTS" ]; then
        echo "❌ No Age keys found in .sops.yaml"
        exit 1
    fi
else
    echo "No existing encrypted file or .sops.yaml found."
    echo "You need to specify Age recipients manually:"
    echo "Example: SOPS_AGE_RECIPIENTS='age1...' $0"
    echo ""
    echo "Or create a .sops.yaml file with your Age recipients."
    exit 1
fi

# Encrypt the plaintext file
echo "Encrypting secrets..."
SOPS_AGE_RECIPIENTS="$RECIPIENTS" sops --input-type yaml --output-type yaml -e "$SECRETS_DIR/prod.yaml.plaintext" > "$SECRETS_DIR/prod.yaml"

echo "✅ Secrets encrypted successfully!"
echo "📁 Encrypted file: $SECRETS_DIR/prod.yaml"
echo "🔒 Plaintext source: $SECRETS_DIR/prod.yaml.plaintext (ignored by git)"