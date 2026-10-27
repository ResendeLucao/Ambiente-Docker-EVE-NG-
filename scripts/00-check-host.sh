#!/usr/bin/env bash
# Verifica se o PC (Kubuntu) está pronto para rodar o EVE-NG em Docker.
# Não altera nada no sistema: só lê informações e mostra recomendações.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

problems=0
fail() { err "$*"; problems=$((problems + 1)); }

echo "== Sistema operacional =="
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  ok "$PRETTY_NAME (kernel $(uname -r))"
fi
[[ "$(uname -m)" == "x86_64" ]] && ok "Arquitetura x86_64" \
  || fail "Arquitetura $(uname -m): o EVE-NG só roda em x86_64 (Intel/AMD)."

echo
echo "== CPU e virtualização =="
cpu_model="$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ //')"
threads="$(nproc)"
info "CPU: $cpu_model ($threads threads)"

if grep -qw vmx /proc/cpuinfo; then
  vendor=intel; ok "Intel VT-x disponível"
elif grep -qw svm /proc/cpuinfo; then
  vendor=amd; ok "AMD-V disponível"
else
  vendor=none
  fail "VT-x/AMD-V não aparece. Ative 'Intel Virtualization Technology' ou 'SVM Mode' na BIOS/UEFI."
fi

if [[ -e /dev/kvm ]]; then
  ok "/dev/kvm existe"
  [[ -r /dev/kvm && -w /dev/kvm ]] || warn "Seu usuário não tem acesso a /dev/kvm (o Docker roda como root, então costuma funcionar mesmo assim)."
else
  if [[ "$vendor" == none ]]; then
    fail "/dev/kvm não existe. Ative a virtualização na BIOS/UEFI e reinicie o PC."
  else
    fail "/dev/kvm não existe. Rode: sudo modprobe kvm_${vendor}"
  fi
fi

if [[ "$vendor" != none ]]; then
  nested_file="/sys/module/kvm_${vendor}/parameters/nested"
  if [[ -r "$nested_file" ]]; then
    nested="$(cat "$nested_file")"
    if [[ "$nested" == "Y" || "$nested" == "1" ]]; then
      ok "Virtualização aninhada ativa (necessária para FortiGate e outros nós QEMU)"
    else
      fail "Virtualização aninhada desativada. Rode: ./scripts/02-enable-nested-virt.sh"
    fi
  else
    warn "Não consegui ler $nested_file (módulo kvm_${vendor} carregado?)."
  fi
fi

echo
echo "== Memória =="
mem_gb=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1024 / 1024 ))
info "RAM total: ~${mem_gb} GB"
if (( mem_gb < 12 )); then
  fail "Menos de 12 GB de RAM. O EVE-NG pede no mínimo 8 GB só para ele, mais o Kubuntu."
  suggest_ram=$(( mem_gb - 4 ))
elif (( mem_gb < 24 )); then
  warn "Dá para estudar, mas com labs pequenos (poucos nós ao mesmo tempo)."
  suggest_ram=$(( mem_gb - 5 ))
else
  ok "RAM suficiente para labs de CCNA e FortiGate"
  suggest_ram=$(( mem_gb - 6 ))
fi
(( suggest_ram < 4 )) && suggest_ram=4
suggest_cpu=$(( threads - 2 ))
(( suggest_cpu < 2 )) && suggest_cpu=2
info "Sugestão para o .env: EVE_RAM=${suggest_ram}G  EVE_CPUS=${suggest_cpu}"

echo
echo "== Disco =="
data_dir="${EVE_DATA_DIR:-./data}"
[[ "$data_dir" = /* ]] || data_dir="$REPO_DIR/${data_dir#./}"
probe="$data_dir"
while [[ ! -d "$probe" ]]; do probe="$(dirname "$probe")"; done
free_gb=$(df -BG --output=avail "$probe" | tail -1 | tr -dc '0-9')
info "Espaço livre onde o disco da VM vai ficar ($probe): ${free_gb} GB"
disk_req="${EVE_DISK:-300G}"; disk_req="${disk_req%G}"
if (( free_gb < 120 )); then
  fail "Menos de 120 GB livres. O EVE-NG precisa de pelo menos 120 GB."
elif (( free_gb < disk_req )); then
  warn "EVE_DISK=${disk_req}G é maior que o espaço livre. O disco cresce aos poucos, mas pode encher."
else
  ok "Espaço suficiente para EVE_DISK=${disk_req}G"
fi

echo
echo "== Docker =="
if command -v docker >/dev/null 2>&1; then
  ok "$(docker --version)"
  if docker compose version >/dev/null 2>&1; then
    ok "$(docker compose version)"
  else
    fail "Plugin 'docker compose' não encontrado. Rode: ./scripts/01-install-docker.sh"
  fi
  if docker info >/dev/null 2>&1; then
    ok "Seu usuário consegue usar o Docker"
  else
    warn "Seu usuário ainda não acessa o Docker. Faça logout/login depois do script de instalação."
  fi
  if docker context show 2>/dev/null | grep -qi desktop; then
    fail "Docker Desktop detectado. Ele não repassa o KVM ao container; use o Docker Engine."
  fi
else
  fail "Docker não instalado. Rode: ./scripts/01-install-docker.sh"
fi

echo
echo "== ISO do EVE-NG =="
iso="${EVE_ISO:-./iso/eve-ng.iso}"
[[ "$iso" = /* ]] || iso="$REPO_DIR/${iso#./}"
if [[ -f "$iso" ]]; then
  ok "ISO encontrada: $iso ($(du -h "$iso" | cut -f1))"
else
  warn "ISO não encontrada em $iso. Veja docs/03-instalar-eve-ng.md"
fi

echo
if (( problems == 0 )); then
  ok "Tudo certo. Próximo passo: make up"
else
  err "$problems problema(s) encontrado(s). Corrija e rode de novo: make check"
  exit 1
fi
