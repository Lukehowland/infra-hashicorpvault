#!/bin/bash
# ==========================================
# Vault Unseal Script
# ==========================================
# Run this script after Vault restarts
# Requires 3 of 5 unseal keys
# ==========================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VAULT_CONTAINER="${VAULT_CONTAINER:-vault-server}"
KEYS_FILE="./secrets/vault-keys.json"

echo -e "${BLUE}=========================================="
echo "   Vault Unseal Process"
echo -e "==========================================${NC}"
echo ""

# Check if Vault is running
if ! docker ps | grep -q "$VAULT_CONTAINER"; then
    echo -e "${RED}Error: Vault container is not running.${NC}"
    echo "Start it with: docker compose up -d"
    exit 1
fi

# Check current status
SEALED=$(docker exec "$VAULT_CONTAINER" vault status -format=json 2>/dev/null | grep -o '"sealed":[^,]*' | cut -d: -f2)

if [ "$SEALED" = "false" ]; then
    echo -e "${GREEN}✅ Vault is already unsealed${NC}"
    exit 0
fi

echo -e "${YELLOW}Vault is sealed. Starting unseal process...${NC}"
echo ""

# Check if we have keys file
if [ -f "$KEYS_FILE" ]; then
    echo "Found keys file. Using automated unseal..."
    
    # Extract keys using jq or python3 (reliable JSON parsing)
    if command -v jq &> /dev/null; then
        KEY1=$(jq -r '.unseal_keys_b64[0]' "$KEYS_FILE")
        KEY2=$(jq -r '.unseal_keys_b64[1]' "$KEYS_FILE")
        KEY3=$(jq -r '.unseal_keys_b64[2]' "$KEYS_FILE")
    elif command -v python3 &> /dev/null; then
        KEY1=$(python3 -c "import json; print(json.load(open('$KEYS_FILE'))['unseal_keys_b64'][0])")
        KEY2=$(python3 -c "import json; print(json.load(open('$KEYS_FILE'))['unseal_keys_b64'][1])")
        KEY3=$(python3 -c "import json; print(json.load(open('$KEYS_FILE'))['unseal_keys_b64'][2])")
    else
        echo -e "${RED}Error: Neither jq nor python3 available for JSON parsing${NC}"
        exit 1
    fi
    
    # Verify keys were extracted
    if [ -z "$KEY1" ]; then
        echo -e "${RED}Error: Failed to extract keys from $KEYS_FILE${NC}"
        exit 1
    fi
    
    # Unseal with first 3 keys (non-interactive)
    echo "Applying unseal key 1/3..."
    docker exec "$VAULT_CONTAINER" vault operator unseal "$KEY1" > /dev/null
    echo "Applying unseal key 2/3..."
    docker exec "$VAULT_CONTAINER" vault operator unseal "$KEY2" > /dev/null
    echo "Applying unseal key 3/3..."
    docker exec "$VAULT_CONTAINER" vault operator unseal "$KEY3" > /dev/null
    
    echo ""
    echo -e "${GREEN}✅ Vault unsealed successfully${NC}"
else
    echo -e "${RED}Error: Keys file not found: $KEYS_FILE${NC}"
    echo "Run 'make init' first to initialize Vault"
    exit 1
fi

# Show status
echo ""
echo -e "${BLUE}Current Vault Status:${NC}"
docker exec "$VAULT_CONTAINER" vault status
