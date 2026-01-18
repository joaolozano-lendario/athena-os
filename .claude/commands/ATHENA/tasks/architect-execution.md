# /ATHENA:tasks:architect-execution

> Fase P2: Arquitetura de Execução (execução isolada)

---

## Descrição

Executa apenas a Fase P2 do pipeline, transformando uma Intent Specification em uma Execution Architecture completa.

---

## Pré-requisitos

- Intent Specification existente (output de P1)
- Ou fornecer intenção inline (P1 será executado implicitamente)

---

## Fluxo

```
INPUT: Intent Specification
   │
   ▼
ANÁLISE DE COMPLEXIDADE
   └── LOW | MEDIUM | HIGH | EXTREME
   │
   ▼
DESIGN DE FASES
   ├── ID, nome, objetivo
   ├── Inputs e outputs
   └── Gate de saída
   │
   ▼
DEFINIÇÃO DE AGENTES (se aplicável)
   ├── Papel e expertise
   └── Quando invocados
   │
   ▼
DESIGN DE WORKFLOW
   ├── Tipo (LINEAR | PARALLEL | etc.)
   ├── Diagrama Mermaid
   └── Fluxo detalhado
   │
   ▼
MAPEAMENTO DE DECISÕES
   └── Pontos onde operador intervém
   │
   ▼
GATE G2: Arquitetura válida?
   │
   ├── PASS ──► exec-arch.yaml gerado
   └── FAIL ──► Revisar arquitetura
```

---

## Instruções para ATHENA

1. Carregar ou solicitar Intent Specification
2. Processar usando protocolo `protocols/P2-ARCHITECT.md`
3. Gerar `exec-arch.yaml` conforme template
4. Apresentar arquitetura com diagrama visual
5. Solicitar validação (Gate G2)
6. Se validado, salvar

---

## Output

```yaml
# exec-arch.yaml
metadata:
  id: "ARCH-{YYYY-MM-DD}-{NNN}"
  intent_id: "{INT-*}"

classification:
  complexity: ""
  type: ""
  
phases:
  - id: "PH-1"
    # ... (estrutura completa)

agents:
  - id: "AGT-1"
    # ... (estrutura completa)

workflow:
  type: ""
  diagram: |
    ```mermaid
    ...
    ```
  flow: []

decision_points: []

validation:
  gate: "G2"
  status: "PASSED | FAILED"
```

---

*Comando do ATHENA OS v1.0.0*
