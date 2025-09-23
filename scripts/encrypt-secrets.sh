#!/usr/bin/env bash
# Encrypt secrets from plaintext source
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SECRETS_DIR="$REPO_ROOT/secrets"

cd "$REPO_ROOT"

# Check if plaintext source exists
if [ ! -f "$SECRETS_DIR/prod.yaml.plaintext" ]; then
    echo "Error: $SECRETS_DIR/prod.yaml.plaintext not found"
    exit 1
fi

# Get all Age recipients from existing encrypted file or generate new ones
if [ -f "$SECRETS_DIR/prod.yaml" ]; then
    echo "Using existing Age recipients from encrypted file..."
    # Extract recipients from existing encrypted file
    RECIPIENTS=$(sops exec-file "$SECRETS_DIR/prod.yaml" 'echo "$SOPS_AGE_RECIPIENTS"')
else
    echo "No existing encrypted file found. You need to specify Age recipients."
    echo "Example: SOPS_AGE_RECIPIENTS='age1...' $0"
    exit 1
fi

# Encrypt the plaintext file
echo "Encrypting secrets..."
SOPS_AGE_RECIPIENTS="$RECIPIENTS" sops -i -e "$SECRETS_DIR/prod.yaml.plaintext"

# Move the encrypted file to the final location
mv "$SECRETS_DIR/prod.yaml.plaintext" "$SECRETS_DIR/prod.yaml"

echo "✅ Secrets encrypted successfully!"
echo "📁 Encrypted file: $SECRETS_DIR/prod.yaml"
echo "🔒 Plaintext source: $SECRETS_DIR/prod.yaml.plaintext (ignored by git)"
