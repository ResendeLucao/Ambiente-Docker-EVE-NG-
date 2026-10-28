#!/usr/bin/env bash
# Verifica se o servidor (Ubuntu Server 26.04) está pronto para rodar o
# EVE-NG em Docker. Não altera nada no sistema: só lê informações e mostra
# recomendações.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

problems=0
fail() { err "$*"; problems=$((problems + 1)); }

echo "== Sistema operacional =="
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  ok "$PRETTY_NAME (kernel $(uname -r))"
  case "${VERSION_ID:-}" in
    26.04|24.04|22.04) ok "Versão do Ubuntu suportada pelo Docker" ;;
    *) warn "Versão ${VERSION_ID:-?} não testada. O projeto foi feito para Ubuntu 26.04 LTS." ;;
  esac
fi
[[ "$(uname -m)" == "x86_64" ]] && ok "Arquitetura x86_64" \
  || fail "Arquitetura $(uname -m): o EVE-NG só roda em x86_64 (Intel/AMD)."

headless=0
if [[ "$(systemctl get-default 2>/dev/null)" != "graphical.target" ]]; then
  headless=1
  ok "Servidor sem interface gráfica: acesse pelo navegador de outro computador"
fi

echo
echo "== Ferramentas =="
for cmd in git make ssh scp unzip wget; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd"
  else
    warn "$cmd não instalado (o 'make docker' instala)"
  fi
done

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
else
  if [[ "$vendor" == none ]]; then
    fail "/dev/kvm não existe. Ative a virtualização na BIOS/UEFI e reinicie."
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
      fail "Virtualização aninhada desativada. Rode: make nested"
    fi
  else
    warn "Não consegui ler $nested_file (módulo kvm_${vendor} carregado?)."
  fi
fi

echo
echo "== Memória =="
mem_gb=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1024 / 1024 ))
info "RAM total: ~${mem_gb} GB"
# Sem interface gráfica, o Ubuntu usa pouca RAM: reservamos 2 a 3 GB para ele.
reserve=$(( headless == 1 ? 2 : 5 ))
(( mem_gb >= 24 )) && reserve=$(( reserve + 1 ))
if (( mem_gb < 10 )); then
  fail "Menos de 10 GB de RAM. O EVE-NG precisa de pelo menos 8 GB."
elif (( mem_gb < 24 )); then
  warn "Dá para estudar, mas com labs pequenos (poucos nós ao mesmo tempo)."
else
  ok "RAM suficiente para labs de CCNA e FortiGate"
fi
suggest_ram=$(( mem_gb - reserve ))
(( suggest_ram < 4 )) && suggest_ram=4
suggest_cpu=$(( threads - 1 ))
(( suggest_cpu < 2 )) && suggest_cpu=2
info "Sugestão para o .env: EVE_RAM=${suggest_ram}G  EVE_CPUS=${suggest_cpu}"

echo
echo "== Disco =="
data_dir="${EVE_DATA_DIR:-./data}"
[[ "$data_dir" = /* ]] || data_dir="$REPO_DIR/${data_dir#./}"
probe="$data_dir"
while [[ ! -d "$probe" ]]; do probe="$(dirname "$probe")"; done
free_gb=$(df -Pk "$probe" | awk 'NR == 2 {print int($4 / 1024 / 1024)}')
info "Espaço livre onde o disco da VM vai ficar ($probe): ${free_gb} GB"
disk_req="${EVE_DISK:-300G}"; disk_req="${disk_req%G}"
if (( free_gb < 120 )); then
  fail "Menos de 120 GB livres. O EVE-NG precisa de pelo menos 120 GB."
  info "Se o HD de 1 TB estiver em outro ponto de montagem, ajuste EVE_DATA_DIR no .env (veja 'lsblk -f' e 'df -h')."
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
    fail "Plugin 'docker compose' não encontrado. Rode: make docker"
  fi
  if docker info >/dev/null 2>&1; then
    ok "Seu usuário consegue usar o Docker"
  else
    warn "Seu usuário ainda não acessa o Docker. Saia da sessão (exit) e entre de novo depois do 'make docker'."
  fi
else
  fail "Docker não instalado. Rode: make docker"
fi

echo
echo "== Rede =="
info "IP deste servidor na rede local: $(server_ip)"
if [[ "$BIND_ADDR" == "127.0.0.1" ]]; then
  warn "BIND_ADDR=127.0.0.1: o EVE-NG só abre neste servidor. Sem interface gráfica, use BIND_ADDR=0.0.0.0 no .env."
else
  ok "BIND_ADDR=$BIND_ADDR: acessível de outros computadores em http://$(server_ip):${PORT_VIEWER} e https://$(server_ip):${PORT_HTTPS}"
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
  ok "Tudo certo. Próximo passo: make install (primeira vez) ou make up"
else
  err "$problems problema(s) encontrado(s). Corrija e rode de novo: make check"
  exit 1
fi
