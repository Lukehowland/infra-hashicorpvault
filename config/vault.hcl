# ==========================================
# HashiCorp Vault Server Configuration
# ==========================================
# Production-ready configuration
# Documentation: https://developer.hashicorp.com/vault/docs/configuration
# ==========================================

# ==========================================
# Storage Backend
# ==========================================
# File storage - suitable for single-node deployments
# For HA, consider Consul, PostgreSQL, or Raft
storage "file" {
  path = "/vault/data"
}

# ==========================================
# Listener Configuration
# ==========================================
listener "tcp" {
  address         = "0.0.0.0:8200"
  
  # TLS Configuration
  # In production, ALWAYS enable TLS
  # For local development, we disable it
  tls_disable = 1
  
  # Production TLS settings (uncomment and configure):
  # tls_disable     = 0
  # tls_cert_file   = "/vault/tls/vault.crt"
  # tls_key_file    = "/vault/tls/vault.key"
  # tls_min_version = "tls12"
  
  # Telemetry for monitoring
  telemetry {
    unauthenticated_metrics_access = false
  }
}

# ==========================================
# API Configuration
# ==========================================
api_addr = "http://0.0.0.0:8200"
cluster_addr = "https://0.0.0.0:8201"

# ==========================================
# UI Configuration
# ==========================================
ui = true

# ==========================================
# Telemetry & Monitoring
# ==========================================
telemetry {
  disable_hostname = true
  prometheus_retention_time = "30s"
}

# ==========================================
# Performance & Limits
# ==========================================
# Maximum request duration
default_lease_ttl = "768h"    # 32 days
max_lease_ttl     = "8760h"   # 1 year

# Rate limiting (requests per second)
# Uncomment in production to prevent DoS
# max_request_per_second = 1000

# ==========================================
# Security Hardening
# ==========================================
# Disable memory lock warning (handled by IPC_LOCK)
disable_mlock = false

# Log level
log_level = "info"

# Log format (json for production, standard for dev)
log_format = "json"

# ==========================================
# Audit Logging (Enterprise Feature)
# ==========================================
# Enable file audit in production
# audit {
#   type = "file"
#   path = "/vault/logs/audit.log"
# }
