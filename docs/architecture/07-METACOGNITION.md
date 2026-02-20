# 07 — META-COGNITION

> **"Pensar sobre como pensar é o primeiro passo para pensar melhor."**

---

## VISÃO GERAL

A camada de Meta-Cognição adiciona dois protocolos ao pipeline:
- **P0: REFLECT** — Reflexão pré-execução
- **P5: LEARN** — Aprendizado pós-execução

---

## P0: REFLECT

### Propósito
Preparar o sistema cognitivo antes de iniciar, consultando histórico e ativando configuração ideal.

### Processo
1. Carregar últimas execuções
2. Detectar natureza do projeto
3. Ativar cognitive kit
4. Montar dream team
5. Antecipar riscos
6. Formular perguntas preventivas

### Gate: G0
Reflexão completa e sistema pronto.

**Localização:** `protocols/P0-REFLECT.md`

---

## P5: LEARN

### Propósito
Capturar aprendizado após execução, alimentando o sistema para melhorar continuamente.

### Processo
1. Avaliar o que funcionou
2. Identificar dificuldades
3. Extrair padrões
4. Calibrar confiança
5. Atualizar knowledge base
6. Sugerir melhorias

### Gate: G5
Aprendizado capturado e sistema atualizado.

**Localização:** `protocols/P5-LEARN.md`

---

## FEEDBACK LOOP

```
P5 (atual) ───► execution_log ───► P0 (próxima)
            ├─► pattern_library ───┘
            └─► lessons_learned ────┘
```

Este loop é o que torna ATHENA um **sistema que aprende**.

---

## COMANDOS

| Comando | Protocolo |
|---------|-----------|
| `/ATHENA:tasks:reflect` | P0: REFLECT |
| `/ATHENA:tasks:learn` | P5: LEARN |

---

## INTEGRAÇÃO

P0 e P5 são executados automaticamente no `/ATHENA:tasks:forge-blueprint`, mas podem ser invocados manualmente quando necessário.

---

*ATHENA OS 2.0 — Architecture: Meta-Cognition*
