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
    echo "Start it with: docker-compose up -d"
    exit 1
fi

# Check current status
SEALED=$(docker exec $VAULT_CONTAINER vault status -format=json 2>/dev/null | grep -o '"sealed":[^,]*' | cut -d: -f2)

if [ "$SEALED" = "false" ]; then
    echo -e "${GREEN}✅ Vault is already unsealed${NC}"
    exit 0
fi

echo -e "${YELLOW}Vault is sealed. Starting unseal process...${NC}"
echo ""

# Check if we have keys file
if [ -f "$KEYS_FILE" ]; then
    echo "Found keys file. Using automated unseal..."
    
    # Extract keys from JSON (basic parsing)
    KEYS=$(cat "$KEYS_FILE" | grep -o '"unseal_keys_b64":\[[^]]*\]' | sed 's/"unseal_keys_b64":\[//;s/\]//;s/"//g;s/,/ /g')
    KEY_ARRAY=($KEYS)
    
    # Unseal with first 3 keys
    for i in 0 1 2; do
        echo "Applying unseal key $((i+1))/3..."
        docker exec $VAULT_CONTAINER vault operator unseal "${KEY_ARRAY[$i]}" > /dev/null
    done
    
    echo ""
    echo -e "${GREEN}✅ Vault unsealed successfully${NC}"
else
    echo -e "${YELLOW}No keys file found. Manual unseal required.${NC}"
    echo ""
    echo "Enter 3 unseal keys (from your secure storage):"
    echo ""
    
    for i in 1 2 3; do
        read -sp "Unseal Key $i: " KEY
        echo ""
        docker exec $VAULT_CONTAINER vault operator unseal "$KEY" > /dev/null
    done
    
    echo ""
    echo -e "${GREEN}✅ Vault unsealed successfully${NC}"
fi

# Show status
echo ""
echo -e "${BLUE}Current Vault Status:${NC}"
docker exec $VAULT_CONTAINER vault status
