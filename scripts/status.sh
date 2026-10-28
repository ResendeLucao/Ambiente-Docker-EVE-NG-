#!/usr/bin/env bash
# Mostra o estado do container, testa se a web e o SSH do EVE-NG respondem
# e informa os endereços para abrir no navegador de outro computador.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
cd "$REPO_DIR"

docker compose ps
echo

check_port() {
  local name="$1" port="$2"
  if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then
    ok "$name respondendo na porta $port"
  else
    warn "$name ainda não responde na porta $port"
  fi
}

check_port "Console da VM" "$PORT_VIEWER"
check_port "Web do EVE-NG (HTTPS)" "$PORT_HTTPS"
check_port "SSH do EVE-NG" "$PORT_SSH"

host="$(access_host)"
echo
info "Console da VM: http://${host}:${PORT_VIEWER}"
info "Web do EVE-NG: https://${host}:${PORT_HTTPS}"
info "Uso de disco da VM: $(du -sh "${EVE_DATA_DIR:-./data}" 2>/dev/null | cut -f1)"
