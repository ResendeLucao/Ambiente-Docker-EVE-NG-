#!/usr/bin/env bash
# Instala o Docker Engine no Ubuntu Server 26.04 (também funciona em 24.04 e
# 22.04) usando o repositório oficial da Docker, no formato deb822 indicado
# na documentação oficial: https://docs.docker.com/engine/install/ubuntu/
#
# Instala também as ferramentas que o projeto usa (git, make, unzip, wget...).
set -euo pipefail
source "$(dirname "$0")/lib.sh"

[[ $EUID -eq 0 ]] && die "Rode como seu usuário normal (o script chama sudo quando precisa)."

# shellcheck disable=SC1091
. /etc/os-release
codename="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
info "Ubuntu ${VERSION_ID:-?} ($codename) detectado"

info "Removendo pacotes antigos/conflitantes (se existirem)..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y "$pkg" >/dev/null 2>&1 || true
done
# Formato antigo do repositório, caso exista de uma instalação anterior
sudo rm -f /etc/apt/sources.list.d/docker.list

info "Instalando ferramentas do projeto..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl git make unzip wget cpu-checker qemu-utils openssh-client

info "Adicionando o repositório oficial da Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${codename}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

info "Instalando Docker Engine + Compose..."
sudo apt-get update
if ! sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
  die "Falha ao instalar o Docker. Confira se a sua versão ($codename) aparece em https://docs.docker.com/engine/install/ubuntu/"
fi

sudo systemctl enable --now docker

if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  warn "Seu usuário entrou no grupo 'docker'. Saia da sessão (exit) e entre de novo antes de continuar."
fi

ok "Docker instalado: $(docker --version)"
ok "Teste rápido (depois de sair e entrar de novo): docker run --rm hello-world"
