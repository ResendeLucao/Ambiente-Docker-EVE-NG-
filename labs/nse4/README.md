# Labs de NSE 4 (FortiOS Administrator)

Labs com **FortiGate VM 7.6** no EVE-NG, todos desenhados para caber na **licença de avaliação permanente** da Fortinet:

- 1 vCPU e 2 GB de RAM por FortiGate
- no máximo **3 interfaces, 3 políticas de firewall e 3 rotas estáticas**

| # | Lab | Nós | Assuntos |
|---|-----|-----|----------|
| 01 | [Configuração inicial e licença](01-configuracao-inicial.md) | FGT + LNX-PC | Interfaces, acesso administrativo, DNS, NTP, backup |
| 02 | [Políticas de firewall e NAT](02-politicas-nat.md) | FGT + LNX-PC + LNX-WEB | Políticas, objetos, SNAT, VIP (DNAT), logs |
| 03 | [Roteamento e failover de WAN](03-roteamento.md) | FGT + LNX-PC + LNX-RTR | Rotas estáticas, distância e prioridade, link monitor |
| 04 | [Autenticação de usuários](04-autenticacao.md) | FGT + LNX-PC | Usuários locais, grupos, política com autenticação |
| 05 | [VPN IPsec site a site](05-vpn-ipsec.md) | FGT + LNX-PC + LNX-VPN | IKEv2, fase 1 e 2, rotas e políticas de VPN |
| 06 | [Perfis de segurança](06-perfis-seguranca.md) | FGT + LNX-PC + LNX-WEB | Inspeção SSL, antivírus, web filter, application control, IPS |
| 07 | [Diagnóstico e HA](07-diagnostico-ha.md) | FGT + LNX-PC (+ FGT2 opcional) | Sniffer, debug flow, sessões, logs, HA FGCP |

## Topologia base (usada em todos)

```
                 Cloud NAT (internet do EVE-NG, DHCP 172.29.129.0/24)
                        |
                      port1  WAN
                 +-------------+
                 |    FGT1     |
                 +-------------+
          port2  LAN       port3  DMZ / WAN2 (muda por lab)
        10.10.10.1/24
               |
       Network (Bridge)
               |
            LNX-PC  10.10.10.10/24 (cliente com navegador)
```

## Preparar o FortiGate

Siga [docs/05-imagens.md](../../docs/05-imagens.md#51-fortinet-nse-4) para baixar, enviar e ativar a licença. Configure o nó com 1 CPU, 2048 MB de RAM e 4 interfaces.

## Preparar os nós Linux

Os labs usam até três Linux:

| Nó | Função | Sugestão |
|----|--------|----------|
| `LNX-PC` | Cliente, com navegador para a GUI do FortiGate | Ubuntu Desktop 24.04 |
| `LNX-WEB` | Servidor web na DMZ | Ubuntu Server 24.04 com nginx |
| `LNX-RTR` / `LNX-VPN` | Roteador de WAN2 / par de VPN (strongSwan) | Ubuntu Server 24.04 |

**Opção A: nós Docker do EVE-NG.** Se a sua edição do EVE-NG trouxer as imagens Docker prontas (como um desktop com navegador), use-as para o `LNX-PC`. É o caminho mais leve.

**Opção B: instalar a partir da ISO oficial do Ubuntu** (funciona em qualquer edição):

```bash
# 1. no Kubuntu: baixe as ISOs em https://ubuntu.com/download e crie os templates
./scripts/create-linux-node.sh linux-ubuntu-24.04-desktop ~/Downloads/ubuntu-24.04*-desktop-amd64.iso 30G
./scripts/create-linux-node.sh linux-ubuntu-24.04-server  ~/Downloads/ubuntu-24.04*-live-server-amd64.iso 20G
```

2. No EVE-NG, crie um lab temporário, adicione um nó **Linux** com o template, ligue em **Cloud NAT** e instale pelo console (VNC).
3. Depois da instalação, desligue o nó, clique com o botão direito → **Commit** (no EVE-NG Community, faça o commit pela linha de comando; veja a documentação oficial).
4. Remova o `cdrom.iso` da pasta do template:

```bash
make shell-eve
rm /opt/unetlab/addons/qemu/linux-ubuntu-24.04-server/cdrom.iso
```

A partir daí, cada novo nó criado com esse template já nasce com o Ubuntu instalado.

## Dica de economia de RAM

Com pouca memória, use o Ubuntu Server (sem interface gráfica) como `LNX-PC` e abra a GUI do FortiGate **no navegador do seu Kubuntu**, por um túnel SSH através do EVE-NG. A `port1` fica na rede Cloud NAT, que o EVE-NG alcança diretamente:

```bash
# no FortiGate (só em laboratório): libere HTTPS na port1
#   config system interface / edit port1 / set allowaccess ping https ssh / end
# no Kubuntu:
ssh -p 2222 -N -L 9443:<IP-da-port1>:443 root@127.0.0.1
# depois abra https://127.0.0.1:9443
```

Também vale fazer boa parte dos labs pela **CLI** do FortiGate, que é o que a prova mais cobra em troubleshooting.
