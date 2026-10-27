#!/usr/bin/env bash
# Envia uma imagem QEMU (.qcow2) para o EVE-NG com o nome de pasta e de disco
# que o EVE-NG espera, e corrige as permissões.
#
# Uso:
#   ./scripts/upload-qemu-image.sh <pasta-no-eve> <arquivo.qcow2> [<arquivo2.qcow2>]
#
# Exemplos:
#   FortiGate (o EVE-NG espera o prefixo "fortinet-FGT-"):
#     ./scripts/upload-qemu-image.sh fortinet-FGT-v7.6.4 images/qemu/fortios.qcow2
#   FortiGate com disco de log (opcional):
#     ./scripts/upload-qemu-image.sh fortinet-FGT-v7.6.4 images/qemu/fortios.qcow2 images/qemu/log.qcow2
#   Linux:
#     ./scripts/upload-qemu-image.sh linux-ubuntu-24.04-server images/qemu/ubuntu.qcow2
#
# O primeiro disco vira virtioa.qcow2 e o segundo virtiob.qcow2. Se o fabricante
# exigir outro nome (hda.qcow2, sataa.qcow2...), use a variável DISK_PREFIX:
#   DISK_PREFIX=hd ./scripts/upload-qemu-image.sh ...
set -euo pipefail
source "$(dirname "$0")/lib.sh"

(( $# >= 2 )) || { sed -n '2,20p' "$0"; exit 1; }

folder="$1"; shift
prefix="${DISK_PREFIX:-virtio}"

[[ "$folder" =~ ^[a-z0-9]+-[A-Za-z0-9._-]+$ ]] \
  || die "Nome de pasta inválido: '$folder'. Formato: <prefixo-do-fabricante>-<versão>, ex.: fortinet-FGT-v7.6.4"

letters=(a b c d)
for f in "$@"; do [[ -f "$f" ]] || die "Arquivo não encontrado: $f"; done

dest="/opt/unetlab/addons/qemu/$folder"
info "Criando $dest no EVE-NG..."
eve_ssh "mkdir -p '$dest'"

i=0
for f in "$@"; do
  target="${prefix}${letters[$i]}.qcow2"
  info "Enviando $f -> $dest/$target"
  eve_scp "$f" "root@127.0.0.1:$dest/$target"
  i=$((i + 1))
done

info "Corrigindo permissões..."
eve_ssh "/opt/unetlab/wrappers/unl_wrapper -a fixpermissions"
ok "Pronto. A imagem já aparece ao adicionar um nó no EVE-NG."
