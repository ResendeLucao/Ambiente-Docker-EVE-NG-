# CCNA 03: Roteamento entre VLANs (router-on-a-stick) e DHCP

**Objetivo:** fazer VLANs diferentes conversarem por subinterfaces 802.1Q e entregar IP automaticamente com DHCP no roteador.

## Topologia

```
               +------+
               |  R1  |   e0/0.10  192.168.10.1/24
               +------+   e0/0.20  192.168.20.1/24
                  | e0/0  e0/0.30  192.168.30.1/24
                  | trunk
               e0/0
               +------+
               | SW1  |
               +------+
          e0/1 |  e0/2 |  e0/3
              PC1    PC2    PC3
           VLAN 10 VLAN 20 VLAN 30 (servidor, IP fixo)
```

Nós: 1 × IOL (roteador), 1 × IOL L2, 3 × VPCS.

| Rede | VLAN | Gateway | Pool DHCP |
|------|------|---------|-----------|
| 192.168.10.0/24 | 10 VENDAS | .1 | .100 a .200 |
| 192.168.20.0/24 | 20 TI | .1 | .100 a .200 |
| 192.168.30.0/24 | 30 SERVIDORES | .1 | sem DHCP; PC3 = .10 |

## Tarefas

1. No SW1: VLANs 10, 20, 30; `e0/0` trunk; `e0/1`, `e0/2`, `e0/3` em acesso.
2. No R1: subinterfaces `e0/0.10`, `.20` e `.30` com `encapsulation dot1Q`.
3. No R1: pools DHCP para VLAN 10 e 20, excluindo de `.1` a `.99`. DNS `8.8.8.8`, domínio `lab.local`.
4. PC1 e PC2 pegam IP por DHCP (`ip dhcp`). PC3 com IP fixo.
5. Teste ping de PC1 para PC2 e PC3.
6. **Desafio:** mova o servidor DHCP para outro roteador (R2) ligado em `e0/1` do R1 e use `ip helper-address` nas subinterfaces (DHCP relay).

## Verificação

```
R1# show ip interface brief
R1# show ip dhcp binding
R1# show ip dhcp pool
PC1> show ip
PC1> ping 192.168.30.10
PC1> trace 192.168.20.100
```

<details>
<summary>Configuração de referência</summary>

**SW1**

```
hostname SW1
vlan 10
 name VENDAS
vlan 20
 name TI
vlan 30
 name SERVIDORES
interface Ethernet0/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
interface Ethernet0/1
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
interface Ethernet0/2
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast
interface Ethernet0/3
 switchport mode access
 switchport access vlan 30
 spanning-tree portfast
```

**R1**

```
hostname R1
interface Ethernet0/0
 no shutdown
interface Ethernet0/0.10
 encapsulation dot1Q 10
 ip address 192.168.10.1 255.255.255.0
interface Ethernet0/0.20
 encapsulation dot1Q 20
 ip address 192.168.20.1 255.255.255.0
interface Ethernet0/0.30
 encapsulation dot1Q 30
 ip address 192.168.30.1 255.255.255.0
!
ip dhcp excluded-address 192.168.10.1 192.168.10.99
ip dhcp excluded-address 192.168.10.201 192.168.10.254
ip dhcp excluded-address 192.168.20.1 192.168.20.99
ip dhcp excluded-address 192.168.20.201 192.168.20.254
!
ip dhcp pool VLAN10
 network 192.168.10.0 255.255.255.0
 default-router 192.168.10.1
 dns-server 8.8.8.8
 domain-name lab.local
ip dhcp pool VLAN20
 network 192.168.20.0 255.255.255.0
 default-router 192.168.20.1
 dns-server 8.8.8.8
 domain-name lab.local
```

**VPCS**

```
PC1> ip dhcp
PC2> ip dhcp
PC3> ip 192.168.30.10/24 192.168.30.1
```

**Desafio (relay):** no R1, em `e0/0.10` e `e0/0.20`, `ip helper-address <IP-do-R2>`. Os pools vão para o R2, que precisa de rota de volta para 192.168.10.0/24 e 192.168.20.0/24.

</details>
