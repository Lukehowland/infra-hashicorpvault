# 📋 TODO - Vault Infrastructure

> Pendientes y decisiones técnicas para esta infraestructura.
> Última revisión: 2025-12-29

---

## 🔴 Bloqueantes para Producción

Estas tareas DEBEN completarse antes de exponer Vault a una red real.

- [ ] **Habilitar TLS**
  - Archivo: `config/vault.hcl` líneas 26-32
  - Por qué: Sin TLS, tokens y secrets viajan en texto plano
  - Cómo: Certificado autofirmado para desarrollo, Let's Encrypt para producción

- [ ] **Distribuir Unseal Keys**
  - Actualmente todas las keys están en `secrets/vault-keys.json`
  - En producción: Distribuir 5 keys a diferentes personas/ubicaciones
  - Regla: Ninguna persona debe tener acceso a 3+ keys

- [ ] **Revocar Root Token después del setup**
  - El root token en `vault-keys.json` tiene acceso TOTAL
  - Después de crear usuarios admin, revocar con: `vault token revoke <root-token>`

---

## 🟡 Mejoras Recomendadas

Mejoran la seguridad y operación, pero no son bloqueantes.

- [ ] **Reducir Lease TTL**
  - Actual: `default_lease_ttl = 768h` (32 días)
  - Recomendado: `24h` para producción
  - Archivo: `config/vault.hcl` línea 63

- [ ] **Habilitar Rate Limiting**
  - Previene ataques DoS
  - Descomentar `max_request_per_second` en `config/vault.hcl`

- [ ] **Configurar Audit Logging**
  - Para compliance y debugging
  - Descomentar sección "Audit Logging" en `config/vault.hcl`

- [ ] **Backup Automatizado**
  - Actualmente: Manual con `make backup`
  - Ideal: Cron job o servicio de backup

---

## 🟢 Nice to Have

Mejoras futuras que agregarían valor.

- [ ] **Auto-Unseal con Cloud KMS**
  - Elimina necesidad de unseal keys manuales
  - Opciones: AWS KMS, GCP KMS, Azure Key Vault
  - Requiere cuenta cloud

- [ ] **Vault Agent para Aplicaciones**
  - Renovación automática de tokens
  - Caching de secrets
  - Template de secrets a archivos

- [ ] **Métricas y Alertas**
  - Prometheus integration (ya configurado en vault.hcl)
  - Alertas para: sealed state, token expiration, failed auth

- [ ] **HA (High Availability)**
  - Actualmente: Single node con file storage
  - Producción crítica: Raft storage con 3+ nodos

---

## ✅ Completado

Mover items aquí cuando estén listos.

- [x] Setup inicial con Docker
- [x] Scripts de unseal, backup, add-project
- [x] Políticas de admin y apps
- [x] Autenticación userpass para admins
- [x] Documentación README

---

## 📝 Decisiones Técnicas

Registro de por qué se tomaron ciertas decisiones.

| Decisión | Razón | Fecha |
|----------|-------|-------|
| TLS deshabilitado | Solo desarrollo local | 2025-12-25 |
| File storage vs Raft | Simplicidad para single-node | 2025-12-25 |
| Shamir 3-of-5 | Balance seguridad/usabilidad | 2025-12-25 |
| Lease TTL largo | Desarrollo, evitar re-auth constante | 2025-12-25 |
