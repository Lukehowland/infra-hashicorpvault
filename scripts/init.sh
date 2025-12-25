#!/bin/bash
# ==========================================
# Vault Initialization Script
# ==========================================
# Run this ONLY ONCE when setting up Vault for the first time
# This script will:
#   1. Initialize Vault with 5 unseal keys (threshold 3)
#   2. Save keys securely to a local file
#   3. Unseal Vault
#   4. Enable KV secrets engine
#   5. Apply policies
#   6. Create initial secrets for VicVet
# ==========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"
VAULT_CONTAINER="${VAULT_CONTAINER:-vault-server}"
KEYS_FILE="./secrets/vault-keys.json"
KEYS_DIR="./secrets"

echo -e "${BLUE}=========================================="
echo "   HashiCorp Vault Initialization"
echo -e "==========================================${NC}"
echo ""

# Check if vault is running
echo -e "${YELLOW}[1/7] Checking Vault status...${NC}"
if ! docker ps | grep -q "$VAULT_CONTAINER"; then
    echo -e "${RED}Error: Vault container is not running.${NC}"
    echo "Start it with: docker-compose up -d"
    exit 1
fi

# Check if already initialized
INIT_STATUS=$(docker exec $VAULT_CONTAINER vault status -format=json 2>/dev/null | grep -o '"initialized":[^,]*' | cut -d: -f2 || echo "false")

if [ "$INIT_STATUS" = "true" ]; then
    echo -e "${YELLOW}⚠️  Vault is already initialized.${NC}"
    echo "If you need to reinitialize, destroy the volume first:"
    echo "  docker-compose down -v"
    echo "  docker-compose up -d"
    exit 1
fi

# Create secrets directory
echo -e "${YELLOW}[2/7] Creating secrets directory...${NC}"
mkdir -p "$KEYS_DIR"
chmod 700 "$KEYS_DIR"

# Initialize Vault
echo -e "${YELLOW}[3/7] Initializing Vault...${NC}"
echo "Generating 5 unseal keys with threshold of 3..."
docker exec $VAULT_CONTAINER vault operator init \
    -key-shares=5 \
    -key-threshold=3 \
    -format=json > "$KEYS_FILE"

chmod 600 "$KEYS_FILE"

echo -e "${GREEN}✅ Vault initialized successfully${NC}"
echo ""

# Extract keys
UNSEAL_KEY_1=$(cat "$KEYS_FILE" | grep -o '"unseal_keys_b64":\[[^]]*\]' | sed 's/.*\["\([^"]*\)".*/\1/' | head -1)
UNSEAL_KEY_2=$(cat "$KEYS_FILE" | grep -o '"unseal_keys_b64":\[[^]]*\]' | sed 's/.*","\([^"]*\)".*/\1/' | head -1)
UNSEAL_KEY_3=$(cat "$KEYS_FILE" | grep -o '"unseal_keys_b64":\[[^]]*\]' | sed 's/.*","[^"]*","\([^"]*\)".*/\1/' | head -1)
ROOT_TOKEN=$(cat "$KEYS_FILE" | grep -o '"root_token":"[^"]*"' | cut -d'"' -f4)

# Unseal Vault
echo -e "${YELLOW}[4/7] Unsealing Vault...${NC}"
docker exec $VAULT_CONTAINER vault operator unseal "$UNSEAL_KEY_1" > /dev/null
docker exec $VAULT_CONTAINER vault operator unseal "$UNSEAL_KEY_2" > /dev/null
docker exec $VAULT_CONTAINER vault operator unseal "$UNSEAL_KEY_3" > /dev/null

echo -e "${GREEN}✅ Vault unsealed${NC}"

# Login with root token
echo -e "${YELLOW}[5/7] Configuring Vault...${NC}"
docker exec -e VAULT_TOKEN="$ROOT_TOKEN" $VAULT_CONTAINER vault secrets enable -path=secret kv-v2 2>/dev/null || true

echo -e "${GREEN}✅ KV secrets engine enabled${NC}"

# Apply policies
echo -e "${YELLOW}[6/7] Applying policies...${NC}"
docker exec -e VAULT_TOKEN="$ROOT_TOKEN" $VAULT_CONTAINER vault policy write admin /vault/policies/admin.hcl
docker exec -e VAULT_TOKEN="$ROOT_TOKEN" $VAULT_CONTAINER vault policy write vicvet /vault/policies/vicvet.hcl

echo -e "${GREEN}✅ Policies applied${NC}"

# Create VicVet secrets
echo -e "${YELLOW}[7/7] Creating VicVet secrets...${NC}"

# Generate secure random passwords
DB_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
REDIS_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')

# Store secrets in Vault
docker exec -e VAULT_TOKEN="$ROOT_TOKEN" $VAULT_CONTAINER vault kv put secret/vicvet/database \
    username="vicvet" \
    password="$DB_PASSWORD" \
    host="postgres" \
    port="5432" \
    name="vicvet_db"

docker exec -e VAULT_TOKEN="$ROOT_TOKEN" $VAULT_CONTAINER vault kv put secret/vicvet/redis \
    password="$REDIS_PASSWORD" \
    host="redis" \
    port="6379"

docker exec -e VAULT_TOKEN="$ROOT_TOKEN" $VAULT_CONTAINER vault kv put secret/vicvet/jwt \
    secret="$JWT_SECRET" \
    expiration="86400"

echo -e "${GREEN}✅ VicVet secrets created${NC}"

# Create a token for VicVet application
echo ""
echo -e "${YELLOW}Creating VicVet application token...${NC}"
VICVET_TOKEN=$(docker exec -e VAULT_TOKEN="$ROOT_TOKEN" $VAULT_CONTAINER vault token create \
    -policy=vicvet \
    -ttl=8760h \
    -format=json | grep -o '"client_token":"[^"]*"' | cut -d'"' -f4)

# Save VicVet token separately
echo "$VICVET_TOKEN" > "$KEYS_DIR/vicvet-token.txt"
chmod 600 "$KEYS_DIR/vicvet-token.txt"

echo ""
echo -e "${GREEN}=========================================="
echo "   ✅ Vault Setup Complete!"
echo -e "==========================================${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT - SAVE THESE SECURELY:${NC}"
echo ""
echo "📁 Unseal keys saved to: $KEYS_FILE"
echo "🔑 VicVet token saved to: $KEYS_DIR/vicvet-token.txt"
echo ""
echo "Root Token: $ROOT_TOKEN"
echo ""
echo -e "${RED}⚠️  SECURITY WARNINGS:${NC}"
echo "  1. Store unseal keys in SEPARATE secure locations"
echo "  2. Delete or encrypt $KEYS_FILE after copying keys"
echo "  3. Root token should be revoked after initial setup"
echo "  4. Use VicVet token ($VICVET_TOKEN) in your application"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Access Vault UI: http://localhost:8200"
echo "  2. Login with root token"
echo "  3. Distribute unseal keys to trusted team members"
echo "  4. Configure VicVet with VAULT_TOKEN=$VICVET_TOKEN"
echo ""
echo "To read a secret:"
echo "  docker exec -e VAULT_TOKEN=$VICVET_TOKEN $VAULT_CONTAINER vault kv get secret/vicvet/database"
