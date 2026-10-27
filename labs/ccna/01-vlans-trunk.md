# CCNA 01: VLANs e trunks

**Objetivo:** separar setores em VLANs e transportá-las entre switches por um trunk 802.1Q.

## Topologia

```
 PC1 (VLAN 10)   PC2 (VLAN 20)          PC3 (VLAN 10)   PC4 (VLAN 20)
      |               |                      |               |
   e0/1            e0/2                    e0/1            e0/2
 +----------------------+   trunk 802.1Q  +----------------------+
 |         SW1          |e0/0 ------- e0/0|         SW2          |
 +----------------------+                 +----------------------+
```

Nós no EVE-NG: 2 × Cisco IOL L2, 4 × VPCS.

| Dispositivo | VLAN | IP |
|-------------|------|----|
| PC1 | 10 VENDAS | 192.168.10.11/24 |
| PC2 | 20 TI | 192.168.20.12/24 |
| PC3 | 10 VENDAS | 192.168.10.13/24 |
| PC4 | 20 TI | 192.168.20.14/24 |

## Tarefas

1. Dê hostname `SW1` e `SW2`.
2. Crie as VLANs `10 VENDAS`, `20 TI` e `99 NATIVA` nos dois switches.
3. Coloque as portas de acesso nas VLANs da tabela.
4. Configure `e0/0` como trunk 802.1Q, VLAN nativa 99, permitindo só 10, 20 e 99.
5. Desative o DTP no trunk (`switchport nonegotiate`).
6. Desligue as portas não usadas e coloque-as em uma VLAN 999 `BLACKHOLE`.
7. Configure os PCs.

## Verificação

```
SW1# show vlan brief
SW1# show interfaces trunk
SW1# show interfaces e0/1 switchport
```

- PC1 pinga PC3. PC2 pinga PC4.
- PC1 **não** pinga PC2 (VLANs diferentes, sem roteador).
- `show interfaces trunk` mostra `Native vlan 99` e `Vlans allowed 10,20,99`.

## Perguntas para fixar

1. O que acontece se a VLAN nativa for diferente nos dois lados do trunk?
2. Por que não deixar a VLAN 1 como nativa?
3. Qual a diferença entre `switchport mode trunk` e `dynamic desirable`?

<details>
<summary>Configuração de referência</summary>

**SW1** (SW2 é igual, trocando o hostname)

```
enable
configure terminal
hostname SW1
no ip domain-lookup
!
vlan 10
 name VENDAS
vlan 20
 name TI
vlan 99
 name NATIVA
vlan 999
 name BLACKHOLE
!
interface Ethernet0/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk native vlan 99
 switchport trunk allowed vlan 10,20,99
 switchport nonegotiate
!
interface Ethernet0/1
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
!
interface Ethernet0/2
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast
!
interface Ethernet0/3
 switchport mode access
 switchport access vlan 999
 shutdown
!
end
copy running-config startup-config
```

**VPCS**

```
PC1> ip 192.168.10.11/24
PC2> ip 192.168.20.12/24
PC3> ip 192.168.10.13/24
PC4> ip 192.168.20.14/24
```

Respostas: (1) aparece erro de *native VLAN mismatch* no CDP e o tráfego não marcado vaza entre VLANs; (2) por segurança, evita ataques de VLAN hopping; (3) `trunk` força trunk, `dynamic desirable` negocia via DTP.

</details>
