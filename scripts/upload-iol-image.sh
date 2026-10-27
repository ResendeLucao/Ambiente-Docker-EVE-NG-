#!/usr/bin/env bash
# Envia uma imagem Cisco IOL (.bin) para o EVE-NG e corrige as permissões.
#
# Uso:
#   ./scripts/upload-iol-image.sh images/iol/<imagem-l3>.bin [images/iol/<imagem-l2>.bin ...]
#
# Use apenas imagens que você tem licença para usar fora do CML.
# Veja docs/05-imagens.md antes de rodar.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

(( $# >= 1 )) || { sed -n '2,8p' "$0"; exit 1; }

dest="/opt/unetlab/addons/iol/bin"
eve_ssh "mkdir -p '$dest'"

for f in "$@"; do
  [[ -f "$f" ]] || die "Arquivo não encontrado: $f"
  name="$(basename "$f")"
  [[ "$name" == *.bin ]] || warn "$name não termina em .bin; o EVE-NG só lista IOL com extensão .bin"
  info "Enviando $name ..."
  eve_scp "$f" "root@127.0.0.1:$dest/$name"
done

info "Corrigindo permissões..."
eve_ssh "/opt/unetlab/wrappers/unl_wrapper -a fixpermissions"
ok "Pronto. As imagens IOL aparecem no tipo de nó 'Cisco IOL'."
