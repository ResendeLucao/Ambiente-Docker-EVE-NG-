# NSE 4 06: Perfis de segurança

**Objetivo:** aplicar inspeção SSL, antivírus, filtro web, controle de aplicações e IPS em uma política, e entender a diferença entre modo de inspeção por fluxo e por proxy.

> **Limite da licença de avaliação:** ela não inclui FortiGuard. Por isso, filtros que dependem de consulta à nuvem (categorias de web filter, reputação de DNS) não funcionam, e as assinaturas de antivírus/IPS/aplicações ficam na versão que veio com o firmware. Este lab usa recursos que funcionam sem FortiGuard: filtro de URL estático, arquivo de teste EICAR, assinaturas existentes e regras de inspeção. Leia sobre as categorias FortiGuard na teoria, porque elas caem na prova.

## Topologia

Topologia do [lab 02](02-politicas-nat.md): `LNX-PC` na LAN, `LNX-WEB` na DMZ publicado por VIP.

Políticas usadas: **2 de 3** (as mesmas do lab 02).

## Tarefas

### Inspeção SSL

1. Na política `LAN-para-Internet`, aplique o perfil **certificate-inspection** e acesse um site HTTPS. Note que o certificado no navegador é o original.
2. Troque para **deep-inspection**. O navegador passa a reclamar do certificado.
3. Exporte a CA do FortiGate (*System → Certificates → Fortinet_CA_SSL → Download*) e importe no navegador do `LNX-PC` como autoridade confiável. O aviso some.
4. Crie uma **exceção** para que um domínio (por exemplo um banco) não seja inspecionado.

### Antivírus

5. Crie o perfil de antivírus `AV-LAB`, bloqueando HTTP e HTTPS.
6. Aplique na política (com deep-inspection) e tente baixar o arquivo de teste EICAR em <https://www.eicar.org> (página "Download Anti Malware Testfile"). O download deve ser bloqueado.

### Filtro web

7. Crie o perfil `WEB-LAB` com **URL filter** estático: bloquear `*.facebook.com` e `*.tiktok.com`, monitorar `*.youtube.com`.
8. Teste e veja o bloqueio e o log.

### Controle de aplicações

9. Crie o sensor `APP-LAB` bloqueando a categoria **Proxy** e a aplicação **BitTorrent**.

### IPS

10. No acesso publicado `Internet-para-WEB`, aplique um sensor IPS que proteja servidores Linux/web (filtro por *target: server*, *OS: Linux*). Use `default` como ponto de partida.

### Modo de inspeção

11. Compare: na política, mude o *inspection mode* entre **flow-based** e **proxy-based**. Anote o que muda nas opções disponíveis e no comportamento do bloqueio de antivírus (página de substituição vs conexão cortada).

## Verificação

```
get system fortiguard-service status
diagnose autoupdate versions
show firewall ssl-ssh-profile
show antivirus profile AV-LAB
show webfilter profile WEB-LAB
diagnose ips anomaly list
```

E nos logs: *Log & Report → Security Events* (AV, Web Filter, Application Control, IPS).

<details>
<summary>Configuração de referência</summary>

```
config webfilter urlfilter
    edit 1
        set name "URL-LAB"
        config entries
            edit 1
                set url "*.facebook.com"
                set type wildcard
                set action block
            next
            edit 2
                set url "*.tiktok.com"
                set type wildcard
                set action block
            next
            edit 3
                set url "*.youtube.com"
                set type wildcard
                set action monitor
            next
        end
    next
end

config webfilter profile
    edit "WEB-LAB"
        config web
            set urlfilter-table 1
        end
    next
end

config antivirus profile
    edit "AV-LAB"
        config http
            set av-scan block
        end
    next
end

config application list
    edit "APP-LAB"
        config entries
            edit 1
                set category 6
                set action block
            next
        end
    next
end
! A categoria Proxy tem ID 6 na maioria das versões. Confira com:
!   config application list / edit APP-LAB / config entries / edit 1 / set category ?

config firewall policy
    edit 1
        set utm-status enable
        set ssl-ssh-profile "deep-inspection"
        set av-profile "AV-LAB"
        set webfilter-profile "WEB-LAB"
        set application-list "APP-LAB"
    next
    edit 2
        set utm-status enable
        set ips-sensor "default"
    next
end
```

> Os nomes e opções exatos dos perfis mudam entre versões do FortiOS. Se algum comando não for aceito, monte pela GUI e depois confira o resultado com `show`, que é uma ótima forma de aprender a sintaxe da sua versão.

</details>
