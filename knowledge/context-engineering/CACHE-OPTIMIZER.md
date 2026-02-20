# KV-CACHE OPTIMIZER — ATHENA OS 3.0

> **"KV-cache hit rate é a métrica mais importante para eficiência de agents em produção."**
> — Manus Team

---

## VISÃO GERAL

O KV-cache (Key-Value cache) armazena computações intermediárias do transformer. Quando o cache é "hit", tokens custam 10x menos. Otimizar para cache hits é crítico para eficiência.

---

## POR QUE IMPORTA

| Tipo de Token | Custo Relativo |
|---------------|----------------|
| Cached | 1x |
| Uncached | 10x |

**Impacto prático:**
- 90% cache hit = 10x mais barato
- 50% cache hit = 5x mais barato
- 0% cache hit = custo total

---

## PRINCÍPIOS DE OTIMIZAÇÃO

### 1. PROMPT PREFIX STABILITY

**O prefixo do prompt deve ser estável.**

Cache invalida quando o início muda. Manter system prompt, CLAUDE.md, e configuração constantes.

```
✓ BOM: System prompt idêntico entre chamadas
✗ RUIM: Adicionar timestamp no início do prompt
```

**Anti-pattern:**
```markdown
# System Prompt
Current time: 2026-01-20 14:32:45  ← INVALIDA CACHE!
```

---

### 2. APPEND-ONLY CONTEXT

**Adicionar informação nova no final, não modificar o início.**

```
Chamada 1: [System] [Context A]
Chamada 2: [System] [Context A] [Context B]  ← Cache hit em System + A
Chamada 3: [System] [Context A] [Context B] [Context C]  ← Cache hit
```

**Anti-pattern:**
```
Chamada 1: [System] [Context A]
Chamada 2: [System] [Context B]  ← Cache MISS (A removido)
```

---

### 3. DETERMINISTIC SERIALIZATION

**Serializar dados da mesma forma sempre.**

JSON keys em ordem consistente, sem whitespace variável.

```python
# BOM: Ordenado e consistente
json.dumps(data, sort_keys=True)

# RUIM: Ordem aleatória
json.dumps(data)
```

---

### 4. LOGIT MASKING > DYNAMIC TOOL LOADING

**Mascarar ferramentas indisponíveis é melhor que removê-las.**

Remover ferramentas do schema invalida cache. Mascarar mantém schema estável.

```
✓ BOM: Todas as tools no schema, mask unavailable via logits
✗ RUIM: Carregar/descarregar tools dinamicamente
```

---

### 5. ERROR TRACES PRESERVED

**Manter erros no contexto para aprendizado implícito.**

O modelo aprende com falhas anteriores. Remover erros desperdiça essa informação.

```
✓ BOM: Incluir erros e como foram resolvidos
✗ RUIM: Limpar erros do histórico
```

---

## PATTERNS DE IMPLEMENTAÇÃO

### Session Design

```
┌─────────────────────────────────────────────────────────────────┐
│ STABLE PREFIX (cache-friendly)                                  │
│ ├── System Prompt                                               │
│ ├── CLAUDE.md                                                   │
│ ├── Tool Definitions                                            │
│ └── Rules                                                       │
├─────────────────────────────────────────────────────────────────┤
│ APPEND-ONLY BODY                                                │
│ ├── Turn 1: User + Assistant                                    │
│ ├── Turn 2: User + Assistant                                    │
│ ├── Turn 3: User + Assistant                                    │
│ └── ...                                                         │
└─────────────────────────────────────────────────────────────────┘
```

### Compaction Strategy

Quando precisa compactar:
```
ANTES: [Stable] [T1] [T2] [T3] [T4] [T5]
APÓS:  [Stable] [Summary of T1-T4] [T5]
```

Mantém prefix estável, resume meio, preserva recente.

---

## MÉTRICAS A RASTREAR

| Métrica | Como Medir | Target |
|---------|------------|--------|
| Cache Hit Rate | API metrics | > 80% |
| Prefix Stability | Hash do prefix | Constante |
| Invalidations | Count per session | < 5 |

---

## ATHENA-SPECIFIC PATTERNS

### STATE.md como Append-Only

```yaml
# STATE.md cresce append-only
history:
  - timestamp: "T1"
    action: "Started E1"
  - timestamp: "T2"
    action: "Completed T1.1.1"
  - timestamp: "T3"          # Adicionado, não substituído
    action: "Completed T1.1.2"
```

### Tool Definitions Estáveis

```json
{
  "tools": [
    {"name": "Read", "enabled": true},
    {"name": "Write", "enabled": true},
    {"name": "SpecialTool", "enabled": false}  // Masked, not removed
  ]
}
```

### Error Preservation for Learning

```markdown
## Execution Log

### Task T1.1.1
- Attempt 1: Failed - TypeScript error in line 42
- Attempt 2: Failed - Missing import
- Attempt 3: Success - All tests pass

<!-- Erros mantidos para contexto -->
```

---

## ANTI-PATTERNS

### Dynamic System Prompt
```
❌ "Current time: {now}" no início
✓ Timestamp no final ou em tool result
```

### Frequent Context Reordering
```
❌ Reordenar histórico baseado em relevância
✓ Manter ordem cronológica, appendar novo
```

### Tool Schema Churning
```
❌ Adicionar/remover tools entre chamadas
✓ Schema estático, enable/disable via flag
```

### Aggressive History Pruning
```
❌ Remover turns "irrelevantes" do meio
✓ Summarize, mas preservar estrutura
```

---

## IMPLEMENTAÇÃO EM ATHENA

### /athena:execute

1. **Load estável:** Sempre carrega Blueprint da mesma forma
2. **Progress append-only:** STATE.md cresce, não substitui
3. **Error preservation:** Falhas documentadas para learning
4. **Tool stability:** Agents têm tools fixas por tipo

### Ralph Loop

1. **Contexto preservado:** Iterações adicionam, não resetam
2. **Exit check append:** Verificação no final, não modifica início
3. **Summary on compact:** Quando muito grande, summarize meio

---

*ATHENA OS 3.0 — KV-Cache Optimizer*
*"Estabilidade gera eficiência."*
