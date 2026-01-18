# /ATHENA:tasks:decode-intent

> Fase P1: Decodificação de Intenção (execução isolada)

---

## Descrição

Executa apenas a Fase P1 do pipeline, extraindo a intenção real por trás das palavras do operador e gerando uma Intent Specification estruturada.

---

## Quando Usar

- Quando você quer apenas clarificar uma ideia sem criar Blueprint completo
- Para refinar uma intenção antes de decidir se vale um Blueprint
- Para substituir/melhorar a Intent Spec de um Blueprint em progresso

---

## Fluxo

```
INPUT: Descrição livre do operador
   │
   ▼
EXTRAÇÃO DE DIMENSÕES
   ├── WHAT (explícito, implícito, fora do escopo)
   ├── WHY (razão superficial, razão profunda)
   ├── WHO (operador, beneficiário, stakeholders)
   ├── WHERE (projeto-alvo, localização)
   ├── WHEN (urgência, deadline, dependências)
   └── HOW (constraints, preferências, anti-patterns)
   │
   ▼
FORMULAÇÃO DO JTBD
   "Quando [X], eu quero [Y], para que [Z]."
   │
   ▼
DEFINIÇÃO DE SUCESSO
   ├── MUST HAVE
   ├── SHOULD HAVE
   └── MUST NOT
   │
   ▼
GATE G1: Intent clara?
   │
   ├── PASS ──► intent-spec.yaml gerado
   └── FAIL ──► Solicitar clarificação
```

---

## Instruções para ATHENA

1. Solicitar descrição ao operador
2. Processar usando protocolo `protocols/P1-DECODE.md`
3. Gerar `intent-spec.yaml` conforme template
4. Apresentar resumo e solicitar validação
5. Se validado, salvar em:
   - Se Blueprint ativo: `outputs/blueprints/{date}/{slug}/intent-spec.yaml`
   - Se standalone: `outputs/blueprints/{date}/decode-{timestamp}/intent-spec.yaml`

---

## Output

```yaml
# intent-spec.yaml
metadata:
  id: "INT-{YYYY-MM-DD}-{NNN}"
  version: "1.0.0"
  created_at: "{timestamp}"
  standalone: true | false
  
summary:
  one_liner: ""
  jtbd: ""
  complexity: ""

dimensions:
  # ... (estrutura completa)

success_criteria:
  # ... (estrutura completa)

validation:
  gate: "G1"
  status: "PASSED | FAILED"
```

---

*Comando do ATHENA OS v1.0.0*
