# NSE 4 04: Autenticação de usuários

**Objetivo:** exigir que os usuários da LAN se identifiquem antes de navegar, usando usuários e grupos locais, e entender como o FortiGate associa usuário a IP.

## Topologia

Topologia base: `port1` na Cloud NAT, `port2` na LAN com o `LNX-PC` (precisa de navegador).

Políticas usadas: **2 de 3**.

## Tarefas

1. Crie os usuários locais `ana` e `bruno` (senha `Fortinet123!`).
2. Crie os grupos de firewall `VENDAS` (ana) e `TI` (bruno).
3. **Política 1, `TI-Internet`:** `port2` → `port1`, grupo `TI`, todos os serviços, NAT.
4. **Política 2, `VENDAS-Web`:** `port2` → `port1`, grupo `VENDAS`, só `HTTP`, `HTTPS` e `DNS`, NAT.
5. Ajuste o timeout de autenticação para 10 minutos.
6. No `LNX-PC`, abra um site HTTP (por exemplo `http://neverssl.com`). O FortiGate mostra a página de login. Entre como `ana`.
7. Veja quem está autenticado: *Dashboard → Firewall Users* e pela CLI.
8. Faça logout do usuário pela CLI e entre como `bruno`. Teste um `ping 8.8.8.8` com cada um.
9. **Pergunta:** por que o DNS precisa estar liberado mesmo antes do login?

## Verificação

```
diagnose firewall auth list
diagnose firewall auth filter user ana
diagnose firewall auth clear
show user local
show user group
```

- Logado como `ana`: navega, mas `ping 8.8.8.8` falha.
- Logado como `bruno`: navega e pinga.

<details>
<summary>Configuração de referência</summary>

```
config user local
    edit "ana"
        set type password
        set passwd Fortinet123!
    next
    edit "bruno"
        set type password
        set passwd Fortinet123!
    next
end

config user group
    edit "VENDAS"
        set member "ana"
    next
    edit "TI"
        set member "bruno"
    next
end

config user setting
    set auth-timeout 10
end

config firewall policy
    edit 1
        set name "TI-Internet"
        set srcintf "port2"
        set dstintf "port1"
        set srcaddr "all"
        set dstaddr "all"
        set groups "TI"
        set action accept
        set schedule "always"
        set service "ALL"
        set nat enable
    next
    edit 2
        set name "VENDAS-Web"
        set srcintf "port2"
        set dstintf "port1"
        set srcaddr "all"
        set dstaddr "all"
        set groups "VENDAS"
        set action accept
        set schedule "always"
        set service "HTTP" "HTTPS" "DNS"
        set nat enable
    next
end
```

Resposta (9): o navegador precisa resolver o nome do site para gerar a requisição HTTP que o FortiGate intercepta e redireciona para o portal de login. Por isso o FortiGate permite DNS em políticas com autenticação mesmo antes do usuário se identificar.

> Em empresas, o mais comum é integrar com LDAP/Active Directory (FSSO) em vez de usuários locais. A lógica de grupos e políticas é a mesma; o NSE 4 cobra os dois modos (ativo, com portal, e passivo, com FSSO).

</details>
