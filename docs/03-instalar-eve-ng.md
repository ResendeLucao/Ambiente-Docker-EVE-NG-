# 3. Instalar o EVE-NG no Docker

Os comandos rodam **no servidor** (direto ou por SSH). As telas do instalador você abre **no navegador da estação**.

## 3.1 Baixar a ISO oficial

Como o servidor não tem navegador, baixe a ISO direto pelo terminal:

1. **Na estação**, abra <https://www.eve-ng.net/index.php/download/>.
2. Na edição escolhida em [1.2](01-requisitos.md#12-qual-edição-do-eve-ng-baixar), clique com o botão direito no link da **Full ISO** e escolha **Copiar endereço do link**.
3. **No servidor**, baixe para a pasta `iso/` do repositório:

```bash
cd ~/Ambiente-Docker-EVE-NG-
wget -O iso/eve-ng.iso "<cole-o-link-aqui>"
ls -lh iso/
```

> Se o site exigir login ou o link não funcionar no `wget`, baixe na estação e envie para o servidor. No PowerShell do Windows:
>
> ```powershell
> scp $HOME\Downloads\EVE-*.iso seu-usuario@<IP-do-servidor>:~/Ambiente-Docker-EVE-NG-/iso/eve-ng.iso
> ```

Confira de novo:

```bash
make check
```

## 3.2 Primeira inicialização (pela ISO)

```bash
make install
```

Esse comando usa `docker-compose.yml` + `docker-compose.install.yml`, que monta a ISO como CD de boot. Na primeira vez o Docker baixa a imagem `qemux/qemu` (algumas centenas de MB) e cria o disco virtual em `./data`.

No final ele mostra o endereço. **Na estação**, abra:

**`http://<IP-do-servidor>:8006`**

Você vai ver a tela da VM do EVE-NG como se fosse um monitor ligado ao servidor.

## 3.3 Rodar o instalador

A instalação do EVE-NG tem três fases. Não interrompa nenhuma delas.

### Fase 1: Ubuntu do EVE-NG

1. No menu de boot, escolha a opção de instalar o EVE-NG (na Professional aparece como **Install EVE NG Pro Server**).
2. Aceite os padrões e confirme. O disco usado é o virtual (`EVE_DISK`), não o seu HD nem o seu Ubuntu Server.
3. Ao final, a VM **reinicia sozinha**.

> **Se o menu do instalador aparecer de novo depois da reinicialização**, a VM voltou a inicializar pela ISO. No servidor, rode:
>
> ```bash
> docker compose down
> make up
> ```
>
> O `make up` sobe sem a ISO, e a instalação continua pelo disco. Recarregue a página do console na estação.

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

> O IP que o EVE-NG mostra na tela de login é o IP **interno** do container, não o da sua rede. Para acessar, use sempre o IP do servidor com as portas do `.env`.

## 3.4 Passar para o modo normal

Com a instalação concluída, no servidor:

```bash
docker compose down
make up
make status
```

A partir de agora, use sempre **`make up`** para ligar e **`make down`** para desligar. Você pode apagar a ISO se quiser liberar espaço.

## 3.5 Atualizar os pacotes do EVE-NG

No servidor, entre por SSH no EVE-NG (a senha é a de root que você definiu na fase 3):

```bash
make shell-eve
```

Dentro do EVE-NG:

```bash
apt update && apt upgrade -y
dpkg -l | grep -i eve-ng             # mostra a versão instalada
egrep -c '(vmx|svm)' /proc/cpuinfo   # precisa ser > 0: nested funcionando
exit
```

Se o último comando der `0`, a virtualização aninhada não chegou até a VM. Veja [07-troubleshooting.md](07-troubleshooting.md#os-nós-qemu-fortigate-linux-não-iniciam).

---

Anterior: [2. Preparar o Ubuntu Server](02-preparar-host.md) · Próximo: [4. Primeiro acesso](04-primeiro-acesso.md)
