# /ATHENA:tasks:analyze-budget

> Analisar budget de tokens e recomendar otimizações

---

## Descrição

Estima uso atual de tokens, identifica oportunidades de otimização, e recomenda ações baseadas em thresholds. Previne overflow e otimiza performance de context window.

---

## Uso

```
/ATHENA:tasks:analyze-budget
```

Sem parâmetros. Analisa estado atual automaticamente.

---

## Análise Realizada

1. **Estimate Current Usage**
   - System instructions (~baseline)
   - Tool definitions (~fixed)
   - Conversation history (variável)
   - File reads acumulados

2. **Breakdown por Tipo**
   - System context
   - Tools/functions
   - Messages (user + assistant)
   - Cached content

3. **Threshold Detection**
   - Comparar com limites (GREEN/YELLOW/ORANGE/RED)
   - Identificar proximidade de overflow
   - Calcular margem disponível

4. **Identify Opportunities**
   - Arquivos grandes lidos sem necessidade
   - Redundâncias em conversation
   - Candidatos para summarization
   - Tasks para delegation

---

## Output

```yaml
budget_analysis:
  timestamp: "2026-01-20T15:30:00Z"

  estimated_usage:
    total_tokens: 65000
    percentage: 65%
    threshold_status: "YELLOW"

  breakdown:
    system_instructions: 8000   # 8%
    tool_definitions: 12000     # 12%
    conversation_history: 30000 # 30%
    file_reads: 15000          # 15%

  capacity:
    limit: 100000
    used: 65000
    remaining: 35000
    margin: "Moderate"

  recommendations:
    priority: "MEDIUM"
    actions:
      - "Consider /compact before next complex task"
      - "Delegate deep research tasks to subagent"
      - "3 large files can be pruned from context"

    compaction_opportunity:
      tokens_recoverable: ~15000
      effort: "LOW"

  delegation_candidates:
    - task: "Codebase refactoring analysis"
      reason: "Deep focus required, independent"
      savings: ~8000 tokens
```

---

## Thresholds

| Usage | Status | Description | Action Required |
|-------|--------|-------------|-----------------|
| 0-50% | GREEN | Healthy operation | None |
| 50-70% | YELLOW | Monitor closely | Prune if possible |
| 70-80% | ORANGE | Approaching limit | Consider /compact |
| 80-90% | RED | Critical level | Delegate to subagent |
| 90%+ | CRITICAL | Imminent overflow | Emergency action |

---

## Optimization Strategies

### 1. Conversation Compaction (/compact)
**Quando:** 70%+ usage
**Savings:** 20-40% typical
**Trade-off:** Perde granularidade histórica

```bash
# Suggested usage
/compact --keep-last 10 --summarize-older
```

### 2. Selective File Pruning
**Quando:** Múltiplos arquivos grandes lidos
**Savings:** Variável (por arquivo)
**Trade-off:** Pode precisar re-ler depois

```yaml
files_to_prune:
  - path: "D:/large-config.json"
    size: 5000 tokens
    reason: "Read once, not referenced since"
```

### 3. Subagent Delegation
**Quando:** 80%+ ou task independente
**Savings:** Isola contexto pesado
**Trade-off:** Overhead de delegation

```yaml
delegate:
  task: "Research competitors' pricing models"
  reason: "Deep focus, doesn't need main context"
  expected_savings: 12000 tokens
```

### 4. Progressive Loading
**Quando:** Sempre (preventivo)
**Savings:** Evita preloading
**Trade-off:** Nenhum

```yaml
best_practice:
  - Use Glob/Grep para descobrir
  - Read apenas arquivos relevantes
  - Evitar "ler tudo por precaução"
```

---

## Breakdown Detalhado

### System Instructions (~8-12k tokens)
- CLAUDE.md (~5k)
- Active rules (~2-4k)
- Context engineering rules (~1-3k)

**Otimização:** Não reduzível. Core do sistema.

### Tool Definitions (~10-15k tokens)
- Read, Write, Edit, Bash, Grep, Glob
- Function schemas
- Descriptions

**Otimização:** Não reduzível. Essenciais.

### Conversation History (variável)
- User messages
- Assistant responses
- Tool results

**Otimização:** /compact ou prune old turns.

### File Reads (variável)
- Arquivos lidos com Read
- Armazenados em context

**Otimização:** Prune unused files.

---

## Exemplos Práticos

### Exemplo 1: Status Saudável
```yaml
status: "GREEN"
usage: 45%
recommendation: "Continue normalmente. Budget saudável."
action: None
```

### Exemplo 2: Aproximando Limite
```yaml
status: "ORANGE"
usage: 75%
recommendations:
  - "Execute /compact antes da próxima task complexa"
  - "Considere delegar análise profunda para subagent"
files_to_prune:
  - "old-config.json" (3k tokens)
  - "backup-state.yaml" (2k tokens)
recoverable: 5000 tokens
```

### Exemplo 3: Crítico
```yaml
status: "RED"
usage: 85%
urgent_action: "REQUIRED"
recommendations:
  - "Execute /compact IMEDIATAMENTE"
  - "Delegate remaining work para novo agent"
  - "Prune 4 arquivos grandes"
risk: "Próxima task complexa pode causar overflow"
```

---

## Cálculo de Estimativa

```python
# Pseudo-algorithm
def estimate_usage():
    baseline = 8000  # System + Tools

    # Count conversation tokens
    conv_tokens = sum(len(msg.content) * 1.3 for msg in conversation)

    # Count file read tokens
    file_tokens = sum(file.size for file in files_read)

    total = baseline + conv_tokens + file_tokens
    percentage = (total / CONTEXT_LIMIT) * 100

    return {
        'total': total,
        'percentage': percentage,
        'status': get_threshold(percentage)
    }
```

---

## Anti-Patterns Detectados

### Preloading Files
```
❌ Ler 10 arquivos "para ter contexto"
✓ Usar Grep para buscar, Read apenas relevantes
```

### Hoarding History
```
❌ Manter 50 turnos de conversa
✓ /compact após 20-30 turnos
```

### Speculative Reading
```
❌ "Vou ler esse arquivo caso precise"
✓ Ler apenas quando necessidade confirmada
```

---

## Integration com Outras Features

### Compile-Context
Antes de compilar payload complexo:
```bash
/ATHENA:tasks:analyze-budget
# Se ORANGE/RED → /compact primeiro
/ATHENA:tasks:compile-context deep "..."
```

### Execute Blueprint
Antes de executar Blueprint grande:
```bash
/ATHENA:tasks:analyze-budget
# Se >70% → considerar delegação
```

### Codebase Analysis
Análise pode consumir muito contexto:
```bash
/ATHENA:tasks:analyze-budget
# Se >60% → usar subagent para análise
```

---

## Automation Triggers

Sistema pode auto-sugerir análise quando:
- 20+ arquivos foram lidos
- 30+ turns de conversa
- Task complexa solicitada
- Erro de context overflow ocorreu

---

## Referências

@knowledge/context-engineering/TOKEN-BUDGET.md
@knowledge/context-engineering/CACHE-OPTIMIZER.md
@knowledge/context-engineering/MEMORY-HIERARCHY.md
@.claude/rules/context-budget.md

---

*ATHENA OS 3.0 — Context Engineering*
