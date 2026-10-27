# NSE 4 02: Políticas de firewall e NAT

**Objetivo:** liberar a saída da LAN para a internet com SNAT, publicar um servidor web da DMZ com VIP (DNAT) e ler os logs de tráfego.

## Topologia

```
                 Cloud NAT
                     |
                   port1 (WAN, DHCP)  <IP-port1>
                   FGT1
       port2 10.10.10.1/24        port3 10.10.20.1/24 (DMZ)
             |                           |
          LNX-PC                     LNX-WEB
       10.10.10.10                 10.10.20.10 (nginx)
```

Políticas usadas: **2 de 3**.

## Tarefas

1. Configure a `port3` com `10.10.20.1/24`, alias `DMZ`, aceitando `ping`.
2. No `LNX-WEB`: IP `10.10.20.10/24`, gateway `10.10.20.1`, instale o nginx (dê internet temporariamente a ele pela Cloud NAT para instalar, ou instale antes de mover para a DMZ).
3. Crie os objetos de endereço `LAN-NET` (10.10.10.0/24) e `SRV-WEB` (10.10.20.10/32).
4. **Política 1, `LAN-para-Internet`:** `port2` → `port1`, origem `LAN-NET`, destino `all`, serviços `HTTP`, `HTTPS`, `DNS`, `PING`, **NAT ativado** (usa o IP da interface de saída), log de todas as sessões.
5. Crie o VIP `VIP-WEB`: IP externo `<IP-port1>` porta `8080` → `10.10.20.10` porta `80`.
6. **Política 2, `Internet-para-WEB`:** `port1` → `port3`, origem `all`, destino `VIP-WEB`, serviço `HTTP`, **NAT desativado**.
7. Teste a publicação a partir do próprio EVE-NG, que está na rede Cloud NAT:

```bash
make shell-eve
curl -I http://<IP-port1>:8080
```

8. Veja os logs em *Log & Report → Forward Traffic* e as sessões ativas.
9. **Pergunta:** por que não é preciso criar uma política da DMZ para a internet para o servidor responder ao `curl`?

## Verificação

```
show firewall policy
show firewall vip
diagnose sys session filter dport 8080
diagnose sys session list
get system session list
```

<details>
<summary>Configuração de referência</summary>

```
config system interface
    edit "port3"
        set alias "DMZ"
        set ip 10.10.20.1 255.255.255.0
        set allowaccess ping
    next
end

config firewall address
    edit "LAN-NET"
        set subnet 10.10.10.0 255.255.255.0
    next
    edit "SRV-WEB"
        set subnet 10.10.20.10 255.255.255.255
    next
end

config firewall vip
    edit "VIP-WEB"
        set extip <IP-port1>
        set extintf "port1"
        set portforward enable
        set mappedip "10.10.20.10"
        set extport 8080
        set mappedport 80
    next
end

config firewall policy
    edit 1
        set name "LAN-para-Internet"
        set srcintf "port2"
        set dstintf "port1"
        set srcaddr "LAN-NET"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "HTTP" "HTTPS" "DNS" "PING"
        set nat enable
        set logtraffic all
    next
    edit 2
        set name "Internet-para-WEB"
        set srcintf "port1"
        set dstintf "port3"
        set srcaddr "all"
        set dstaddr "VIP-WEB"
        set action accept
        set schedule "always"
        set service "HTTP"
        set logtraffic all
    next
end
```

**LNX-WEB (Ubuntu)**

```bash
sudo ip addr add 10.10.20.10/24 dev ens3
sudo ip route add default via 10.10.20.1
sudo apt install -y nginx      # com internet disponível
```

Resposta (9): o FortiGate é *stateful*. A resposta do servidor pertence à sessão aberta pela política 2, então não passa por uma nova avaliação de política.

> O IP da `port1` vem por DHCP. Se ele mudar, atualize o `extip` do VIP. Em produção, a WAN de um servidor publicado costuma ter IP fixo.

</details>
