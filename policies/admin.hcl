# ==========================================
# Vault Admin Policy
# ==========================================
# Official HashiCorp recommended admin policy
# Source: https://developer.hashicorp.com/vault/tutorials/policies/policies
# ==========================================

# Read system health check
path "sys/health" {
  capabilities = ["read", "sudo"]
}

# List existing policies
path "sys/policies/acl" {
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage auth methods broadly across Vault
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*" {
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth" {
  capabilities = ["read"]
}

# List, create, update, and delete key/value secrets
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines (enable/disable database, kv, etc.)
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines
path "sys/mounts" {
  capabilities = ["read"]
}

# ==========================================
# Additional permissions for database engine
# ==========================================

# Manage database secrets engine
path "database/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage leases (for dynamic secrets)
path "sys/leases/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage tokens
path "auth/token/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage identity (entities, groups)
path "identity/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
