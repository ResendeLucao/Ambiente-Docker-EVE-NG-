# 7. Solução de problemas

Primeiro passo em qualquer problema:

```bash
make check
make status
make logs
```

## O container não sobe: "KVM acceleration not available" ou "/dev/kvm not found"

- A virtualização está desligada na BIOS. Veja [2.1](02-preparar-host.md#21-ativar-a-virtualização-na-biosuefi).
- O módulo não carregou: `sudo modprobe kvm_intel` (ou `kvm_amd`).
- Você está usando Docker Desktop. Desinstale e use o Docker Engine (`make docker`).
- Permissão: como teste, acrescente `privileged: true` ao serviço no `docker-compose.yml`. Se funcionar, o problema é acesso ao dispositivo.

## A ISO não inicializa (tela preta ou "no bootable device")

Abra `docker-compose.yml`, descomente a linha `BOOT_MODE: legacy` e suba de novo:

```bash
docker compose down
make install
```

## Depois de instalar, a VM volta para o menu do instalador

A VM está inicializando pela ISO de novo. Suba sem ela:

```bash
docker compose down
make up
```

## O container reclama que não há o que inicializar ao rodar `make up`

O disco ainda não tem o EVE-NG instalado (ou `EVE_DATA_DIR` aponta para outra pasta). Confira o caminho no `.env` e, se necessário, rode `make install` de novo.

## Os nós QEMU (FortiGate, Linux) não iniciam

Quase sempre é a virtualização aninhada. Confira em duas camadas:

```bash
# No servidor Ubuntu
cat /sys/module/kvm_intel/parameters/nested   # ou kvm_amd -> precisa ser Y ou 1

# Dentro do EVE-NG (make shell-eve)
egrep -c '(vmx|svm)' /proc/cpuinfo            # precisa ser > 0
```

Se o primeiro estiver errado, rode `make nested` (com o container desligado) e reinicie o servidor (`sudo reboot`).

Se o primeiro estiver certo e o segundo der `0`, force a CPU do host na VM: acrescente ao `environment` do `docker-compose.yml`

```yaml
      ARGUMENTS: "-cpu host"
```

e rode `docker compose up -d`.

## Imagem enviada não aparece na lista de nós

```bash
make fixperms
```

Confira se a pasta tem o prefixo correto (por exemplo `fortinet-FGT-`) e se o disco se chama `virtioa.qcow2`. Veja [5.3](05-imagens.md#53-regras-de-nomes-no-eve-ng).

## A web do EVE-NG não abre em `https://<IP-do-servidor>:8443`

- A VM ainda está iniciando. Acompanhe em `http://<IP-do-servidor>:8006`.
- Confira se está usando o IP do **servidor** (o `make status` mostra), e não o IP interno que aparece na tela do EVE-NG.
- Teste no próprio servidor: `curl -kI https://127.0.0.1:8443`. Se responder no servidor e não na estação, verifique se `BIND_ADDR=0.0.0.0` no `.env` e se os dois computadores estão na mesma rede.
- Confira o IP na tela de login do console. Se aparecer sem IP, rode `dhclient` dentro do EVE-NG ou refaça a configuração de rede com o assistente (`rm -f /opt/ovf/.configured && reboot`).
- Outro serviço do servidor já usa a porta (veja com `sudo ss -tlnp | grep 8443`). Troque `PORT_HTTPS` no `.env`.

## SSH pede confirmação de chave ou dá "REMOTE HOST IDENTIFICATION HAS CHANGED"

Acontece se você reinstalou o EVE-NG. Remova a chave antiga:

```bash
ssh-keygen -R "[127.0.0.1]:2222"
```

## Os labs ficam lentos

- Dê mais RAM e CPU (`EVE_RAM` / `EVE_CPUS`) e rode `docker compose up -d`.
- Ligue só os nós que estiver usando.
- Prefira IOL a vIOS: usa bem menos recursos.
- Evite rodar outros serviços pesados no servidor ao mesmo tempo.

## O disco encheu

```bash
du -sh data/
```

O disco virtual cresce até `EVE_DISK`. Apague labs e imagens que não usa mais dentro do EVE-NG, ou mova `EVE_DATA_DIR` para um disco com mais espaço (com o container desligado).

---

Anterior: [6. Operação e backup](06-operacao-e-backup.md) · Próximo: [8. Plano de estudos](08-plano-de-estudos.md)
