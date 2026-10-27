# NSE 4 07: Diagnóstico e alta disponibilidade

**Objetivo:** dominar as ferramentas de troubleshooting que a prova cobra (sniffer, debug flow, tabela de sessões, logs) e conhecer a configuração de HA FGCP.

## Parte 1: Diagnóstico

Use a topologia do [lab 02](02-politicas-nat.md).

### Tarefas

1. **Sniffer:** capture o ping do `LNX-PC` para `8.8.8.8` e identifique o pacote entrando na `port2` e saindo da `port1` já com NAT.
2. **Debug flow:** siga uma conexão HTTP do `LNX-PC` e encontre no output o ID da política aplicada, a rota escolhida e o SNAT.
3. **Bloqueio implícito:** tente um acesso que nenhuma política libera (por exemplo `ssh` do `LNX-PC` para o `LNX-WEB`). No debug flow, encontre a mensagem de *policy 0* (negação implícita).
4. **Sessões:** filtre a tabela de sessões pelo IP do `LNX-PC` e interprete os campos (`proto_state`, `policy_id`, `hook=post dir=org act=snat`).
5. **Logs:** ative o log das negações implícitas e veja o acesso do passo 3 em *Forward Traffic*.
6. **Recursos:** verifique CPU, memória e o modo de conservação de memória.

### Comandos

```
! 1. sniffer: interface, filtro, nível de detalhe, quantidade
diagnose sniffer packet any 'icmp and host 10.10.10.10' 4 10

! 2. debug flow
diagnose debug reset
diagnose debug flow filter clear
diagnose debug flow filter addr 10.10.10.10
diagnose debug flow show function-name enable
diagnose debug flow trace start 20
diagnose debug enable
!    ... gere o tráfego no LNX-PC ...
diagnose debug disable
diagnose debug reset

! 4. sessões
diagnose sys session filter clear
diagnose sys session filter src 10.10.10.10
diagnose sys session list
diagnose sys session clear     ! cuidado: derruba as sessões filtradas

! 5. log da negação implícita
config log setting
    set fwpolicy-implicit-log enable
end

! 6. recursos
get system performance status
diagnose hardware sysinfo conserve
get system status
```

<details>
<summary>O que procurar no debug flow</summary>

- `find a route: flag=... gw-<IP> via port1`: a decisão de roteamento.
- `Allowed by Policy-1: SNAT`: política e NAT aplicados.
- `Denied by forward policy check (policy 0)`: nenhuma política casou, negação implícita.
- `reverse path check fail, drop`: o caminho de volta não bate com a rota (problema de RPF, comum em roteamento assimétrico).

</details>

## Parte 2: Alta disponibilidade (HA FGCP)

> Precisa de **dois FortiGates licenciados**, ou seja, duas contas FortiCloud com avaliação (uma por conta) ou licenças completas. Também precisa de 2 GB de RAM a mais. Se não tiver, estude a configuração abaixo e a teoria; a prova cobra conceitos de HA (modos, eleição, sincronização), não a montagem prática.

### Topologia

```
          Cloud NAT                        LAN (Bridge)
            |    \                         /      |
          port1  port1                 port2    port2
           FGT1 ========= port3 (heartbeat) ========= FGT2
          (primário)                               (secundário)
```

Os dois FortiGates precisam da **mesma versão de firmware e do mesmo modelo/licença**.

### Configuração

Em **cada** FortiGate (mude só a prioridade):

```
config system ha
    set group-name "LAB-HA"
    set mode a-p
    set password Fortinet123!
    set hbdev "port3" 50
    set session-pickup enable
    set override disable
    set priority 200          ! FGT2: 100
    set monitor "port1" "port2"
end
```

### Verificação

```
get system ha status
diagnose sys ha checksum cluster
execute ha manage 1 admin     ! acessa o secundário a partir do primário
```

### Testes

1. Derrube a `port1` do primário e veja o secundário assumir (`monitor`).
2. Com `override disable`, o primário original **não** volta a ser primário sozinho quando a porta volta. Mude para `override enable` e compare.
3. Faça um download longo e teste o failover com `session-pickup` ligado e desligado.

## Revisão final para a prova

Monte do zero, sem consultar, a topologia do lab 02 com os perfis do lab 06, e depois cause e resolva três falhas: uma rota faltando, uma política na ordem errada e um VIP com porta errada. Use só as ferramentas da parte 1 para encontrar cada uma.
