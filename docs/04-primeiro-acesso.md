# 4. Primeiro acesso

## 4.1 Entrar na interface web

**Na estação**, abra **`https://<IP-do-servidor>:8443`** (ou `http://<IP-do-servidor>:8080`). O `make status` no servidor mostra o endereço certo.

1. O navegador avisa que o certificado não é confiável. É esperado (certificado autoassinado). Clique em **Avançado → Continuar**.
2. Login: **`admin`** / **`eve`**.
3. Em **HTML5 console** (opção na tela de login), deixe marcado. Assim os consoles dos equipamentos abrem no próprio navegador, sem instalar nada.
4. Troque a senha do `admin` em **Management → User management**.

> Qualquer computador da sua rede chega nessa tela, então troque a senha padrão antes de qualquer outra coisa.

## 4.2 Criar o primeiro lab de teste

Esse teste usa só VPCS, que já vem com o EVE-NG, então funciona antes de você ter qualquer imagem.

1. **Add new lab** → nome `00-teste` → **Save**.
2. Clique com o botão direito na área em branco → **Node** → **Virtual PC (VPCS)** → **Number of nodes: 2** → **Save**.
3. Botão direito na área → **Network** → tipo **Bridge** → **Save**.
4. Arraste dos PCs até a rede para ligar cada um nela.
5. Selecione tudo → botão direito → **Start Selected**.
6. Clique em **VPC1** para abrir o console e configure:

```
ip 192.168.1.1/24
```

7. Em **VPC2**:

```
ip 192.168.1.2/24
ping 192.168.1.1
```

Se o ping responder, o EVE-NG está funcionando.

## 4.3 Dar acesso à internet para os nós

O FortiGate precisa de internet para ativar a licença de avaliação, e é útil para os Linux baixarem pacotes.

1. Botão direito → **Network** → tipo **Cloud NAT** (em algumas versões aparece como **NAT**).
2. Ligue a interface do nó a essa rede.
3. O nó recebe IP por DHCP na faixa `172.29.129.0/24` e sai para a internet pelo EVE-NG → container → servidor.

```
Servidor Ubuntu ── Docker (NAT) ── VM EVE-NG ── Cloud NAT 172.29.129.0/24 ── FortiGate port1
```

> Não use na sua rede de casa as faixas `172.17.0.0/16`, `172.29.129.0/24` e `172.29.130.0/24`, que o EVE-NG usa internamente. A rede Docker deste projeto usa `10.250.0.0/24` justamente para não colidir.

## 4.4 Dicas de uso

- **Salvar configurações dos equipamentos:** no console, salve normalmente (`copy run start` no Cisco, as configs do FortiGate são salvas na hora). No EVE-NG, use **More actions → Export all CFGs** para guardar no lab.
- **Desligar com calma:** pare os nós no lab antes de `make down`.
- **Wipe:** um nó com **Wipe** volta para a configuração de fábrica.

---

Anterior: [3. Instalar o EVE-NG](03-instalar-eve-ng.md) · Próximo: [5. Imagens Cisco e Fortinet](05-imagens.md)
