# CCNA 04: Rotas estáticas e flutuantes

**Objetivo:** montar rotas estáticas, rota padrão e uma rota flutuante (backup) que só entra quando o link principal cai.

## Topologia

```
   PC1                                         PC2
192.168.1.10                               192.168.3.10
    |                                            |
  e0/2                                         e0/2
 +----+ e0/0   10.0.13.0/30 (principal)  e0/0 +----+
 | R1 |-------------------------------------- | R3 |
 +----+                                       +----+
  e0/1 \                                    / e0/1
        \ 10.0.12.0/30      10.0.23.0/30   /
         \        e0/0 +----+ e0/1         /
          ------------ | R2 | -------------
                       +----+
                    Lo0 2.2.2.2/32
```

Nós: 3 × IOL, 2 × VPCS.

| Link | Lado A | Lado B |
|------|--------|--------|
| R1–R3 | R1 e0/0 10.0.13.1 | R3 e0/0 10.0.13.2 |
| R1–R2 | R1 e0/1 10.0.12.1 | R2 e0/0 10.0.12.2 |
| R2–R3 | R2 e0/1 10.0.23.1 | R3 e0/1 10.0.23.2 |
| LAN R1 | R1 e0/2 192.168.1.1/24 | PC1 .10 |
| LAN R3 | R3 e0/2 192.168.3.1/24 | PC2 .10 |

## Tarefas

1. Endereçe todas as interfaces.
2. R1 alcança `192.168.3.0/24` **pelo link direto** com R3.
3. R1 tem uma **rota flutuante** para `192.168.3.0/24` via R2, com distância administrativa 10.
4. Faça o mesmo no sentido contrário em R3 (para `192.168.1.0/24`).
5. R2 alcança as duas LANs com rotas estáticas.
6. R1 e R3 alcançam o `Lo0` do R2 com uma **rota de host** `/32`.
7. Teste o failover: dê `shutdown` em R1 `e0/0` e veja a rota flutuante entrar na tabela.

## Verificação

```
R1# show ip route static
R1# show ip route 192.168.3.0
PC1> trace 192.168.3.10
```

- Antes do shutdown: `trace` passa por 10.0.13.2.
- Depois do shutdown: passa por 10.0.12.2 e 10.0.23.2, e a rota aparece com `[10/0]`.

<details>
<summary>Configuração de referência</summary>

**R1**

```
hostname R1
interface Ethernet0/0
 ip address 10.0.13.1 255.255.255.252
 no shutdown
interface Ethernet0/1
 ip address 10.0.12.1 255.255.255.252
 no shutdown
interface Ethernet0/2
 ip address 192.168.1.1 255.255.255.0
 no shutdown
!
ip route 192.168.3.0 255.255.255.0 10.0.13.2
ip route 192.168.3.0 255.255.255.0 10.0.12.2 10
ip route 2.2.2.2 255.255.255.255 10.0.12.2
```

**R2**

```
hostname R2
interface Loopback0
 ip address 2.2.2.2 255.255.255.255
interface Ethernet0/0
 ip address 10.0.12.2 255.255.255.252
 no shutdown
interface Ethernet0/1
 ip address 10.0.23.1 255.255.255.252
 no shutdown
!
ip route 192.168.1.0 255.255.255.0 10.0.12.1
ip route 192.168.3.0 255.255.255.0 10.0.23.2
```

**R3**

```
hostname R3
interface Ethernet0/0
 ip address 10.0.13.2 255.255.255.252
 no shutdown
interface Ethernet0/1
 ip address 10.0.23.2 255.255.255.252
 no shutdown
interface Ethernet0/2
 ip address 192.168.3.1 255.255.255.0
 no shutdown
!
ip route 192.168.1.0 255.255.255.0 10.0.13.1
ip route 192.168.1.0 255.255.255.0 10.0.23.1 10
ip route 2.2.2.2 255.255.255.255 10.0.23.1
```

**VPCS**

```
PC1> ip 192.168.1.10/24 192.168.1.1
PC2> ip 192.168.3.10/24 192.168.3.1
```

> No EVE-NG, dar `shutdown` só de um lado já derruba a rota daquele lado. Em links reais com switch no meio, a interface poderia continuar *up*; nesses casos usa-se IP SLA com `track` (fora do escopo do CCNA).

</details>
