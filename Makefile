.PHONY: help up down logs status init unseal setup-admin backup add-project read-secret ui clean

help:
	@echo "🔐 Vault Infrastructure"
	@echo ""
	@echo "Lifecycle:"
	@echo "  make up              Start Vault"
	@echo "  make down            Stop Vault"
	@echo "  make logs            View logs"
	@echo "  make status          Check Vault status"
	@echo ""
	@echo "First Time Setup:"
	@echo "  make init            Initialize Vault (run ONLY ONCE)"
	@echo ""
	@echo "Operations:"
	@echo "  make unseal          Unseal Vault (required after restart)"
	@echo "  make setup-admin     Create admin user for Web UI"
	@echo "  make backup          Create encrypted backup"
	@echo "  make ui              Open Vault UI in browser"
	@echo ""
	@echo "Projects:"
	@echo "  make add-project NAME=myproject    Add new project with secrets"
	@echo "  make read-secret PROJECT=x PATH=y  Read a secret"
	@echo ""
	@echo "Danger Zone:"
	@echo "  make clean           Destroy all Vault data"
	@echo ""

up:
	@docker-compose up -d
	@echo "✅ Vault started"
	@echo "   UI: http://localhost:8200"
	@echo ""
	@echo "ℹ️  First time? Run: make init"
	@echo "   After restart? Run: make unseal"

down:
	@docker-compose down
	@echo "✅ Vault stopped"

logs:
	@docker-compose logs -f vault

status:
	@docker exec vault-server vault status || true

init:
	@echo "🔐 Initializing Vault..."
	@echo ""
	@echo "⏳ Waiting for Vault to be ready..."
	@sleep 5
	@mkdir -p secrets
	@docker exec vault-server vault operator init -format=json > secrets/vault-keys.json
	@chmod 600 secrets/vault-keys.json
	@echo ""
	@echo "✅ Vault initialized!"
	@echo "   Keys saved to: secrets/vault-keys.json"
	@echo ""
	@echo "⚠️  IMPORTANT: Keep vault-keys.json safe! It contains your unseal keys and root token."
	@echo ""
	@echo "🔓 Now unsealing Vault..."
	@./scripts/unseal.sh

unseal:
	@./scripts/unseal.sh

setup-admin:
	@./scripts/setup-admin.sh

backup:
	@./scripts/backup.sh

add-project:
ifndef NAME
	@echo "Usage: make add-project NAME=project-name"
	@echo "Example: make add-project NAME=ecommerce"
else
	@./scripts/add-project.sh $(NAME)
endif

read-secret:
ifndef PROJECT
	@echo "Usage: make read-secret PROJECT=project-name PATH=secret-path"
	@echo "Example: make read-secret PROJECT=vicvet PATH=database"
else ifndef PATH
	@echo "Usage: make read-secret PROJECT=project-name PATH=secret-path"
	@echo "Example: make read-secret PROJECT=vicvet PATH=database"
else
	@./scripts/read-secret.sh $(PROJECT) $(PATH)
endif

ui:
	@xdg-open http://localhost:8200 2>/dev/null || open http://localhost:8200 2>/dev/null || echo "Open http://localhost:8200 in your browser"

clean:
	@echo "⚠️  This will destroy all Vault data!"
	@read -p "Continue? (y/N) " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		rm -rf secrets/ backups/; \
		echo "✅ Vault data destroyed"; \
	else \
		echo "❌ Cancelled"; \
	fi
