# TOKEN BUDGET MANAGEMENT — ATHENA OS 3.0

> **"Contexto é moeda. Gastar com sabedoria."**

---

## VISÃO GERAL

O context window do Claude Code é limitado a ~200K tokens. Gerenciar esse budget é crítico para performance e eficiência.

---

## BREAKDOWN DO BUDGET

```
┌─────────────────────────────────────────────────────────────────┐
│                    200K TOKENS (TOTAL)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  SYSTEM OVERHEAD          ~50K tokens                           │
│  ├── Claude Code System Prompt    ~30K                         │
│  ├── Tool Definitions             ~15K                         │
│  └── Base Instructions            ~5K                          │
│                                                                 │
│  MCP OVERHEAD             ~20K (max recommended)                │
│  ├── Server Definitions                                        │
│  └── Tool Schemas                                              │
│                                                                 │
│  USER MEMORY              ~5-10K                                │
│  ├── CLAUDE.md            (keep <3K)                           │
│  ├── Rules                (conditional)                        │
│  └── Local overrides                                           │
│                                                                 │
│  WORKING CONTEXT          ~120-130K                             │
│  ├── Conversation History                                      │
│  ├── File Contents                                             │
│  ├── Tool Results                                              │
│  └── Current Task                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## INSTRUCTION BUDGET

LLMs podem seguir confiavelmente **100-150 instruções**.

| Fonte | Instruções |
|-------|------------|
| Claude Code System | ~50 |
| CLAUDE.md (user) | ~50-100 |
| Rules (conditional) | ~20-30 |

**Regra:** Quanto mais instruções, menor a aderência a cada uma. Priorize.

---

## THRESHOLDS E AÇÕES

| Usage | Status | Ação Recomendada |
|-------|--------|------------------|
| 0-50% | GREEN | Normal operation |
| 50-70% | YELLOW | Monitor, consider pruning |
| 70-80% | ORANGE | Trigger /compact |
| 80-90% | RED | Delegate to subagent |
| 90%+ | CRITICAL | Emergency summary, split task |

---

## ESTRATÉGIAS DE OTIMIZAÇÃO

### 1. Progressive Loading
Usar `@filename` para carregar sob demanda, não upfront.

```markdown
# CLAUDE.md

## References
See @docs/architecture.md for system design
See @docs/api.md for API details
```

Claude carrega apenas quando necessário.

### 2. Aggressive Summarization
Resumir antes de prosseguir em conversas longas.

```
Após ~20 turns, considerar /compact
```

### 3. Subagent Delegation
Delegar tarefas focadas para subagents com fresh 200K context.

```
Main agent (orchestrator) → Subagent (executor)
                         → Subagent (researcher)
```

### 4. Tool Result Truncation
Limitar output de ferramentas quando possível.

```
Read: Use offset/limit para arquivos grandes
Grep: Limitar results com head_limit
```

### 5. Memory Hygiene
Manter CLAUDE.md lean:
- < 300 linhas
- Apenas informação universalmente aplicável
- Sem exemplos longos (ficam stale)
- Sem código inline

---

## MCP OVERHEAD WARNING

> **Se MCP overhead > 20K tokens, você está significativamente limitando working context.**

MCP tools adicionam schema overhead. Usar apenas servers realmente necessários.

---

## MÉTRICAS A RASTREAR

| Métrica | Como Medir | Target |
|---------|------------|--------|
| Total Usage | /context | < 70% idle |
| Conversation Length | Turn count | < 20 turns |
| File Loads | Count @references | Minimal |
| Tool Calls | Per task | Right-sized |

---

## COMANDOS ÚTEIS

| Comando | Função |
|---------|--------|
| `/context` | Visualizar uso de contexto |
| `/compact` | Summarizar e comprimir |
| `/clear` | Reset completo |
| `/athena:analyze-budget` | Análise detalhada |

---

## ANTI-PATTERNS

### Preloading "Just in Case"
**Ruim:** Carregar 10 arquivos no início
**Bom:** Carregar sob demanda via @reference

### Giant CLAUDE.md
**Ruim:** 1000+ linhas de instruções
**Bom:** < 300 linhas focadas

### Ignoring Tool Output Size
**Ruim:** `cat huge_file.log` via Bash
**Bom:** `Read` com limit ou `Grep` filtrado

### No Compaction Strategy
**Ruim:** Conversa infinita sem /compact
**Bom:** /compact a cada milestone

---

## ECONOMIA DE TOKENS

| Técnica | Economia Estimada |
|---------|-------------------|
| Progressive @loading | 30-50% |
| Subagent delegation | Fresh 200K per task |
| Aggressive /compact | 50-70% history reduction |
| Tool right-sizing | 20-40% per call |

---

*ATHENA OS 3.0 — Token Budget Management*
*"Contexto é finito. Gastar com sabedoria."*
