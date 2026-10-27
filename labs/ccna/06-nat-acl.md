# CCNA 06: NAT, PAT e ACLs

**Objetivo:** dar saída para a "internet" com PAT, publicar um servidor interno com NAT estático e filtrar tráfego com ACLs padrão e estendidas.

## Topologia

```
                 +-------+  Lo0 8.8.8.8/32 (simula um site)
                 |  ISP  |
                 +-------+
                     | e0/0 203.0.113.1/30
                     |
                     | e0/0 203.0.113.2/30  (outside)
                 +-------+
                 | EDGE  |
                 +-------+
                     | e0/1 192.168.10.1/24 (inside)
                 +-------+
                 |  SW1  |
                 +-------+
              /      |      \
           PC1      PC2     SRV
          .11       .12     .100
```

Nós: 2 × IOL, 1 × IOL L2, 3 × VPCS.

## Tarefas

1. Endereçe as interfaces. EDGE tem rota padrão para o ISP. O ISP **não** tem rota para 192.168.10.0/24 (como na internet real).
2. Configure **PAT (overload)** na `e0/0` do EDGE para a rede 192.168.10.0/24.
3. Publique o SRV com **NAT estático**: `192.168.10.100` ↔ `203.0.113.5`.
4. No ISP, crie a rota `203.0.113.4/30` via EDGE, para que o IP público do servidor seja alcançável.
5. **ACL padrão nomeada** `VTY-ADMIN`: só o PC1 pode acessar o EDGE por SSH/Telnet.
6. **ACL estendida nomeada** `INTERNET-IN`, aplicada na entrada da `e0/0` do EDGE:
   - permite ICMP echo-reply e respostas de sessões iniciadas de dentro
   - permite tráfego vindo da internet só para `203.0.113.5` (o servidor)
   - bloqueia e registra (`log`) todo o resto

## Verificação

```
EDGE# show ip nat translations
EDGE# show ip nat statistics
EDGE# show access-lists
PC1> ping 8.8.8.8
ISP# ping 203.0.113.5 source 8.8.8.8
```

- `show ip nat translations` mostra várias entradas com o mesmo IP global (203.0.113.2) e portas diferentes: isso é PAT.
- O ISP alcança 203.0.113.5, mas não alcança 192.168.10.11.

<details>
<summary>Configuração de referência</summary>

**ISP**

```
hostname ISP
interface Loopback0
 ip address 8.8.8.8 255.255.255.255
interface Ethernet0/0
 ip address 203.0.113.1 255.255.255.252
 no shutdown
ip route 203.0.113.4 255.255.255.252 203.0.113.2
```

**EDGE**

```
hostname EDGE
interface Ethernet0/0
 ip address 203.0.113.2 255.255.255.252
 ip nat outside
 no shutdown
interface Ethernet0/1
 ip address 192.168.10.1 255.255.255.0
 ip nat inside
 no shutdown
ip route 0.0.0.0 0.0.0.0 203.0.113.1
!
! PAT
ip access-list standard NAT-INSIDE
 permit 192.168.10.0 0.0.0.255
ip nat inside source list NAT-INSIDE interface Ethernet0/0 overload
!
! NAT estático do servidor
ip nat inside source static 192.168.10.100 203.0.113.5
!
! Gerência só do PC1
ip access-list standard VTY-ADMIN
 permit host 192.168.10.11
 deny any log
line vty 0 4
 access-class VTY-ADMIN in
!
! Filtro de entrada da internet
ip access-list extended INTERNET-IN
 permit icmp any any echo-reply
 permit tcp any any established
 permit ip any host 203.0.113.5
 deny ip any any log
interface Ethernet0/0
 ip access-group INTERNET-IN in
```

**VPCS**

```
PC1> ip 192.168.10.11/24 192.168.10.1
PC2> ip 192.168.10.12/24 192.168.10.1
SRV> ip 192.168.10.100/24 192.168.10.1
```

> A ACL de entrada na interface outside enxerga os endereços **globais** (antes da tradução de volta), por isso a regra do servidor usa 203.0.113.5. `established` só cobre TCP; para UDP (DNS) seria preciso uma regra específica ou uma ACL reflexiva/ZBF, que estão fora do CCNA.

</details>
