#!/usr/bin/env bash
# Sobe o container do EVE-NG.
#   ./scripts/03-start.sh install   -> primeira vez: inicializa pela ISO
#   ./scripts/03-start.sh           -> uso normal: inicializa pelo disco instalado
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$REPO_DIR"

mode="${1:-run}"

if [[ ! -f .env ]]; then
  cp .env.example .env
  warn ".env não existia; criei a partir do .env.example. Revise EVE_RAM e EVE_CPUS (make check sugere valores)."
fi
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

host="$(access_host)"
echo
ok "Container iniciado."
info "Abra no navegador de outro computador da sua rede:"
info "  Console da VM (instalação):  http://${host}:${PORT_VIEWER}"
info "  Web do EVE-NG (após instalar): https://${host}:${PORT_HTTPS}"
info "Neste servidor:"
info "  SSH no EVE-NG:  make shell-eve"
info "  Logs:           make logs"
