#!/bin/bash
# ==========================================
# Read Secret Helper
# ==========================================
# Quick way to read secrets from Vault
# Usage: ./read-secret.sh <project> <path>
# Example: ./read-secret.sh vicvet database
# ==========================================

set -e

VAULT_CONTAINER="${VAULT_CONTAINER:-vault-server}"

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <project> <path>"
    echo "Example: $0 vicvet database"
    exit 1
fi

PROJECT="$1"
SECRET_PATH="$2"
TOKEN_FILE="./secrets/${PROJECT}-token.txt"

if [ -f "$TOKEN_FILE" ]; then
    TOKEN=$(cat "$TOKEN_FILE")
else
    echo "Token file not found: $TOKEN_FILE"
    read -sp "Enter token for $PROJECT: " TOKEN
    echo ""
fi

echo ""
echo "Reading secret/${PROJECT}/${SECRET_PATH}:"
echo "=========================================="
docker exec -e VAULT_TOKEN="$TOKEN" $VAULT_CONTAINER \
    vault kv get "secret/${PROJECT}/${SECRET_PATH}"
