# CCNA 02: STP e EtherChannel

**Objetivo:** controlar quem é o root bridge do Rapid PVST+, proteger portas de acesso e agregar links com LACP.

## Topologia

```
              +-------+
              |  SW1  |  (root VLAN 10)
              +-------+
          e0/0 |     | e0/1
               |     |
        e0/0   |     |  e0/0
        +-------+   +-------+
        |  SW2  |===|  SW3  |   (root VLAN 20)
        +-------+   +-------+
      e0/1,e0/2 Po1 e0/1,e0/2
        e0/3 |         | e0/3
            PC1       PC2
        (VLAN 10)  (VLAN 20)
```

Nós: 3 × Cisco IOL L2, 2 × VPCS. SW2–SW3 usa **dois links** (`e0/1` e `e0/2`) agregados em `Port-channel1`.

| PC | VLAN | IP |
|----|------|----|
| PC1 | 10 | 192.168.10.11/24 |
| PC2 | 20 | 192.168.20.12/24 |

## Tarefas

1. Crie as VLANs 10 e 20 nos três switches. Todos os links entre switches são trunks.
2. Ative `spanning-tree mode rapid-pvst` nos três.
3. Faça o **SW1 root primário da VLAN 10** e secundário da VLAN 20.
4. Faça o **SW3 root primário da VLAN 20** e secundário da VLAN 10.
5. Agregue `e0/1` e `e0/2` entre SW2 e SW3 em um EtherChannel **LACP** (modo `active`), como trunk.
6. Nas portas dos PCs, ative `portfast` e `bpduguard`.
7. Teste: em uma porta com BPDU Guard, ligue um switch no lugar do PC e veja a porta entrar em `err-disabled`.

## Verificação

```
show spanning-tree vlan 10
show spanning-tree vlan 20
show spanning-tree summary
show etherchannel summary
show interfaces port-channel 1 trunk
```

- `show spanning-tree vlan 10` em SW1: *This bridge is the root*.
- `show etherchannel summary`: `Po1(SU)` com `Et0/1(P)` e `Et0/2(P)`.
- Desligue um dos links do Po1: o ping entre PCs da mesma VLAN continua (se estiverem na mesma VLAN; teste colocando ambos na VLAN 10).

<details>
<summary>Configuração de referência</summary>

**Comum aos três switches**

```
spanning-tree mode rapid-pvst
vlan 10
vlan 20
```

**SW1**

```
hostname SW1
spanning-tree vlan 10 root primary
spanning-tree vlan 20 root secondary
interface range Ethernet0/0 - 1
 switchport trunk encapsulation dot1q
 switchport mode trunk
```

**SW2**

```
hostname SW2
interface Ethernet0/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
interface range Ethernet0/1 - 2
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 1 mode active
interface Port-channel1
 switchport trunk encapsulation dot1q
 switchport mode trunk
interface Ethernet0/3
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
 spanning-tree bpduguard enable
```

**SW3**

```
hostname SW3
spanning-tree vlan 20 root primary
spanning-tree vlan 10 root secondary
interface Ethernet0/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
interface range Ethernet0/1 - 2
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 1 mode active
interface Port-channel1
 switchport trunk encapsulation dot1q
 switchport mode trunk
interface Ethernet0/3
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast
 spanning-tree bpduguard enable
```

Para recuperar uma porta em `err-disabled`: `shutdown` e `no shutdown` na interface (ou configure `errdisable recovery cause bpduguard`).

</details>
