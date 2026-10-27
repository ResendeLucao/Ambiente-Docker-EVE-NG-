# Labs de CCNA 200-301

| # | Lab | Nós | Tópicos da prova |
|---|-----|-----|------------------|
| 01 | [VLANs e trunks](01-vlans-trunk.md) | 2 SW + 4 PC | 2.1, 2.2 |
| 02 | [STP e EtherChannel](02-stp-etherchannel.md) | 3 SW + 2 PC | 2.4, 2.5 |
| 03 | [Roteamento entre VLANs e DHCP](03-inter-vlan-dhcp.md) | 1 R + 1 SW + 3 PC | 1.6, 2.1, 4.3, 4.6 |
| 04 | [Rotas estáticas e flutuantes](04-rotas-estaticas.md) | 3 R + 2 PC | 3.1, 3.2, 3.3 |
| 05 | [OSPFv2 em área única](05-ospf.md) | 3 R + 2 PC | 3.4 |
| 06 | [NAT, PAT e ACLs](06-nat-acl.md) | 2 R + 1 SW + 3 PC | 4.1, 5.6 |
| 07 | [Segurança de switch e acesso remoto](07-seguranca-switch.md) | 1 R + 1 SW + 2 PC | 4.8, 5.3, 5.7 |
| 08 | [IPv6: endereçamento e rotas](08-ipv6.md) | 3 R + 2 PC | 1.8, 1.9, 3.3 |

> **CML-Free (5 nós):** VPCS não existe no CML. Use os nós Alpine/Ubuntu como PCs ou reduza a quantidade de PCs para caber no limite.

## Ordem sugerida

Faça na ordem. Cada lab assume que você já sabe o anterior. Antes de cada um, revise o tópico na teoria.

## Comandos que você vai usar em todos

```
show running-config
show ip interface brief
show interfaces status
show vlan brief
show ip route
ping <destino>
traceroute <destino>
copy running-config startup-config
```
