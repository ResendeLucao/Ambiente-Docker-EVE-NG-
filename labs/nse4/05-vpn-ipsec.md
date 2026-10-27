# NSE 4 05: VPN IPsec site a site

**Objetivo:** fechar uma VPN IPsec IKEv2 baseada em rota entre o FortiGate e uma "filial" Linux com strongSwan.

> Por que Linux e não outro FortiGate? A licença de avaliação permite **uma** avaliação por conta FortiCloud. Com o strongSwan do outro lado você pratica a mesma configuração do FortiGate sem precisar de uma segunda licença.

## Topologia

```
  Cloud NAT ── port1 (internet, só para a licença)
                FGT1
   port2 10.10.10.1/24          port3 203.0.113.1/24 ("internet" do lab)
         |                               |
      LNX-PC                         LNX-VPN eth0 203.0.113.2/24
   10.10.10.10                       filial (dummy) 192.168.50.1/24
```

| Item | Valor |
|------|-------|
| IKE | versão 2, PSK `LabVPN-2026!` |
| Fase 1 | AES256-SHA256, DH 14 |
| Fase 2 | AES256-SHA256, DH 14 (PFS), redes 10.10.10.0/24 ↔ 192.168.50.0/24 |

Políticas usadas: **3 de 3**. Rotas estáticas: **1 de 3**.

## Tarefas

1. `port3` com `203.0.113.1/24`, aceitando `ping`.
2. Configure o `LNX-VPN` com strongSwan (referência abaixo).
3. No FortiGate, crie o túnel `to-filial` (fase 1 e fase 2), em modo **baseado em rota** (interface de túnel).
4. Rota estática para `192.168.50.0/24` pela interface `to-filial`.
5. Políticas:
   - `port2 → to-filial` (LAN para filial), **sem NAT**
   - `to-filial → port2` (filial para LAN), **sem NAT**
   - `port2 → port1` (internet), com NAT
6. Suba o túnel e teste ping de `10.10.10.10` para `192.168.50.1`, e de volta (`ping -I 192.168.50.1 10.10.10.10` no Linux).
7. Quebre a VPN de propósito (troque o PSK em um lado) e diagnostique com o debug de IKE.

## Verificação

```
get vpn ipsec tunnel summary
diagnose vpn ike gateway list
diagnose vpn tunnel list
diagnose debug application ike -1
diagnose debug enable
! ... teste ...
diagnose debug disable
diagnose debug reset
```

No Linux:

```bash
sudo swanctl --list-sas
sudo swanctl --log
```

<details>
<summary>Configuração de referência</summary>

**FortiGate**

```
config system interface
    edit "port3"
        set ip 203.0.113.1 255.255.255.0
        set allowaccess ping
    next
end

config vpn ipsec phase1-interface
    edit "to-filial"
        set interface "port3"
        set ike-version 2
        set peertype any
        set net-device disable
        set proposal aes256-sha256
        set dhgrp 14
        set remote-gw 203.0.113.2
        set psksecret LabVPN-2026!
        set dpd on-idle
    next
end

config vpn ipsec phase2-interface
    edit "to-filial-p2"
        set phase1name "to-filial"
        set proposal aes256-sha256
        set dhgrp 14
        set src-subnet 10.10.10.0 255.255.255.0
        set dst-subnet 192.168.50.0 255.255.255.0
        set auto-negotiate enable
    next
end

config router static
    edit 1
        set dst 192.168.50.0 255.255.255.0
        set device "to-filial"
    next
end

config firewall address
    edit "LAN-NET"
        set subnet 10.10.10.0 255.255.255.0
    next
    edit "FILIAL-NET"
        set subnet 192.168.50.0 255.255.255.0
    next
end

config firewall policy
    edit 1
        set name "LAN-para-Filial"
        set srcintf "port2"
        set dstintf "to-filial"
        set srcaddr "LAN-NET"
        set dstaddr "FILIAL-NET"
        set action accept
        set schedule "always"
        set service "ALL"
    next
    edit 2
        set name "Filial-para-LAN"
        set srcintf "to-filial"
        set dstintf "port2"
        set srcaddr "FILIAL-NET"
        set dstaddr "LAN-NET"
        set action accept
        set schedule "always"
        set service "ALL"
    next
    edit 3
        set name "LAN-Internet"
        set srcintf "port2"
        set dstintf "port1"
        set srcaddr "LAN-NET"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set nat enable
    next
end
```

**LNX-VPN (Ubuntu Server)**

```bash
sudo apt install -y strongswan-swanctl charon-systemd   # instale antes, com internet
sudo ip addr add 203.0.113.2/24 dev ens3
sudo ip link add filial type dummy
sudo ip addr add 192.168.50.1/24 dev filial
sudo ip link set filial up
```

`/etc/swanctl/conf.d/fgt.conf`:

```
connections {
    fgt {
        version = 2
        local_addrs  = 203.0.113.2
        remote_addrs = 203.0.113.1
        proposals = aes256-sha256-modp2048
        dpd_delay = 30s
        local {
            auth = psk
            id = 203.0.113.2
        }
        remote {
            auth = psk
            id = 203.0.113.1
        }
        children {
            lan {
                local_ts  = 192.168.50.0/24
                remote_ts = 10.10.10.0/24
                esp_proposals = aes256-sha256-modp2048
                start_action = start
                dpd_action = restart
            }
        }
    }
}

secrets {
    ike-fgt {
        id = 203.0.113.1
        secret = "LabVPN-2026!"
    }
}
```

```bash
sudo systemctl restart strongswan
sudo swanctl --load-all
sudo swanctl --initiate --child lan
```

> Boa prática que não coube no limite de 3 rotas: uma **rota blackhole** para `192.168.50.0/24` com distância maior. Ela evita que, com o túnel caído, o tráfego para a filial saia pela rota padrão da internet.

</details>
