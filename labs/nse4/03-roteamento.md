# NSE 4 03: Roteamento e failover de WAN

**Objetivo:** trabalhar com rotas estáticas, distância administrativa e prioridade, e fazer a internet trocar sozinha para um segundo link quando o primeiro falhar (link monitor).

## Topologia

```
   Cloud NAT                              Cloud NAT
       |                                      |
     port1 (WAN1)                          eth1 (DHCP)
       FGT1  port3 10.10.20.1/24 ──── eth0 10.10.20.254  LNX-RTR  (faz NAT)
       |                                   lo:  10.10.30.1/24 (rede "filial")
     port2 10.10.10.1/24
       |
    LNX-PC 10.10.10.10
```

O `LNX-RTR` faz o papel de um segundo provedor (WAN2) e também tem a rede `10.10.30.0/24`, que simula uma filial.

Rotas estáticas usadas: **3 de 3**. Políticas: **2 de 3**.

## Tarefas

1. Configure o `LNX-RTR` (comandos na referência): IP em `eth0`, `eth1` por DHCP, roteamento e NAT ativados, rede `10.10.30.1/24` em uma interface dummy.
2. Na `port1`, desative a rota padrão recebida por DHCP (`defaultgw disable`). Anote antes qual era o gateway (`get router info routing-table all`).
3. Crie as rotas estáticas:
   - **Rota 1:** padrão via gateway da Cloud NAT, `port1`, **distância 10**.
   - **Rota 2:** padrão via `10.10.20.254`, `port3`, **distância 20** (backup).
   - **Rota 3:** `10.10.30.0/24` via `10.10.20.254`, `port3`.
4. Políticas: `LAN → port1` e `LAN → port3`, ambas com NAT.
5. Confira que só a rota 1 está ativa na tabela de roteamento e que a rota 2 aparece só no banco de rotas (RIB).
6. Crie o **link monitor** `WAN1-MON` na `port1`, pingando `8.8.8.8` e `1.1.1.1`, removendo a rota estática quando falhar.
7. Teste o failover: no EVE-NG, desconecte o link da `port1` (ou derrube com `set status down` em outro teste) e veja a internet do `LNX-PC` continuar por `port3`.
8. **Variação:** coloque as duas rotas padrão com a **mesma distância** e prioridades diferentes (`priority`). O que muda na tabela? E com distância e prioridade iguais (ECMP)?

## Verificação

```
get router info routing-table all
get router info routing-table database
diagnose sys link-monitor status
diagnose firewall proute list
execute traceroute 8.8.8.8
```

- Com a WAN1 normal: `traceroute` a partir do `LNX-PC` sai pela Cloud NAT da `port1`.
- Com a WAN1 caída: `diagnose sys link-monitor status` mostra `die`, e a rota 2 passa a ser a ativa.

<details>
<summary>Configuração de referência</summary>

**FortiGate**

```
config system interface
    edit "port1"
        set mode dhcp
        set defaultgw disable
    next
    edit "port3"
        set ip 10.10.20.1 255.255.255.0
        set allowaccess ping
    next
end

config router static
    edit 1
        set gateway <gateway-da-Cloud-NAT>
        set device "port1"
        set distance 10
    next
    edit 2
        set gateway 10.10.20.254
        set device "port3"
        set distance 20
    next
    edit 3
        set dst 10.10.30.0 255.255.255.0
        set gateway 10.10.20.254
        set device "port3"
    next
end

config system link-monitor
    edit "WAN1-MON"
        set srcintf "port1"
        set server "8.8.8.8" "1.1.1.1"
        set protocol ping
        set failtime 3
        set recoverytime 5
        set update-static-route enable
    next
end

config firewall policy
    edit 1
        set name "LAN-WAN1"
        set srcintf "port2"
        set dstintf "port1"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set nat enable
    next
    edit 2
        set name "LAN-WAN2"
        set srcintf "port2"
        set dstintf "port3"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set nat enable
    next
end
```

**LNX-RTR (Ubuntu Server)**

```bash
sudo ip addr add 10.10.20.254/24 dev ens3          # eth0 ligada na port3
sudo dhclient ens4                                 # eth1 ligada na Cloud NAT
sudo ip link add filial type dummy
sudo ip addr add 10.10.30.1/24 dev filial
sudo ip link set filial up
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE
sudo ip route add 10.10.10.0/24 via 10.10.20.1      # opcional: sem NAT no FGT para a filial
```

> Os nomes das interfaces no Ubuntu (`ens3`, `ens4`) podem variar. Confira com `ip -br link`.

Variação (8): com distância igual, as duas rotas ficam ativas na tabela, mas a de **menor prioridade** é usada. Com distância e prioridade iguais, o tráfego é dividido entre as duas (ECMP).

</details>
