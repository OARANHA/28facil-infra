# =====================================================
# Makefile - 28Facil Infra
# =====================================================

.PHONY: help deploy start stop restart logs status shell mysql backup clean healthcheck

# Detectar Docker Compose
DOCKER_COMPOSE := $(shell docker compose version > /dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

help: ## Mostrar ajuda
	@echo ""
	@echo "🐳 28Facil Infra - Comandos Disponíveis"
	@echo "========================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

deploy: ## Fazer deploy completo
	@chmod +x deploy.sh
	@./deploy.sh

start: ## Iniciar containers
	@$(DOCKER_COMPOSE) up -d
	@echo "✅ Containers iniciados"

stop: ## Parar containers
	@$(DOCKER_COMPOSE) stop
	@echo "✅ Containers parados"

restart: ## Reiniciar containers
	@$(DOCKER_COMPOSE) restart
	@echo "✅ Containers reiniciados"

logs: ## Ver logs em tempo real
	@$(DOCKER_COMPOSE) logs -f

logs-api: ## Ver logs apenas da API
	@$(DOCKER_COMPOSE) logs -f api-server

logs-mysql: ## Ver logs apenas do MySQL
	@$(DOCKER_COMPOSE) logs -f mysql

status: ## Ver status dos containers
	@$(DOCKER_COMPOSE) ps

shell: ## Abrir shell no container da API
	@$(DOCKER_COMPOSE) exec api-server /bin/bash

mysql: ## Abrir MySQL CLI
	@$(DOCKER_COMPOSE) exec mysql mysql -u root -p

backup: ## Fazer backup do banco
	@chmod +x backup.sh
	@./backup.sh

healthcheck: ## Verificar saúde da API
	@chmod +x healthcheck.sh
	@./healthcheck.sh

clean: ## Limpar containers e volumes (CUIDADO!)
	@echo "⚠️  ATENÇÃO: Isso vai remover todos os containers e volumes!"
	@read -p "Tem certeza? (s/N): " confirm && [ "$$confirm" = "s" ] || exit 1
	@$(DOCKER_COMPOSE) down -v
	@echo "✅ Limpeza concluída"

rebuild: ## Rebuildar imagens
	@$(DOCKER_COMPOSE) down
	@$(DOCKER_COMPOSE) build --no-cache
	@$(DOCKER_COMPOSE) up -d
	@echo "✅ Rebuild concluído"

stats: ## Ver estatísticas de uso
	@docker stats --no-stream $$(docker ps --filter "name=28facil" --format "{{.Names}}")
