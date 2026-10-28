# 2. Preparar o Ubuntu (Kubuntu, Desktop ou Server)

São três etapas: ligar a virtualização na BIOS, instalar o Docker Engine e ativar a virtualização aninhada.

Funciona em Ubuntu 22.04, 24.04 e 26.04, com ou sem interface gráfica. Se o seu PC for **só linha de comando (Ubuntu Server)**, siga também a seção [2.6](#26-ubuntu-server-sem-interface-gráfica).

## 2.1 Ativar a virtualização na BIOS/UEFI

1. Reinicie o PC e entre na BIOS/UEFI (geralmente `Del`, `F2`, `F10` ou `F12` na tela inicial).
2. Procure a opção de virtualização. O nome muda conforme o fabricante:
   - Intel: **Intel Virtualization Technology**, **VT-x** ou **Intel VT-d**
   - AMD: **SVM Mode**, **AMD-V** ou **AMD Virtualization**
3. Deixe como **Enabled**, salve e reinicie.

Confira no Kubuntu:

```bash
grep -Ec '(vmx|svm)' /proc/cpuinfo   # precisa ser maior que 0
ls -l /dev/kvm                        # precisa existir
```

## 2.2 Clonar este repositório

```bash
sudo apt update && sudo apt install -y git make
cd ~
git clone https://github.com/ResendeLucao/Ambiente-Docker-EVE-NG-.git
cd Ambiente-Docker-EVE-NG-
```

> Se o seu HD de 1 TB estiver montado em outro lugar (por exemplo `/mnt/dados`), clone lá dentro ou aponte `EVE_DATA_DIR` no `.env` para uma pasta nesse disco.

## 2.3 Instalar o Docker Engine

```bash
make docker
```

O script [`scripts/01-install-docker.sh`](../scripts/01-install-docker.sh):

1. Remove pacotes antigos que conflitam (`docker.io`, `podman-docker`...).
2. Adiciona o repositório oficial da Docker para a sua versão do Ubuntu.
3. Instala `docker-ce`, `docker-compose-plugin` e utilitários (`cpu-checker`, `qemu-utils`).
4. Coloca seu usuário no grupo `docker`.

Depois, **faça logout e login** (ou reinicie) e teste:

```bash
docker run --rm hello-world
```

> **Não use o Docker Desktop.** Ele roda dentro de uma VM própria e não entrega o `/dev/kvm` para os containers, então o EVE-NG não funcionaria. O script instala o Docker Engine, que é o correto.

## 2.4 Ativar a virtualização aninhada

```bash
make nested
```

O script grava `options kvm_intel nested=1` (ou `kvm_amd`) em `/etc/modprobe.d/kvm-nested.conf` e recarrega o módulo. Se aparecer aviso de que não deu para recarregar, reinicie o PC.

Confira:

```bash
cat /sys/module/kvm_intel/parameters/nested   # Intel: Y
cat /sys/module/kvm_amd/parameters/nested     # AMD: 1
```

## 2.5 Configurar o `.env`

```bash
make env
make check     # mostra a sugestão de EVE_RAM e EVE_CPUS para o seu PC
nano .env      # Ctrl+O salva, Ctrl+X sai
```

Ajuste no mínimo:

| Variável | O que é | Exemplo (PC com 32 GB e 8 núcleos/16 threads) |
|----------|---------|----------------------------------|
| `EVE_RAM` | RAM entregue ao EVE-NG | `24G` |
| `EVE_CPUS` | Núcleos entregues ao EVE-NG | `12` |
| `EVE_DISK` | Tamanho máximo do disco virtual | `300G` |
| `EVE_DATA_DIR` | Onde o disco fica salvo | `./data` ou `/mnt/dados/eve-ng` |
| `BIND_ADDR` | `127.0.0.1` = só este PC; `0.0.0.0` = toda a rede | `127.0.0.1` |

Rode `make check` de novo. Quando tudo estiver `[OK]` (a ISO pode continuar como aviso por enquanto), siga para a instalação.

## 2.6 Ubuntu Server (sem interface gráfica)

Sem navegador no servidor, você acessa o EVE-NG pelo navegador de **outro computador da mesma rede** (notebook, PC com Windows etc.).

1. Descubra o IP do servidor:

   ```bash
   ip -4 -br addr        # exemplo: enp3s0  UP  192.168.0.50/24
   ```

2. No `.env`, libere o acesso pela rede:

   ```bash
   nano .env
   # troque para:
   BIND_ADDR=0.0.0.0
   ```

3. Se o firewall `ufw` estiver ativo, libere as portas:

   ```bash
   sudo ufw status
   sudo ufw allow 8006,8080,8443,2222/tcp
   ```

4. Baixe a ISO direto pelo terminal. Na [página de download](https://www.eve-ng.net/index.php/download/), copie o link da Full ISO e use:

   ```bash
   wget -O iso/eve-ng.iso "<link-copiado>"
   ```

5. Nos próximos guias, troque `127.0.0.1` pelo IP do servidor quando abrir no navegador do outro computador:

   | O quê | Endereço |
   |-------|----------|
   | Console da VM (instalação) | `http://192.168.0.50:8006` |
   | Web do EVE-NG | `https://192.168.0.50:8443` |

   Os comandos `make ...` e `ssh -p 2222 root@127.0.0.1` continuam sendo executados **no próprio servidor**, então ali o `127.0.0.1` vale.

> Com `BIND_ADDR=0.0.0.0`, qualquer pessoa da sua rede chega na tela de login. Troque a senha padrão `admin`/`eve` logo no primeiro acesso.

---

Anterior: [1. Requisitos](01-requisitos.md) · Próximo: [3. Instalar o EVE-NG](03-instalar-eve-ng.md)
