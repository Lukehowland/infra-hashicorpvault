.PHONY: help up down logs status init unseal backup add-project clean

help:
	@echo "🔐 Vault Infrastructure"
	@echo ""
	@echo "Commands:"
	@echo "  make up           Start Vault"
	@echo "  make down         Stop Vault"
	@echo "  make logs         View logs"
	@echo "  make status       Check Vault status"
	@echo "  make init         Initialize Vault (first time only)"
	@echo "  make unseal       Unseal Vault"
	@echo "  make backup       Create backup"
	@echo "  make ui           Open Vault UI in browser"
	@echo ""
	@echo "Add Project:"
	@echo "  make add-project NAME=myproject"
	@echo ""

up:
	@docker-compose up -d
	@echo "✅ Vault started"
	@echo "   UI: http://localhost:8200"

down:
	@docker-compose down
	@echo "✅ Vault stopped"

logs:
	@docker-compose logs -f vault

status:
	@docker exec vault-server vault status || true

init:
	@chmod +x scripts/*.sh
	@./scripts/init.sh

unseal:
	@./scripts/unseal.sh

backup:
	@./scripts/backup.sh

add-project:
ifndef NAME
	@echo "Usage: make add-project NAME=project-name"
else
	@./scripts/add-project.sh $(NAME)
endif

ui:
	@xdg-open http://localhost:8200 2>/dev/null || open http://localhost:8200 2>/dev/null || echo "Open http://localhost:8200 in your browser"

clean:
	@echo "⚠️  This will destroy all Vault data!"
	@read -p "Continue? (y/N) " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		rm -rf secrets/; \
		echo "✅ Vault data destroyed"; \
	else \
		echo "❌ Cancelled"; \
	fi
