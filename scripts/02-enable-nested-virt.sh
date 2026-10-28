#!/usr/bin/env bash
# Ativa a virtualização aninhada (nested KVM) no Ubuntu (host).
#
# Por que precisa: o EVE-NG já é uma VM (rodando no container). Os nós dos labs
# - FortiGate, Linux, vIOS etc. - são VMs DENTRO dessa VM. Sem nested, eles não
# iniciam ou ficam extremamente lentos.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

if grep -qw vmx /proc/cpuinfo; then
  mod=kvm_intel
elif grep -qw svm /proc/cpuinfo; then
  mod=kvm_amd
else
  die "CPU sem VT-x/AMD-V visível. Ative a virtualização na BIOS/UEFI primeiro."
fi

param="/sys/module/${mod}/parameters/nested"
current="$(cat "$param" 2>/dev/null || echo "?")"
if [[ "$current" == "Y" || "$current" == "1" ]]; then
  ok "Virtualização aninhada já está ativa ($mod nested=$current)."
  exit 0
fi

info "Gravando /etc/modprobe.d/kvm-nested.conf ..."
echo "options ${mod} nested=1" | sudo tee /etc/modprobe.d/kvm-nested.conf >/dev/null

if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx eve-ng; then
  warn "O container eve-ng está rodando. Desligue antes (make down) e rode este script de novo."
  exit 1
fi

info "Recarregando o módulo $mod ..."
if sudo modprobe -r "$mod" && sudo modprobe "$mod"; then
  ok "Nested ativo: $(cat "$param")"
else
  warn "Não deu para recarregar o módulo agora (alguma VM aberta?). Reinicie o servidor (sudo reboot) para aplicar."
fi
