# CCNA 05: OSPFv2 em área única

**Objetivo:** substituir as rotas estáticas do lab 04 por OSPF, controlar o DR/BDR, o custo e anunciar uma rota padrão.

## Topologia

Mesma do [lab 04](04-rotas-estaticas.md), sem as rotas estáticas. Acrescente um segmento compartilhado para ver a eleição de DR:

```
 R1 e0/3 ----+
             |  Rede broadcast 10.0.123.0/24 (nó "Network" tipo Bridge no EVE-NG)
 R2 e0/2 ----+
             |
 R3 e0/3 ----+
```

| Roteador | Router ID | IP no segmento 10.0.123.0/24 |
|----------|-----------|------------------------------|
| R1 | 1.1.1.1 | .1 |
| R2 | 2.2.2.2 | .2 |
| R3 | 3.3.3.3 | .3 |

## Tarefas

1. Remova as rotas estáticas do lab 04 (`no ip route ...`).
2. Configure OSPF processo 1, área 0, com router-id fixo em cada roteador.
3. Anuncie as redes usando o comando `ip ospf 1 area 0` **na interface** (não use `network`).
4. Deixe as interfaces das LANs dos PCs como **passive**.
5. No segmento 10.0.123.0/24, faça o **R2 ser o DR** (prioridade 255) e o **R1 nunca participar** da eleição (prioridade 0).
6. Faça o link R1–R3 direto ter custo maior que o caminho via R2, e confira a mudança de rota.
7. No R2, crie `Loopback1 8.8.8.8/32` (simulando internet) e anuncie uma **rota padrão** com `default-information originate always`.
8. Ajuste os timers hello/dead no link R1–R2 para 5/20 e veja o que acontece quando só um lado muda.

## Verificação

```
show ip ospf neighbor
show ip ospf interface brief
show ip ospf interface Ethernet0/3
show ip route ospf
show ip protocols
```

- `show ip ospf neighbor` em R1 mostra R2 como `FULL/DR` no segmento compartilhado.
- `show ip route` em R1 e R3 tem `O*E2 0.0.0.0/0`.
- Com timers diferentes, a adjacência cai e volta só quando os dois lados batem.

<details>
<summary>Configuração de referência</summary>

**R1**

```
no ip route 192.168.3.0 255.255.255.0 10.0.13.2
no ip route 192.168.3.0 255.255.255.0 10.0.12.2 10
no ip route 2.2.2.2 255.255.255.255 10.0.12.2
!
interface Ethernet0/3
 ip address 10.0.123.1 255.255.255.0
 ip ospf priority 0
 no shutdown
!
router ospf 1
 router-id 1.1.1.1
 passive-interface Ethernet0/2
!
interface range Ethernet0/0 - 3
 ip ospf 1 area 0
interface Ethernet0/0
 ip ospf cost 100
interface Ethernet0/1
 ip ospf hello-interval 5
 ip ospf dead-interval 20
```

**R2**

```
no ip route 192.168.1.0 255.255.255.0 10.0.12.1
no ip route 192.168.3.0 255.255.255.0 10.0.23.2
!
interface Loopback1
 ip address 8.8.8.8 255.255.255.255
interface Ethernet0/2
 ip address 10.0.123.2 255.255.255.0
 ip ospf priority 255
 no shutdown
!
router ospf 1
 router-id 2.2.2.2
 default-information originate always
!
interface range Ethernet0/0 - 2
 ip ospf 1 area 0
interface Loopback0
 ip ospf 1 area 0
interface Ethernet0/0
 ip ospf hello-interval 5
 ip ospf dead-interval 20
```

**R3**

```
no ip route 192.168.1.0 255.255.255.0 10.0.13.1
no ip route 192.168.1.0 255.255.255.0 10.0.23.1 10
no ip route 2.2.2.2 255.255.255.255 10.0.23.1
!
interface Ethernet0/3
 ip address 10.0.123.3 255.255.255.0
 no shutdown
!
router ospf 1
 router-id 3.3.3.3
 passive-interface Ethernet0/2
!
interface range Ethernet0/0 - 3
 ip ospf 1 area 0
interface Ethernet0/0
 ip ospf cost 100
```

> Se a eleição de DR já tiver acontecido antes de você mudar a prioridade, ela não muda sozinha (OSPF não é preemptivo). Rode `clear ip ospf process` nos roteadores do segmento.

</details>
