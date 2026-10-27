# CCNA 07: Segurança de switch e acesso remoto

**Objetivo:** endurecer o acesso aos equipamentos (SSH, senhas, usuários locais) e proteger a camada 2 com port security, DHCP snooping e Dynamic ARP Inspection.

## Topologia

```
            +------+  e0/0 192.168.10.1/24 (gateway + servidor DHCP)
            |  R1  |
            +------+
               |
          e0/0 | (porta confiável)
            +------+   SVI VLAN 10: 192.168.10.2/24 (gerência)
            | SW1  |
            +------+
        e0/1 |      | e0/2
            PC1    PC2 (atacante: tenta ser servidor DHCP / trocar MAC)
```

Nós: 1 × IOL, 1 × IOL L2, 2 × VPCS. Tudo na VLAN 10.

## Tarefas

### Acesso aos equipamentos (R1 e SW1)

1. `enable secret` e `service password-encryption`.
2. Usuário local `admin` privilégio 15 com `secret`.
3. Banner MOTD avisando que o acesso é restrito.
4. SSH versão 2 com chave RSA de 2048 bits, domínio `lab.local`.
5. Linhas VTY só aceitam SSH e autenticação local, com timeout de 10 minutos.
6. Bloqueie 3 tentativas erradas em 60 segundos por 120 segundos (`login block-for`).

### Camada 2 (SW1)

7. **Port security** em `e0/1` e `e0/2`: máximo 2 MACs, `sticky`, violação `restrict`.
8. **DHCP snooping** na VLAN 10. Só `e0/0` (para o R1) é confiável. Limite de 10 pacotes DHCP por segundo nas portas dos PCs.
9. **Dynamic ARP Inspection** na VLAN 10, usando a tabela do DHCP snooping.
10. PC1 pega IP por DHCP do R1.

## Verificação

```
SW1# show port-security
SW1# show port-security interface e0/1
SW1# show ip dhcp snooping
SW1# show ip dhcp snooping binding
SW1# show ip arp inspection vlan 10
R1#  show ip ssh
R1#  show users
```

- Do SW1, `ssh -l admin 192.168.10.1` funciona e `telnet 192.168.10.1` é recusado. (O VPCS não tem cliente SSH; para testar de um "PC", use um nó Linux.)
- A tabela de bindings do DHCP snooping tem o MAC e IP do PC1.
- Se o PC2 configurar um IP fixo e tentar fazer ARP, o DAI descarta (aparece em `show ip arp inspection statistics`).

<details>
<summary>Configuração de referência</summary>

**R1**

```
hostname R1
ip domain-name lab.local
enable secret cisco123
service password-encryption
username admin privilege 15 secret cisco123
banner motd # Acesso restrito a pessoas autorizadas. #
crypto key generate rsa modulus 2048
ip ssh version 2
login block-for 120 attempts 3 within 60
line vty 0 4
 login local
 transport input ssh
 exec-timeout 10 0
!
interface Ethernet0/0
 ip address 192.168.10.1 255.255.255.0
 no shutdown
ip dhcp excluded-address 192.168.10.1 192.168.10.99
ip dhcp pool VLAN10
 network 192.168.10.0 255.255.255.0
 default-router 192.168.10.1
```

**SW1**

```
hostname SW1
ip domain-name lab.local
enable secret cisco123
service password-encryption
username admin privilege 15 secret cisco123
banner motd # Acesso restrito a pessoas autorizadas. #
crypto key generate rsa modulus 2048
ip ssh version 2
line vty 0 4
 login local
 transport input ssh
 exec-timeout 10 0
!
vlan 10
interface Vlan10
 ip address 192.168.10.2 255.255.255.0
 no shutdown
ip default-gateway 192.168.10.1
!
interface Ethernet0/0
 switchport mode access
 switchport access vlan 10
 ip dhcp snooping trust
 ip arp inspection trust
!
interface range Ethernet0/1 - 2
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
 switchport port-security
 switchport port-security maximum 2
 switchport port-security mac-address sticky
 switchport port-security violation restrict
 ip dhcp snooping limit rate 10
!
ip dhcp snooping
ip dhcp snooping vlan 10
no ip dhcp snooping information option
ip arp inspection vlan 10
```

> `no ip dhcp snooping information option` evita que o switch insira a opção 82, que faz o R1 (que não é relay) descartar os pedidos DHCP.

</details>
