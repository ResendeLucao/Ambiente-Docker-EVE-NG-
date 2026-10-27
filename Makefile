# Atalhos para o dia a dia. Rode "make help" para ver todos.
SHELL := /bin/bash
COMPOSE := docker compose

.DEFAULT_GOAL := help

.PHONY: help check docker nested env install up down restart logs status shell-eve backup fixperms

help: ## Mostra esta ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

check: ## Verifica se o PC atende aos requisitos
	@./scripts/00-check-host.sh

docker: ## Instala o Docker Engine no Kubuntu
	@./scripts/01-install-docker.sh

nested: ## Ativa a virtualização aninhada (KVM nested)
	@./scripts/02-enable-nested-virt.sh

env: ## Cria o .env a partir do .env.example
	@test -f .env && echo ".env já existe, nada a fazer." || (cp .env.example .env && echo ".env criado. Revise os valores.")

install: ## Primeira vez: sobe o EVE-NG inicializando pela ISO
	@./scripts/03-start.sh install

up: ## Uso normal: sobe o EVE-NG já instalado (sem ISO)
	@./scripts/03-start.sh

down: ## Desliga o EVE-NG com segurança
	$(COMPOSE) down

restart: ## Reinicia o EVE-NG
	$(COMPOSE) restart

logs: ## Acompanha os logs do container
	$(COMPOSE) logs -f --tail=100

status: ## Mostra o estado do container e o endereço de acesso
	@./scripts/status.sh

shell-eve: ## Abre SSH no EVE-NG (usuário root)
	@source ./scripts/lib.sh && ssh -p "$$PORT_SSH" root@127.0.0.1

fixperms: ## Corrige permissões das imagens dentro do EVE-NG
	@source ./scripts/lib.sh && ssh -p "$$PORT_SSH" root@127.0.0.1 /opt/unetlab/wrappers/unl_wrapper -a fixpermissions

backup: ## Exporta os labs (.unl) do EVE-NG para ./backups
	@./scripts/backup-labs.sh
