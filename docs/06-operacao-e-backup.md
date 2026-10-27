# 6. Operação e backup

## 6.1 Comandos do dia a dia

| Comando | O que faz |
|---------|-----------|
| `make up` | Liga o EVE-NG |
| `make down` | Desliga com segurança (espera até 2 min para a VM desligar) |
| `make restart` | Reinicia |
| `make status` | Mostra se a web e o SSH respondem |
| `make logs` | Mostra os logs do container |
| `make shell-eve` | Abre SSH como root no EVE-NG |
| `make backup` | Exporta os labs para `./backups` |

O container está com `restart: unless-stopped`: se você não der `make down`, ele volta sozinho quando o PC reinicia. Se preferir ligar só quando for estudar, sempre desligue com `make down`.

## 6.2 Backup dos labs

```bash
make backup
```

Gera `backups/labs-AAAA-MM-DD_HHMM.tar.gz` com tudo de `/opt/unetlab/labs` (topologias `.unl` e configurações salvas). São arquivos pequenos.

Para guardar seus labs no GitHub, extraia os `.unl` para a pasta `labs/` deste repositório e faça commit. Eles não contêm as imagens dos fabricantes.

Para restaurar:

```bash
cat backups/labs-<data>.tar.gz | ssh -p 2222 root@127.0.0.1 \
  'tar -xzf - -C /opt/unetlab && /opt/unetlab/wrappers/unl_wrapper -a fixpermissions'
```

## 6.3 Backup completo da VM

Todo o EVE-NG (sistema, imagens e labs) está na pasta `EVE_DATA_DIR` (padrão `./data`).

```bash
make down
sudo tar -cf /mnt/backup/eve-ng-data-$(date +%F).tar data/
make up
```

Para restaurar, desligue, substitua a pasta `data/` pela do backup e ligue de novo. Também serve para mover o laboratório para outro PC: copie o repositório com a pasta `data/` e rode `make up`.

## 6.4 Atualizar

**Pacotes do EVE-NG** (dentro da VM):

```bash
make shell-eve
apt update && apt upgrade -y
```

**Container qemux/qemu** (no Kubuntu):

```bash
make down
docker compose pull
make up
```

## 6.5 Mudar RAM ou CPU

Edite `EVE_RAM` e `EVE_CPUS` no `.env` e rode:

```bash
docker compose up -d
```

O container é recriado com os novos valores. O disco em `data/` é mantido.

> `EVE_DISK` só pode **aumentar**. Diminuir corrompe o disco.

---

Anterior: [5. Imagens](05-imagens.md) · Próximo: [7. Solução de problemas](07-troubleshooting.md)
