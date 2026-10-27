#!/usr/bin/env bash
# Instala o Docker Engine (não o Docker Desktop) no Kubuntu usando o repositório
# oficial da Docker. O Docker Desktop não serve aqui: ele roda dentro de uma VM
# própria e não entrega o /dev/kvm para os containers.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

[[ $EUID -eq 0 ]] && die "Rode como seu usuário normal (o script chama sudo quando precisa)."

# shellcheck disable=SC1091
. /etc/os-release
codename="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
info "Base Ubuntu detectada: $codename"

info "Removendo pacotes antigos/conflitantes (se existirem)..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y "$pkg" >/dev/null 2>&1 || true
done

info "Instalando dependências..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl cpu-checker qemu-utils openssh-client

info "Adicionando o repositório oficial da Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

info "Instalando Docker Engine + Compose..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable --now docker

if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  warn "Seu usuário foi adicionado ao grupo 'docker'. Faça logout e login (ou reinicie) antes de continuar."
fi

ok "Docker instalado: $(docker --version)"
ok "Teste rápido (depois do logout/login): docker run --rm hello-world"
