#!/usr/bin/env bash
# Sobe o container do EVE-NG.
#   ./scripts/03-start.sh install   -> primeira vez: inicializa pela ISO
#   ./scripts/03-start.sh           -> uso normal: inicializa pelo disco instalado
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$REPO_DIR"

mode="${1:-run}"

[[ -f .env ]] || { cp .env.example .env; warn ".env não existia; criei a partir do .env.example. Revise RAM/CPU."; }
[[ -e /dev/kvm ]] || die "/dev/kvm não existe. Rode: make check"

data="${EVE_DATA_DIR:-./data}"
mkdir -p "$data"

compose=(docker compose -f docker-compose.yml)

if [[ "$mode" == "install" ]]; then
  iso="${EVE_ISO:-./iso/eve-ng.iso}"
  [[ -f "$iso" ]] || die "ISO não encontrada em $iso. Baixe a ISO oficial (veja docs/03-instalar-eve-ng.md)."
  compose+=(-f docker-compose.install.yml)
  info "Modo instalação: a VM vai inicializar pela ISO $iso"
else
  if [[ -z "$(ls -A "$data" 2>/dev/null)" ]]; then
    die "Ainda não há EVE-NG instalado em $data. Rode primeiro: make install"
  fi
fi

"${compose[@]}" up -d
echo
ok "Container iniciado."
info "Console da VM (tela do servidor): http://127.0.0.1:${PORT_VIEWER}"
info "Web do EVE-NG (após instalar):    https://127.0.0.1:${PORT_HTTPS}   (ou http://127.0.0.1:${PORT_HTTP})"
info "SSH/SFTP do EVE-NG:               ssh -p ${PORT_SSH} root@127.0.0.1"
info "Logs:                             make logs"
