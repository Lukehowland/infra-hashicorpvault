#!/bin/bash
# ==========================================
# Vault Backup Script
# ==========================================
# Creates encrypted backup of Vault data
# Usage: ./backup.sh
# ==========================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="vault-backup-${TIMESTAMP}"

echo -e "${BLUE}=========================================="
echo "   Vault Backup"
echo -e "==========================================${NC}"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if Vault is running
if ! docker ps | grep -q "vault-server"; then
    echo -e "${RED}Error: Vault container is not running.${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/3] Exporting Vault data...${NC}"

# Copy data from volume
docker run --rm \
    -v vault-data:/vault/data:ro \
    -v "$(pwd)/$BACKUP_DIR":/backup \
    alpine:3.19 \
    tar -czf "/backup/${BACKUP_NAME}.tar.gz" -C /vault data

echo -e "${GREEN}✅ Data exported${NC}"

# Optional: Encrypt backup
echo -e "${YELLOW}[2/3] Encrypting backup (optional)...${NC}"
read -p "Encrypt backup with GPG? (y/N): " ENCRYPT

if [[ "$ENCRYPT" =~ ^[Yy]$ ]]; then
    read -p "Enter GPG recipient email: " GPG_EMAIL
    gpg -e -r "$GPG_EMAIL" "$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
    rm "$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
    BACKUP_FILE="${BACKUP_NAME}.tar.gz.gpg"
    echo -e "${GREEN}✅ Backup encrypted${NC}"
else
    BACKUP_FILE="${BACKUP_NAME}.tar.gz"
    echo "Skipped encryption"
fi

# Cleanup old backups (keep last 7)
echo -e "${YELLOW}[3/3] Cleaning old backups...${NC}"
cd "$BACKUP_DIR"
ls -t vault-backup-* 2>/dev/null | tail -n +8 | xargs -r rm --
cd - > /dev/null

echo ""
echo -e "${GREEN}=========================================="
echo "   ✅ Backup Complete!"
echo -e "==========================================${NC}"
echo ""
echo "Backup saved to: $BACKUP_DIR/$BACKUP_FILE"
echo ""
echo "To restore:"
echo "  1. Stop Vault: docker-compose down"
echo "  2. Delete volume: docker volume rm vault-data"
echo "  3. Recreate volume: docker volume create vault-data"
echo "  4. Extract backup to volume"
echo "  5. Start Vault: docker-compose up -d"
echo "  6. Unseal: ./scripts/unseal.sh"
