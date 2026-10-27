# NSE 4 01: Configuração inicial e licença

**Objetivo:** deixar o FortiGate pronto para os próximos labs: licença ativa, interfaces endereçadas, acesso administrativo seguro, DNS, NTP e backup.

## Topologia

```
  Cloud NAT ── port1 (WAN, DHCP)
                 FGT1
               port2 (LAN) 10.10.10.1/24 ── Bridge ── LNX-PC 10.10.10.10/24, gw 10.10.10.1
```

## Tarefas

1. Primeiro login no console: `admin`, senha em branco. Defina a senha `Fortinet123!`.
2. Configure a `port1` em **DHCP**, papel **WAN**, aceitando `ping`, `https` e `ssh` (só para o lab).
3. Ative a **licença de avaliação** com sua conta FortiCloud (veja [docs/05-imagens.md](../../docs/05-imagens.md#ativar-a-licença-de-avaliação)).
4. Configure a `port2` com `10.10.10.1/24`, papel **LAN**, alias `LAN`, aceitando `ping`, `https`, `ssh`.
5. Hostname `FGT1`. Fuso horário de São Paulo (descubra o valor com `set timezone ?`).
6. DNS: `8.8.8.8` e `1.1.1.1`. NTP sincronizando com o FortiGuard.
7. Restrinja o acesso do `admin` à rede `10.10.10.0/24` e à rede Cloud NAT (**trusted hosts**).
8. Crie um segundo administrador `leitura` com perfil **somente leitura** (`read_only`).
9. Mude a porta HTTPS da administração para `8443` e o timeout de sessão para 15 minutos.
10. Faça **backup da configuração** pela GUI (*Admin → Configuration → Backup*) e pela CLI.

## Verificação

```
get system status
get system interface physical
show system interface port2
get router info routing-table all
diagnose sys ntp status
execute ping 8.8.8.8
execute ping fortiguard.com
```

- `get system status` mostra a versão 7.6.x e a licença válida.
- Do `LNX-PC`, `https://10.10.10.1:8443` abre a GUI.
- Login como `leitura` não consegue alterar nada.

<details>
<summary>Configuração de referência</summary>

```
config system global
    set hostname "FGT1"
    set admin-sport 8443
    set admintimeout 15
end
! Para o fuso: "config system global", "set timezone ?" e escolha São Paulo

config system interface
    edit "port1"
        set mode dhcp
        set role wan
        set allowaccess ping https ssh
    next
    edit "port2"
        set alias "LAN"
        set ip 10.10.10.1 255.255.255.0
        set role lan
        set allowaccess ping https ssh
    next
end

config system dns
    set primary 8.8.8.8
    set secondary 1.1.1.1
end

config system ntp
    set ntpsync enable
    set type fortiguard
end

config system admin
    edit "admin"
        set trusthost1 10.10.10.0 255.255.255.0
        set trusthost2 172.29.129.0 255.255.255.0
    next
    edit "leitura"
        set accprofile "read_only"
        set password Fortinet123!
        set trusthost1 10.10.10.0 255.255.255.0
    next
end
```

Backup pela CLI para um servidor TFTP/FTP (opcional) ou pela GUI:

```
execute backup config tftp fgt1-lab01.conf <IP-do-servidor>
```

> Cuidado com os *trusted hosts*: se você restringir antes de configurar a rede de onde está acessando, perde o acesso pela rede. O console do EVE-NG continua funcionando.

</details>
