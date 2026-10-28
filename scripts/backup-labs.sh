#!/usr/bin/env bash
# Exporta todos os labs (.unl) e as configurações salvas do EVE-NG para
# ./backups/labs-AAAA-MM-DD_HHMM.tar.gz no servidor.
#
# Os arquivos .unl são pequenos e podem ir para o GitHub (pasta labs/),
# desde que não contenham imagens de fabricantes.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$REPO_DIR"

mkdir -p backups
stamp="$(date +%Y-%m-%d_%H%M)"
out="backups/labs-${stamp}.tar.gz"

info "Compactando /opt/unetlab/labs no EVE-NG..."
eve_ssh "tar -czf - -C /opt/unetlab labs" > "$out"

ok "Backup salvo em $out ($(du -h "$out" | cut -f1))"
info "Para restaurar: cat $out | ssh -p $PORT_SSH root@127.0.0.1 'tar -xzf - -C /opt/unetlab && /opt/unetlab/wrappers/unl_wrapper -a fixpermissions'"
