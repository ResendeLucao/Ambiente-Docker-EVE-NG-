#!/usr/bin/env bash
# Funções e variáveis compartilhadas pelos scripts. Use com: source scripts/lib.sh

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Carrega .env (ou .env.example como fallback) sem sobrescrever variáveis já exportadas
load_env() {
  local file="$REPO_DIR/.env"
  [[ -f "$file" ]] || file="$REPO_DIR/.env.example"
  while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
    key="${key//[[:space:]]/}"
    [[ -n "${!key:-}" ]] && continue
    export "$key=$value"
  done < "$file"
}
load_env

: "${PORT_SSH:=2222}"
: "${PORT_HTTP:=8080}"
: "${PORT_HTTPS:=8443}"
: "${PORT_VIEWER:=8006}"
: "${BIND_ADDR:=0.0.0.0}"

if [[ -t 1 ]]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_ERR=$'\033[31m'; C_INFO=$'\033[36m'; C_END=$'\033[0m'
else
  C_OK=""; C_WARN=""; C_ERR=""; C_INFO=""; C_END=""
fi

ok()   { echo "${C_OK}[OK]${C_END}    $*"; }
warn() { echo "${C_WARN}[AVISO]${C_END} $*"; }
err()  { echo "${C_ERR}[ERRO]${C_END}  $*" >&2; }
info() { echo "${C_INFO}[INFO]${C_END}  $*"; }
die()  { err "$*"; exit 1; }

# IP do servidor na rede local (o endereço que você digita no navegador do
# outro computador). Usa a interface da rota padrão.
server_ip() {
  local ip
  ip="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "src") {print $(i + 1); exit}}')"
  [[ -n "$ip" ]] || ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  echo "${ip:-<IP-do-servidor>}"
}

# Endereço para abrir no navegador, de acordo com o BIND_ADDR
access_host() {
  if [[ "$BIND_ADDR" == "127.0.0.1" ]]; then echo "127.0.0.1"; else server_ip; fi
}

# SSH/SCP para o EVE-NG através da porta publicada pelo container.
# Estes comandos rodam no próprio servidor, por isso usam 127.0.0.1.
EVE_SSH_OPTS=(-p "$PORT_SSH" -o StrictHostKeyChecking=accept-new)
eve_ssh() { ssh "${EVE_SSH_OPTS[@]}" root@127.0.0.1 "$@"; }
eve_scp() { scp -P "$PORT_SSH" -o StrictHostKeyChecking=accept-new "$@"; }
