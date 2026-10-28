# 1. Requisitos

## 1.1 Hardware do PC

| Item | Mínimo | Recomendado para CCNA + NSE 4 |
|------|--------|-------------------------------|
| CPU | Intel ou AMD x86_64 com VT-x/AMD-V, 4 núcleos | 6 a 8 núcleos (12 a 16 threads) |
| RAM | 16 GB | 32 GB |
| Disco | 120 GB livres | SSD com 300 GB+ (você tem 1 TB, sobra) |
| Rede | Placa cabeada ou Wi-Fi | Qualquer uma (o EVE-NG sai pela rede do Docker) |

> Processadores Apple Silicon (ARM) não funcionam. O EVE-NG só roda em x86_64.

Rode o diagnóstico, que mostra exatamente o que o seu PC tem e sugere quanto de RAM e CPU entregar ao EVE-NG:

```bash
make check
```

### Quanto de RAM cada lab usa

Valores aproximados por nó ligado:

| Nó | RAM típica |
|----|-----------|
| VPCS (PC simulado do EVE-NG) | ~0 (quase nada) |
| Cisco IOL (roteador ou switch) | 512 MB a 1 GB |
| Cisco vIOS / IOSvL2 | 512 MB a 1 GB |
| FortiGate VM | 2 GB |
| Linux (Ubuntu/Alpine) | 512 MB a 2 GB |
| O próprio EVE-NG | ~2 GB |

Exemplos:

- Lab de CCNA com 4 switches IOL, 2 roteadores IOL e 4 VPCS: **~6 a 8 GB**.
- Lab de NSE 4 com 2 FortiGates, 1 roteador e 2 Linux: **~8 GB**.

Com 32 GB no PC, configure `EVE_RAM=24G` e você roda qualquer lab das duas trilhas com folga. Com 16 GB, use `EVE_RAM=10G` e mantenha um lab ligado por vez.

## 1.2 Qual edição do EVE-NG baixar

Em outubro de 2026, a página oficial de download oferece duas opções:

| Edição | Situação | Limite | Observação |
|--------|----------|--------|------------|
| **Community 6.2.0-4** | Fim de suporte em **junho de 2026** | 63 nós por lab | Grátis, sem atualizações novas. Base Ubuntu 22.04. ISO de ~3,2 GB. |
| **Professional 7.x (modo Freemium)** | Versão atual | Sem licença, roda com limite reduzido de nós (artigos de terceiros falam em **7 nós por lab**) | Licença paga libera todos os recursos. ISO completa de ~10 GB. |

Como escolher:

- **Para começar e para os labs de NSE 4** (normalmente de 2 a 5 nós), a **Professional 7.x em Freemium** atende e é a versão mantida.
- **Se quiser labs de CCNA maiores** (8 a 12 nós ao mesmo tempo) sem pagar, a **Community 6.2.0-4** ainda funciona, mas não recebe mais correções.
- Os labs deste repositório foram desenhados para caber em **até 7 nós**, então funcionam nas duas.

> Confirme o limite atual de nós na [página de download oficial](https://www.eve-ng.net/index.php/download/) antes de baixar. As condições do Freemium podem mudar.

O processo de instalação neste repositório é o mesmo para as duas: você só troca a ISO.

## 1.3 Contas que você vai precisar

| Conta | Para quê | Custo |
|-------|----------|-------|
| [Cisco.com (CCO)](https://www.cisco.com) | Baixar o CML-Free ou o Packet Tracer | Grátis |
| [Cisco Networking Academy](https://www.netacad.com) | Packet Tracer e cursos | Grátis |
| [FortiCloud / Fortinet Support](https://support.fortinet.com) | Baixar a FortiGate VM e ativar a licença de avaliação | Grátis |
| [Fortinet Training Institute](https://training.fortinet.com) | Cursos e agendamento do NSE 4 | Cursos básicos grátis |

Detalhes sobre as imagens estão em [05-imagens.md](05-imagens.md).

---

Próximo: [2. Preparar o Ubuntu](02-preparar-host.md)
