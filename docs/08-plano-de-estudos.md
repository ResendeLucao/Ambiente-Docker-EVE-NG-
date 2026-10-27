# 8. Plano de estudos

Meta: **CCNA e NSE 4 até o fim de 2027**. A sugestão é fazer o CCNA primeiro, porque a base de redes (sub-redes, VLANs, roteamento, NAT) é cobrada também no NSE 4.

## Visão geral

| Período | Foco | Labs |
|---------|------|------|
| Nov/2026 a Dez/2026 | Montar o ambiente e revisar fundamentos | Docs 1 a 6, lab `00-teste` |
| Jan/2027 a Abr/2027 | CCNA: switching, roteamento, serviços | [CCNA 01 a 08](../labs/ccna/README.md) |
| Mai/2027 | Revisão e simulados do CCNA | Refazer labs sem olhar a solução |
| **Jun/2027** | **Prova CCNA 200-301** | |
| Jul/2027 a Out/2027 | NSE 4: FortiGate | [NSE 4 01 a 07](../labs/nse4/README.md) |
| Nov/2027 | Revisão e simulados do NSE 4 | |
| **Dez/2027** | **Prova NSE 4** | |

## Rotina semanal sugerida

- **3 dias de teoria** (1 h): curso, livro ou vídeo do tópico da semana.
- **2 dias de lab** (1 h 30): monte o lab do tópico do zero, sem copiar a solução. Só confira a configuração de referência no final.
- **1 dia de revisão** (1 h): flashcards e questões de simulado.

## Materiais oficiais

### CCNA 200-301

- Blueprint da prova: <https://learningnetwork.cisco.com> (procure "CCNA exam topics")
- Cisco Networking Academy: cursos CCNA 1, 2 e 3 (gratuitos com a instituição parceira ou pagos)
- Packet Tracer: <https://www.netacad.com>

### NSE 4 (FortiOS Administrator)

- Fortinet Training Institute: <https://training.fortinet.com>
- Em 15/07/2026 a Fortinet reorganizou o programa NSE. O exame de nível 4 aparece como **FortiOS Administrator**, e os materiais de preparação atuais usam o FortiOS 7.6. Confira o código e a versão da prova no site oficial antes de agendar.

## Como usar os labs

Cada lab tem:

1. **Topologia**: o que montar no EVE-NG (ou no Packet Tracer/CML).
2. **Tarefas**: o que configurar, em ordem.
3. **Verificação**: comandos para provar que funcionou.
4. **Configuração de referência**: a solução. Só abra no final.

Depois de concluir um lab, exporte as configurações e faça commit neste repositório (pasta `labs/`). Assim você mantém seu histórico de estudo versionado.

---

Anterior: [7. Solução de problemas](07-troubleshooting.md) · [Voltar ao início](../README.md)
