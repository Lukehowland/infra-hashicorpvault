# 🔐 HashiCorp Vault Infrastructure

Gestión centralizada de secrets para todos mis proyectos.

## 📋 Quick Start

### First Time Setup

```bash
make up          # 1. Start Vault
make init        # 2. Initialize & Unseal (first time only)
make setup-admin # 3. (Optional) Create admin user for Web UI
make ui          # 4. Open Web UI
```

### After Restart

```bash
make up          # Start Vault
make unseal      # Unseal (required after every restart)
```

### Available Commands

```bash
make help        # See all available commands
```

## 🏗️ Project Structure

```
vault/
├── config/
│   └── vault.hcl                  # Vault server configuration
├── policies/
│   ├── admin.hcl                  # Full admin access
│   ├── readonly.hcl               # Read-only access template
│   └── example-app.hcl.template   # Template for new app policies
├── scripts/
│   ├── unseal.sh                  # Unseal after restart
│   ├── setup-admin.sh             # Create admin user for Web UI
│   ├── add-project.sh             # Add new project with secrets
│   ├── backup.sh                  # Backup Vault data
│   └── read-secret.sh             # Read secrets helper
├── secrets/                       # ⚠️ NOT committed to git
│   ├── vault-keys.json            # Unseal keys & root token
│   └── *-token.txt                # Application tokens
├── backups/                       # ⚠️ NOT committed to git
├── docker-compose.yml
├── .gitignore
└── README.md
```

## 🔑 Understanding Vault Concepts

### Unseal Keys

Vault starts in a **sealed** state. To unseal it, you need 3 of 5 keys.
This is called [Shamir's Secret Sharing](https://en.wikipedia.org/wiki/Shamir%27s_Secret_Sharing).

```
Key 1: Person A (CTO)
Key 2: Person B (DevOps Lead)
Key 3: Person C (Security)
Key 4: Backup in safe
Key 5: Backup in bank vault
```

### Tokens

- **Root Token**: Full access, use only for initial setup
- **Admin Token**: For operators
- **App Tokens**: Limited to specific secrets (e.g., VicVet can only read vicvet/*)

### Policies

Define what each token can access:

```hcl
# VicVet can only read its own secrets
path "secret/data/vicvet/*" {
  capabilities = ["read"]
}
```

## 📁 Managing Secrets

### Read a Secret

```bash
# Using helper script
./scripts/read-secret.sh vicvet database

# Or manually
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=<your-token>
vault kv get secret/vicvet/database
```

### Write a Secret

```bash
vault kv put secret/vicvet/new-secret \
    key1="value1" \
    key2="value2"
```

### List Secrets

```bash
vault kv list secret/vicvet/
```

## 👤 Setting Up Admin User

For human administrators to access the Web UI with username/password:

```bash
./scripts/setup-admin.sh
```

This will:

1. Enable userpass authentication
2. Create an admin user with the `admin` policy
3. Allow login via Web UI or CLI

**Login options:**

- **Web UI**: <http://localhost:8200> → Method: Username
- **CLI**: `vault login -method=userpass username=<your-username>`

## 🆕 Adding a New Project

```bash
./scripts/add-project.sh my-new-project
```

This will:

1. Create a policy file
2. Apply the policy to Vault
3. Generate secure secrets
4. Create an application token
5. Save the token to `secrets/my-new-project-token.txt`

## 💾 Backup & Restore

### Backup

```bash
./scripts/backup.sh
```

### Restore

```bash
# 1. Stop Vault
docker-compose down

# 2. Remove old data
docker volume rm vault-data

# 3. Create new volume
docker volume create vault-data

# 4. Restore from backup
docker run --rm \
    -v vault-data:/vault/data \
    -v $(pwd)/backups:/backup \
    alpine:3.19 \
    tar -xzf /backup/vault-backup-YYYYMMDD-HHMMSS.tar.gz -C /vault

# 5. Start and unseal
docker-compose up -d
./scripts/unseal.sh
```

## 🔒 Security Best Practices

1. **Unseal Keys**: Store in separate secure locations
2. **Root Token**: Revoke after initial setup, generate new one when needed
3. **TLS**: Enable in production (see `config/vault.hcl`)
4. **Audit Logging**: Enable for compliance
5. **Token TTL**: Use short-lived tokens when possible
6. **Backup**: Regular encrypted backups

## 🔧 Production Checklist

- [ ] Enable TLS (see `config/vault.hcl`)
- [ ] Distribute unseal keys to different people
- [ ] Revoke root token
- [ ] Enable audit logging
- [ ] Set up automated backup
- [ ] Configure monitoring/alerting
- [ ] Document recovery procedures

## 🌐 Connecting Your Application

### Option 1: Environment Variable

```bash
# In your application
export VAULT_ADDR=http://vault:8200
export VAULT_TOKEN=$(cat secrets/vicvet-token.txt)
```

### Option 2: Vault Agent (Advanced)

For production, use [Vault Agent](https://developer.hashicorp.com/vault/docs/agent) to:

- Auto-renew tokens
- Cache secrets
- Template secrets to files

### Option 3: SDK

Use official SDKs:

- [Rust](https://crates.io/crates/vaultrs)
- [Go](https://github.com/hashicorp/vault/tree/main/api)
- [Node.js](https://github.com/kr1sp1n/node-vault)

## 📚 Resources

- [Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Best Practices](https://developer.hashicorp.com/vault/docs/concepts/policies#best-practices)
- [Kubernetes Integration](https://developer.hashicorp.com/vault/docs/platform/k8s)

## ⚠️ Troubleshooting

### Vault is sealed after restart

```bash
./scripts/unseal.sh
```

### Lost unseal keys

If you've lost your unseal keys and `secrets/vault-keys.json`:

1. You cannot recover the existing data
2. You must reinitialize: `docker-compose down -v && docker-compose up -d`

### Permission denied

Check that your token has the correct policy:

```bash
vault token lookup
```

---

**Created for**: VicVet & future projects  
**Vault Version**: 1.15
