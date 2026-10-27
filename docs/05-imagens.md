# 5. Imagens Cisco e Fortinet

O EVE-NG é só o "simulador". Os sistemas dos equipamentos (Cisco IOS, FortiOS) são dos fabricantes e você precisa obtê-los por conta própria, **de forma licenciada**. Este repositório não inclui nem indica fontes não oficiais de imagens.

## 5.1 Fortinet (NSE 4)

A Fortinet oferece uma **licença de avaliação permanente** da FortiGate VM, gratuita.

### Baixar a FortiGate VM

1. Crie uma conta em <https://support.fortinet.com> (FortiCloud).
2. Vá em **Support → VM Images** (ou **Downloads → VM Images**).
3. Selecione **Product: FortiGate** e **Platform: KVM**.
4. Baixe a versão **7.6.x** (é a versão cobrada no NSE 4 atual). O arquivo é um `.zip` com o disco `fortios.qcow2`.

```bash
mkdir -p images/qemu
unzip ~/Downloads/FGT_VM64_KVM-v7.6*.zip -d images/qemu/
ls images/qemu/      # fortios.qcow2
```

### Enviar para o EVE-NG

Com o EVE-NG ligado (`make up`):

```bash
./scripts/upload-qemu-image.sh fortinet-FGT-v7.6.4 images/qemu/fortios.qcow2
```

O script cria `/opt/unetlab/addons/qemu/fortinet-FGT-v7.6.4/virtioa.qcow2` (nome que o EVE-NG espera) e corrige as permissões. Troque `7.6.4` pela versão que você baixou. O prefixo `fortinet-FGT-` é obrigatório.

### Configurar o nó no lab

Ao adicionar o nó **Fortinet FortiGate**:

| Campo | Valor |
|-------|-------|
| CPU | 1 |
| RAM | 2048 MB |
| Ethernets | 4 a 6 |

### Ativar a licença de avaliação

1. Ligue a `port1` do FortiGate em uma rede **Cloud NAT** ([4.3](04-primeiro-acesso.md#43-dar-acesso-à-internet-para-os-nós)).
2. No console: login `admin`, senha em branco, defina uma nova senha.
3. A `port1` pega IP por DHCP. Veja com `get system interface physical`.
4. Libere HTTPS na `port1` (`config system interface` → `edit port1` → `set allowaccess ping https ssh` → `end`) e abra a GUI do FortiGate no navegador do Kubuntu por um túnel SSH através do EVE-NG:

   ```bash
   ssh -p 2222 -N -L 9443:<IP-da-port1>:443 root@127.0.0.1
   # abra https://127.0.0.1:9443
   ```

   Faça login e escolha a opção de **avaliação com conta FortiCloud**, usando a conta do passo 1. (Também dá para usar um nó Linux com navegador dentro do lab.)

**Limites da licença de avaliação** (segundo a Fortinet):

- 1 vCPU e até 2 GB de RAM
- Até **3 interfaces, 3 políticas de firewall e 3 rotas**
- Sem suporte técnico e sem FortiGuard (assinaturas de IPS/antivírus/web filter não atualizam)
- Uma avaliação por conta FortiCloud

Os [labs de NSE 4](../labs/nse4/README.md) deste repositório foram montados respeitando esses limites. Se você trabalha em uma empresa parceira da Fortinet, peça uma licença de avaliação completa ou NFR, que remove as restrições.

## 5.2 Cisco (CCNA)

Aqui é preciso atenção: as imagens Cisco que vêm no **CML (Cisco Modeling Labs)**, incluindo o CML-Free, **são licenciadas apenas para uso dentro do CML**. Usá-las no EVE-NG viola a licença.

### Opções legais para praticar CCNA

| Opção | Custo | Limite | Quando usar |
|-------|-------|--------|-------------|
| **Cisco Packet Tracer** | Grátis (conta NetAcad) | Simulação, não emulação | Cobre quase todo o CCNA 200-301. Ótimo para começar. |
| **CML-Free** | Grátis (conta Cisco) | 5 nós ao mesmo tempo | IOS real (IOL, IOL-L2). Roda como VM. |
| **CML Personal** | Assinatura anual | 20 a 40 nós | Se quiser labs grandes com IOS real. |
| **Imagens com licença própria** | Depende | Do EVE-NG | Se sua empresa tiver contrato Cisco que permita uso em laboratório. |

**Recomendação prática:**

- Use o **Packet Tracer ou o CML** para os labs com CLI Cisco.
- Use o **EVE-NG** para o FortiGate e para labs multivendor (FortiGate + roteador + Linux).
- Os [roteiros de CCNA](../labs/ccna/README.md) deste repositório funcionam em qualquer uma dessas ferramentas: a topologia e os comandos são os mesmos.

> O CML é distribuído como VM e também pode rodar no seu Kubuntu, ao lado do EVE-NG (só não ligue os dois ao mesmo tempo se a RAM for curta).

### Se você tiver imagens IOL licenciadas

```bash
./scripts/upload-iol-image.sh images/iol/<sua-imagem-L3>.bin images/iol/<sua-imagem-L2>.bin
```

Os arquivos vão para `/opt/unetlab/addons/iol/bin/` e aparecem no tipo de nó **Cisco IOL**. Algumas versões do EVE-NG pedem um arquivo de licença IOL (`iourc`); siga a documentação oficial do EVE-NG para isso.

### Alternativa aberta para treinar conceitos

Para praticar OSPF, NAT, VLANs e roteamento sem imagens Cisco, use nós **Linux com FRRouting** ou **VyOS**, que são livres. A sintaxe é diferente da Cisco, mas os conceitos são os mesmos.

```bash
./scripts/upload-qemu-image.sh linux-vyos-1.5 images/qemu/vyos.qcow2
```

## 5.3 Regras de nomes no EVE-NG

| Tipo | Pasta | Nome do disco |
|------|-------|---------------|
| FortiGate | `/opt/unetlab/addons/qemu/fortinet-FGT-v<versão>/` | `virtioa.qcow2` |
| Linux | `/opt/unetlab/addons/qemu/linux-<nome>/` | `virtioa.qcow2` |
| Cisco vIOS | `/opt/unetlab/addons/qemu/vios-<versão>/` | `virtioa.qcow2` |
| Cisco IOL | `/opt/unetlab/addons/iol/bin/` | `<nome>.bin` |

Se a imagem não aparecer na lista de nós, rode `make fixperms` e confira o prefixo da pasta na tabela de nomes de imagens QEMU na [documentação oficial do EVE-NG](https://www.eve-ng.net/index.php/documentation/).

---

Anterior: [4. Primeiro acesso](04-primeiro-acesso.md) · Próximo: [6. Operação e backup](06-operacao-e-backup.md)
