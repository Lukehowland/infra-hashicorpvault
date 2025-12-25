# ==========================================
# VicVet Application Policy
# ==========================================
# Read-only access to VicVet secrets
# This policy should be assigned to the VicVet service
# ==========================================

# Read VicVet secrets (KV v2)
path "secret/data/vicvet/*" {
  capabilities = ["read"]
}

# List VicVet secrets
path "secret/metadata/vicvet/*" {
  capabilities = ["list"]
}

# Renew own token
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Lookup own token
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# ==========================================
# Denied Paths (explicit deny for security)
# ==========================================

# Cannot read other projects' secrets
path "secret/data/+/*" {
  capabilities = ["deny"]
}

# Override: Allow only vicvet
path "secret/data/vicvet/*" {
  capabilities = ["read"]
}
