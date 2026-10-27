# Labs

| Trilha | Ferramenta | Roteiros |
|--------|-----------|----------|
| [CCNA 200-301](ccna/README.md) | EVE-NG (IOL licenciado), CML ou Packet Tracer | 8 labs |
| [NSE 4 (FortiOS Administrator)](nse4/README.md) | EVE-NG com FortiGate VM 7.6 | 7 labs |

## Formato de cada lab

1. **Objetivo** e tópicos da prova cobertos
2. **Topologia** e plano de endereçamento
3. **Tarefas** em ordem
4. **Verificação**: comandos e resultado esperado
5. **Configuração de referência** (a solução, em bloco recolhível)

## Convenções

- Todos os labs cabem em **até 7 nós**, para funcionar no EVE-NG Freemium e no CML-Free (5 nós, veja a observação de cada lab).
- Nomes de interface Cisco seguem o **IOL** (`Ethernet0/0`, `Ethernet0/1`...). No Packet Tracer, troque por `GigabitEthernet0/0`, `FastEthernet0/1` etc.
- PCs são **VPCS** do EVE-NG. No Packet Tracer, use PCs normais com a mesma configuração IP.
- Senhas usadas nos exemplos (`cisco123`, `Fortinet123!`) são só para laboratório.

## Guardando seus labs

Ao terminar, exporte a topologia e as configurações e salve aqui, em uma pasta por lab:

```
labs/ccna/01-vlans-trunk/
├── README.md         # roteiro (já existe)
└── minhas-configs/   # suas configs exportadas
    ├── SW1.txt
    └── SW2.txt
```

```bash
make backup                 # exporta os .unl do EVE-NG
git add labs/ && git commit -m "Lab CCNA 01 concluído" && git push
```
