# ==========================================
# Read-Only Policy Template
# ==========================================
# Template for read-only access to specific paths
# Copy and modify for new applications
# ==========================================

# Example: Read secrets for a specific app
# path "secret/data/APP_NAME/*" {
#   capabilities = ["read"]
# }

# List secrets metadata
# path "secret/metadata/APP_NAME/*" {
#   capabilities = ["list"]
# }

# Self-service token operations
path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
