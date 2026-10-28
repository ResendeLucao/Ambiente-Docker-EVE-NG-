#!/usr/bin/env bash
# Cria no EVE-NG um "template" Linux para instalar a partir de uma ISO.
#
# O EVE-NG inicializa pelo cdrom.iso quando ele existe na pasta da imagem.
# Você instala o Linux uma vez dentro do lab, faz commit do disco e depois
# remove o cdrom.iso (veja labs/nse4/README.md, seção "Preparar os nós Linux").
#
# Uso:
#   ./scripts/create-linux-node.sh <pasta-no-eve> <arquivo.iso> [tamanho-do-disco]
#
# Exemplos:
#   ./scripts/create-linux-node.sh linux-ubuntu-26.04-server ~/Downloads/ubuntu-26.04-live-server-amd64.iso 20G
#   ./scripts/create-linux-node.sh linux-ubuntu-26.04-desktop ~/Downloads/ubuntu-26.04-desktop-amd64.iso 30G
set -euo pipefail
source "$(dirname "$0")/lib.sh"

(( $# >= 2 )) || { sed -n '2,15p' "$0"; exit 1; }

folder="$1"; iso="$2"; size="${3:-20G}"
[[ "$folder" == linux-* ]] || die "A pasta precisa começar com 'linux-' para o EVE-NG reconhecer como Linux."
[[ -f "$iso" ]] || die "ISO não encontrada: $iso"

dest="/opt/unetlab/addons/qemu/$folder"
info "Criando $dest ..."
eve_ssh "mkdir -p '$dest'"

info "Enviando a ISO como cdrom.iso (pode demorar)..."
eve_scp "$iso" "root@127.0.0.1:$dest/cdrom.iso"

info "Criando disco vazio virtioa.qcow2 de $size ..."
eve_ssh "cd '$dest' && [ -f virtioa.qcow2 ] || /opt/qemu/bin/qemu-img create -f qcow2 virtioa.qcow2 '$size' || qemu-img create -f qcow2 virtioa.qcow2 '$size'"

eve_ssh "/opt/unetlab/wrappers/unl_wrapper -a fixpermissions"
ok "Template criado. Adicione um nó 'Linux' com a imagem '$folder' e instale pelo console VNC."
