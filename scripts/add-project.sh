#!/bin/bash
# ==========================================
# Add New Project to Vault
# ==========================================
# Creates secrets and policy for a new application
# Usage: ./add-project.sh <project-name>
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

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 <project-name>${NC}"
    echo "Example: $0 ecommerce"
    exit 1
fi

PROJECT_NAME="$1"
PROJECT_NAME_LOWER=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')

echo -e "${BLUE}=========================================="
echo "   Adding Project: $PROJECT_NAME"
echo -e "==========================================${NC}"
echo ""

# Get root token
if [ -f "$KEYS_FILE" ]; then
    ROOT_TOKEN=$(cat "$KEYS_FILE" | grep -o '"root_token":"[^"]*"' | cut -d'"' -f4)
else
    read -sp "Enter root token: " ROOT_TOKEN
    echo ""
fi

# Create policy file
echo -e "${YELLOW}[1/4] Creating policy...${NC}"
cat > "./policies/${PROJECT_NAME_LOWER}.hcl" << EOF
# ==========================================
# ${PROJECT_NAME} Application Policy
# ==========================================
# Auto-generated policy for ${PROJECT_NAME}
# ==========================================

# Read ${PROJECT_NAME} secrets (KV v2)
path "secret/data/${PROJECT_NAME_LOWER}/*" {
  capabilities = ["read"]
}

# List ${PROJECT_NAME} secrets
path "secret/metadata/${PROJECT_NAME_LOWER}/*" {
  capabilities = ["list"]
}

# Self-service token operations
path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

echo -e "${GREEN}✅ Policy file created: ./policies/${PROJECT_NAME_LOWER}.hcl${NC}"

# Apply policy
echo -e "${YELLOW}[2/4] Applying policy to Vault...${NC}"
docker exec -e VAULT_TOKEN="$ROOT_TOKEN" $VAULT_CONTAINER \
    vault policy write "$PROJECT_NAME_LOWER" "/vault/policies/${PROJECT_NAME_LOWER}.hcl"

echo -e "${GREEN}✅ Policy applied${NC}"

# Generate and store secrets
echo -e "${YELLOW}[3/4] Creating secrets...${NC}"

DB_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
API_KEY=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
SECRET_KEY=$(openssl rand -base64 64 | tr -d '\n')

docker exec -e VAULT_TOKEN="$ROOT_TOKEN" $VAULT_CONTAINER \
    vault kv put "secret/${PROJECT_NAME_LOWER}/database" \
    username="${PROJECT_NAME_LOWER}" \
    password="$DB_PASSWORD" \
    host="postgres" \
    port="5432" \
    name="${PROJECT_NAME_LOWER}_db"

docker exec -e VAULT_TOKEN="$ROOT_TOKEN" $VAULT_CONTAINER \
    vault kv put "secret/${PROJECT_NAME_LOWER}/app" \
    api_key="$API_KEY" \
    secret_key="$SECRET_KEY"

echo -e "${GREEN}✅ Secrets created${NC}"

# Create application token
echo -e "${YELLOW}[4/4] Creating application token...${NC}"

APP_TOKEN=$(docker exec -e VAULT_TOKEN="$ROOT_TOKEN" $VAULT_CONTAINER \
    vault token create \
    -policy="$PROJECT_NAME_LOWER" \
    -ttl=8760h \
    -format=json | grep -o '"client_token":"[^"]*"' | cut -d'"' -f4)

# Save token
echo "$APP_TOKEN" > "./secrets/${PROJECT_NAME_LOWER}-token.txt"
chmod 600 "./secrets/${PROJECT_NAME_LOWER}-token.txt"

echo -e "${GREEN}✅ Token created and saved${NC}"

echo ""
echo -e "${GREEN}=========================================="
echo "   ✅ Project $PROJECT_NAME Added!"
echo -e "==========================================${NC}"
echo ""
echo "Token saved to: ./secrets/${PROJECT_NAME_LOWER}-token.txt"
echo ""
echo "To use in your application:"
echo "  export VAULT_ADDR=http://localhost:8200"
echo "  export VAULT_TOKEN=$APP_TOKEN"
echo ""
echo "To read secrets:"
echo "  vault kv get secret/${PROJECT_NAME_LOWER}/database"
echo "  vault kv get secret/${PROJECT_NAME_LOWER}/app"
