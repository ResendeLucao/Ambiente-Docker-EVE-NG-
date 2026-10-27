# 3. Instalar o EVE-NG no Docker

## 3.1 Baixar a ISO oficial

1. Acesse <https://www.eve-ng.net/index.php/download/>.
2. Baixe a **Full ISO** da edição escolhida em [1.2](01-requisitos.md#12-qual-edição-do-eve-ng-baixar).
3. Mova e renomeie para a pasta `iso/` do repositório:

```bash
mv ~/Downloads/EVE-*.iso iso/eve-ng.iso
ls -lh iso/
```

> Se preferir manter o nome original, aponte `EVE_ISO` no `.env` para o arquivo.

Confira de novo:

```bash
make check
```

## 3.2 Primeira inicialização (pela ISO)

```bash
make install
```

Esse comando usa `docker-compose.yml` + `docker-compose.install.yml`, que monta a ISO como CD de boot. Na primeira vez o Docker baixa a imagem `qemux/qemu` (algumas centenas de MB) e cria o disco virtual em `./data`.

Abra o console da VM no navegador:

**<http://127.0.0.1:8006>**

Você vai ver a tela da VM como se fosse um monitor ligado ao servidor.

## 3.3 Rodar o instalador

A instalação do EVE-NG tem três fases. Não interrompa nenhuma delas.

### Fase 1: Ubuntu

1. No menu de boot, escolha a opção de instalar o EVE-NG (na Professional aparece como **Install EVE NG Pro Server**).
2. Aceite os padrões e confirme. O disco usado é o virtual (`EVE_DISK`), não o seu HD.
3. Ao final, a VM **reinicia sozinha**.

> **Se o menu do instalador aparecer de novo depois da reinicialização**, a VM voltou a inicializar pela ISO. Feche a aba e rode:
>
> ```bash
> docker compose down
> make up
> ```
>
> O `make up` sobe sem a ISO, e a instalação continua pelo disco.

### Fase 2: pacotes do EVE-NG

Os pacotes são instalados automaticamente. Pode levar de 10 a 30 minutos. **Não faça login** até a VM reiniciar pela segunda vez e mostrar o prompt de login.

### Fase 3: assistente de configuração

1. Faça login no console com **`root`** / **`eve`**.
2. O assistente pergunta:

| Pergunta | O que responder |
|----------|-----------------|
| Nova senha de root | Uma senha forte. Anote. |
| Hostname | `eve-ng` |
| DNS domain name | `lab.local` (ou deixe o padrão) |
| IP: DHCP ou estático | **DHCP**. O container entrega o IP automaticamente. |
| NTP server | Deixe em branco ou use `a.ntp.br` |
| Proxy | Direct connection (sem proxy) |

3. Confirme. A VM reinicia mais uma vez.

## 3.4 Passar para o modo normal

Com a instalação concluída, desligue o modo instalação e suba sem a ISO:

```bash
docker compose down
make up
make status
```

A partir de agora, use sempre **`make up`** para ligar e **`make down`** para desligar. Você pode até apagar a ISO se quiser liberar espaço.

## 3.5 Atualizar os pacotes

Entre por SSH (a senha é a de root que você definiu):

```bash
make shell-eve
```

Dentro do EVE-NG:

```bash
apt update && apt upgrade -y
dpkg -l | grep -i eve-ng      # mostra a versão instalada
egrep -c '(vmx|svm)' /proc/cpuinfo   # precisa ser > 0: nested funcionando
```

Se o último comando der `0`, a virtualização aninhada não chegou até a VM. Veja [07-troubleshooting.md](07-troubleshooting.md#os-nós-qemu-fortigate-linux-não-iniciam).

---

Anterior: [2. Preparar o Kubuntu](02-preparar-host.md) · Próximo: [4. Primeiro acesso](04-primeiro-acesso.md)
