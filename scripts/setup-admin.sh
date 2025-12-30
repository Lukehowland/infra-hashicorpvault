#!/bin/bash
# ==========================================
# Setup Admin User for Vault
# ==========================================
# Creates a userpass authentication for human admins
# Usage: ./setup-admin.sh
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
echo "   Vault Admin User Setup"
echo -e "==========================================${NC}"
echo ""

# Check if Vault is running and unsealed
if ! docker ps | grep -q "$VAULT_CONTAINER"; then
    echo -e "${RED}Error: Vault container is not running.${NC}"
    echo "Start it with: docker compose up -d"
    exit 1
fi

SEALED=$(docker exec "$VAULT_CONTAINER" vault status -format=json 2>/dev/null | grep -o '"sealed":[^,]*' | cut -d: -f2)
if [ "$SEALED" = "true" ]; then
    echo -e "${RED}Error: Vault is sealed.${NC}"
    echo "Unseal it with: make unseal"
    exit 1
fi

# Get root token
if [ ! -f "$KEYS_FILE" ]; then
    echo -e "${RED}Error: Keys file not found: $KEYS_FILE${NC}"
    exit 1
fi

if command -v jq &> /dev/null; then
    ROOT_TOKEN=$(jq -r '.root_token' "$KEYS_FILE")
elif command -v python3 &> /dev/null; then
    ROOT_TOKEN=$(python3 -c "import json; print(json.load(open('$KEYS_FILE'))['root_token'])")
else
    echo -e "${RED}Error: Neither jq nor python3 available${NC}"
    exit 1
fi

echo -e "${YELLOW}Setting up admin user authentication...${NC}"
echo ""

# Get username
read -p "Enter admin username: " ADMIN_USER
if [ -z "$ADMIN_USER" ]; then
    echo -e "${RED}Error: Username cannot be empty${NC}"
    exit 1
fi

# Get password (hidden input)
read -sp "Enter password for $ADMIN_USER: " ADMIN_PASS
echo ""
read -sp "Confirm password: " ADMIN_PASS_CONFIRM
echo ""

if [ "$ADMIN_PASS" != "$ADMIN_PASS_CONFIRM" ]; then
    echo -e "${RED}Error: Passwords do not match${NC}"
    exit 1
fi

if [ ${#ADMIN_PASS} -lt 8 ]; then
    echo -e "${RED}Error: Password must be at least 8 characters${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}[1/2] Enabling userpass authentication...${NC}"

# Enable userpass auth (ignore if already enabled)
docker exec -e VAULT_TOKEN="$ROOT_TOKEN" "$VAULT_CONTAINER" \
    vault auth enable userpass 2>/dev/null || echo "  (userpass already enabled)"

echo -e "${GREEN}✅ Userpass auth enabled${NC}"

echo -e "${YELLOW}[2/2] Creating admin user...${NC}"

# Create user with admin policy
docker exec -e VAULT_TOKEN="$ROOT_TOKEN" "$VAULT_CONTAINER" \
    vault write "auth/userpass/users/$ADMIN_USER" \
    password="$ADMIN_PASS" \
    policies="admin"

echo -e "${GREEN}✅ Admin user created${NC}"

# Clear password from memory
unset ADMIN_PASS
unset ADMIN_PASS_CONFIRM

echo ""
echo -e "${GREEN}=========================================="
echo "   ✅ Admin User Setup Complete!"
echo -e "==========================================${NC}"
echo ""
echo -e "${BLUE}You can now login with:${NC}"
echo ""
echo "  1. Web UI: http://localhost:8200"
echo "     → Method: Username"
echo "     → Username: $ADMIN_USER"
echo "     → Password: (your password)"
echo ""
echo "  2. CLI:"
echo "     vault login -method=userpass username=$ADMIN_USER"
echo ""
echo -e "${YELLOW}⚠️  Note: Your password is NOT stored anywhere.${NC}"
echo "    If you forget it, run this script again to reset."
