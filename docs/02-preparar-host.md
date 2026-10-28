# 2. Preparar o Ubuntu Server 26.04

Este guia deixa o servidor pronto: virtualização na BIOS, acesso por SSH a partir da estação, Docker Engine, virtualização aninhada e o arquivo `.env`.

> **Servidor** = o PC com Ubuntu Server 26.04. **Estação** = o computador com navegador de onde você acessa (Windows 10, notebook...). Os comandos deste guia rodam **no servidor**.

## 2.1 Ativar a virtualização na BIOS/UEFI

1. Reinicie o servidor e entre na BIOS/UEFI (geralmente `Del`, `F2`, `F10` ou `F12` na tela inicial).
2. Procure a opção de virtualização. O nome muda conforme o fabricante:
   - Intel: **Intel Virtualization Technology**, **VT-x** ou **Intel VT-d**
   - AMD: **SVM Mode**, **AMD-V** ou **AMD Virtualization**
3. Deixe como **Enabled**, salve e reinicie.

Confira no servidor:

```bash
grep -Ec '(vmx|svm)' /proc/cpuinfo   # precisa ser maior que 0
ls -l /dev/kvm                        # precisa existir
```

## 2.2 Acessar o servidor por SSH a partir da estação

Assim você digita os comandos do servidor confortavelmente na estação, podendo copiar e colar.

**No servidor**, garanta que o SSH está instalado e descubra o IP:

```bash
sudo apt update
sudo apt install -y openssh-server
ip -4 -br addr          # exemplo: enp3s0  UP  192.168.0.50/24  -> IP = 192.168.0.50
```

**Na estação com Windows 10**, abra o **PowerShell** ou o **Prompt de Comando** (o cliente SSH já vem no Windows 10) e conecte:

```powershell
ssh seu-usuario@192.168.0.50
```

Na primeira conexão, responda `yes` e digite a senha do usuário do Ubuntu.

> **Dica:** reserve um IP fixo para o servidor no seu roteador (opção "DHCP estático" ou "reserva de IP", usando o MAC da placa de rede). Assim o endereço do EVE-NG não muda.

## 2.3 Clonar este repositório

```bash
sudo apt install -y git make
cd ~
git clone https://github.com/ResendeLucao/Ambiente-Docker-EVE-NG-.git
cd Ambiente-Docker-EVE-NG-
```

Confira onde está o seu HD de 1 TB:

```bash
lsblk -f
df -h
```

Se ele estiver montado em outro lugar (por exemplo `/mnt/dados`), clone o repositório lá dentro ou aponte `EVE_DATA_DIR` no `.env` para uma pasta nesse disco (passo 2.6).

## 2.4 Instalar o Docker Engine

```bash
make docker
```

O script [`scripts/01-install-docker.sh`](../scripts/01-install-docker.sh):

1. Remove pacotes antigos que conflitam (`docker.io`, `podman-docker`...).
2. Instala as ferramentas do projeto: `git`, `make`, `unzip`, `wget`, `cpu-checker`, `qemu-utils`, cliente SSH.
3. Adiciona o repositório oficial da Docker no formato atual (`/etc/apt/sources.list.d/docker.sources`), que já tem pacotes para o Ubuntu 26.04 (`resolute`).
4. Instala `docker-ce` e `docker-compose-plugin`.
5. Coloca seu usuário no grupo `docker`.

Depois, **saia da sessão e entre de novo**, para o grupo valer:

```bash
exit
# na estação: ssh seu-usuario@192.168.0.50
cd ~/Ambiente-Docker-EVE-NG-
docker run --rm hello-world
```

## 2.5 Ativar a virtualização aninhada

```bash
make nested
```

O script grava `options kvm_intel nested=1` (ou `kvm_amd`) em `/etc/modprobe.d/kvm-nested.conf` e recarrega o módulo. Se aparecer aviso de que não deu para recarregar, reinicie o servidor (`sudo reboot`).

Confira:

```bash
cat /sys/module/kvm_intel/parameters/nested   # Intel: Y
cat /sys/module/kvm_amd/parameters/nested     # AMD: 1
```

## 2.6 Configurar o `.env`

```bash
make env
make check     # mostra a sugestão de EVE_RAM e EVE_CPUS e o IP do servidor
nano .env      # Ctrl+O e Enter salvam, Ctrl+X sai
```

Ajuste no mínimo:

| Variável | O que é | Exemplo (servidor com 32 GB e 16 threads) |
|----------|---------|------------------------------------|
| `EVE_RAM` | RAM entregue ao EVE-NG | `29G` |
| `EVE_CPUS` | Núcleos entregues ao EVE-NG | `15` |
| `EVE_DISK` | Tamanho máximo do disco virtual | `300G` |
| `EVE_DATA_DIR` | Onde o disco fica salvo | `./data` ou `/mnt/dados/eve-ng` |
| `BIND_ADDR` | `0.0.0.0` = acessível pela rede (padrão) | `0.0.0.0` |

Rode `make check` de novo. Quando tudo estiver `[OK]` (a ISO pode continuar como aviso por enquanto), siga para a instalação.

## 2.7 Rede e segurança

- Com `BIND_ADDR=0.0.0.0`, as portas **8006** (console da VM), **8080/8443** (web do EVE-NG) e **2222** (SSH do EVE-NG) ficam abertas para a sua rede local. Troque as senhas padrão (`admin`/`eve` e `root`/`eve`) logo na instalação.
- **O Docker passa por cima do `ufw`.** Portas publicadas por containers continuam acessíveis mesmo com o `ufw` bloqueando. Por isso não é preciso liberar nada no `ufw`, mas também não conte com ele para proteger essas portas.
- **Não exponha essas portas para a internet** (não crie redirecionamento de portas no roteador). O laboratório é para a rede de casa.

---

Anterior: [1. Requisitos](01-requisitos.md) · Próximo: [3. Instalar o EVE-NG](03-instalar-eve-ng.md)
