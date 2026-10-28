# Ambiente Docker + EVE-NG para labs de CCNA e NSE 4

Laboratório pessoal para estudar para o **Cisco CCNA (200-301)** e o **Fortinet NSE 4 (FortiOS Administrator)**, rodando o **EVE-NG dentro do Docker** em um servidor **Ubuntu Server 26.04 LTS** (só linha de comando) com 1 TB de disco.

Tudo o que é preciso para montar o ambiente está aqui: scripts, `docker-compose`, passo a passo e roteiros de labs com configurações de referência.

---

## Como funciona

O EVE-NG **não existe como imagem Docker oficial**. Ele é um servidor completo (baseado em Ubuntu) que usa KVM para rodar cada roteador, switch e firewall dos labs. Para colocá-lo no Docker sem gambiarras, este projeto usa o container [`qemux/qemu`](https://github.com/qemus/qemu), que empacota o QEMU/KVM: o container inicializa a **ISO oficial do EVE-NG**, instala em um disco virtual salvo no seu HD e publica a interface web na rede.

Como o servidor não tem interface gráfica, você usa **dois computadores**:

- **Servidor**: o PC com Ubuntu Server 26.04. Roda o Docker e o EVE-NG. É onde você digita os comandos (`make ...`), direto nele ou por SSH.
- **Estação**: qualquer computador da mesma rede com navegador (seu notebook ou PC com Windows 10, por exemplo). É onde você abre o EVE-NG e faz os labs.

```mermaid
flowchart LR
    subgraph EST["Estação (Windows, notebook...)"]
        B["Navegador<br/>https://IP-do-servidor:8443"]
        T["Terminal SSH<br/>ssh usuario@IP-do-servidor"]
    end
    subgraph SRV["Servidor Ubuntu Server 26.04"]
        subgraph D["Docker Engine"]
            subgraph C["Container eve-ng (qemux/qemu)"]
                subgraph V["VM EVE-NG (KVM)"]
                    R1["Cisco IOL / vIOS"]
                    FG["FortiGate VM"]
                    L["Linux / VPCS"]
                end
            end
        end
        HD[("./data<br/>disco da VM no HD de 1 TB")]
    end
    B -- "rede local: portas 8443 / 8006 / 2222" --> C
    T -- "porta 22" --> SRV
    C --- HD
```

Vantagens dessa abordagem:

- O Ubuntu Server continua limpo: nada do EVE-NG é instalado direto no sistema.
- Subir, desligar e mover o laboratório é um comando (`make up` / `make down`).
- O disco da VM fica em uma pasta só (`./data`), fácil de copiar como backup.
- Sem interface gráfica no servidor, sobra mais RAM e CPU para os labs.

O ponto de atenção é que os nós dos labs viram **VMs dentro de uma VM**, então a **virtualização aninhada** precisa estar ativa no servidor. O comando `make nested` faz isso.

---

## Início rápido

**No servidor** (direto no teclado dele ou por `ssh usuario@IP-do-servidor`):

```bash
sudo apt update && sudo apt install -y git make
git clone https://github.com/ResendeLucao/Ambiente-Docker-EVE-NG-.git
cd Ambiente-Docker-EVE-NG-

make docker     # 1. instala Docker e ferramentas -> depois: exit e entre de novo
make nested     # 2. ativa a virtualização aninhada
make env        # 3. cria o .env
make check      # 4. confere tudo e sugere EVE_RAM e EVE_CPUS -> ajuste com: nano .env
wget -O iso/eve-ng.iso "<link-da-ISO>"   # 5. baixa a ISO do EVE-NG
make install    # 6. primeira inicialização, pela ISO
```

**Na estação**, abra `http://<IP-do-servidor>:8006` e siga o instalador do EVE-NG.

Depois da instalação, **no servidor**:

```bash
docker compose down
make up         # 7. dali em diante, sempre "make up" (sem ISO)
```

E **na estação**, acesse `https://<IP-do-servidor>:8443` com `admin` / `eve` e troque a senha.

O `make check` e o `make up` mostram o IP do servidor. Rode `make help` para ver todos os atalhos.

---

## Passo a passo detalhado

| # | Guia | O que você faz |
|---|------|----------------|
| 1 | [Requisitos](docs/01-requisitos.md) | Confere se o servidor aguenta e escolhe a edição do EVE-NG |
| 2 | [Preparar o Ubuntu Server](docs/02-preparar-host.md) | BIOS, acesso SSH, Docker Engine, virtualização aninhada e `.env` |
| 3 | [Instalar o EVE-NG no Docker](docs/03-instalar-eve-ng.md) | Baixa a ISO, sobe o container e roda o instalador |
| 4 | [Primeiro acesso](docs/04-primeiro-acesso.md) | Web, console HTML5, primeiro lab e acesso à internet |
| 5 | [Imagens Cisco e Fortinet](docs/05-imagens.md) | Onde conseguir imagens de forma legal e como enviar |
| 6 | [Operação e backup](docs/06-operacao-e-backup.md) | Ligar, desligar, atualizar e fazer backup |
| 7 | [Solução de problemas](docs/07-troubleshooting.md) | Erros comuns e como resolver |
| 8 | [Plano de estudos](docs/08-plano-de-estudos.md) | Roteiro até as duas certificações |

## Labs

| Trilha | Conteúdo |
|--------|----------|
| [CCNA](labs/ccna/README.md) | VLANs e trunks, STP, EtherChannel, roteamento entre VLANs, OSPF, DHCP/NAT/ACL, segurança de switch, IPv6 |
| [NSE 4](labs/nse4/README.md) | Configuração inicial, políticas e NAT, roteamento, autenticação, VPN IPsec, inspeção de segurança, HA |

---

## Estrutura do repositório

```
.
├── docker-compose.yml          # container do EVE-NG (uso normal)
├── docker-compose.install.yml  # acrescenta a ISO na instalação
├── .env.example                # RAM, CPU, disco, portas
├── Makefile                    # atalhos: make check, install, up...
├── scripts/
│   ├── 00-check-host.sh        # diagnóstico do servidor
│   ├── 01-install-docker.sh    # Docker Engine + ferramentas no Ubuntu 26.04
│   ├── 02-enable-nested-virt.sh
│   ├── 03-start.sh             # sobe o container (install | normal)
│   ├── status.sh
│   ├── upload-qemu-image.sh    # FortiGate, Linux, vIOS...
│   ├── upload-iol-image.sh     # Cisco IOL
│   ├── create-linux-node.sh    # template Linux a partir de uma ISO
│   └── backup-labs.sh
├── docs/                       # passo a passo
├── labs/                       # roteiros e configs de referência
├── iso/                        # a ISO do EVE-NG fica aqui (ignorada pelo git)
└── images/                     # imagens dos fabricantes (ignoradas pelo git)
```

> **Importante:** imagens Cisco e Fortinet têm licença dos fabricantes. O `.gitignore` já impede que elas subam para o GitHub. Nunca publique essas imagens.
