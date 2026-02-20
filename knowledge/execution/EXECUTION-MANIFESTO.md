# EXECUTION MANIFESTO

> **Get Shit Done**: Iteração sobre Perfeição | Progresso sobre Planejamento Infinito | Resultados sobre Intenções

**Status:** OPERATIONAL
**Versão:** 2.0.0
**Owner:** Execution Engine

---

## FILOSOFIA

### A Doutrina GSD

```
PERFECCIONISMO É PARALISIA
ITERAÇÃO É PROGRESSO
EXECUÇÃO É APRENDIZADO
FEITO > PERFEITO
```

**Get Shit Done** não é sobre trabalho desleixado. É sobre:

- **Ciclos curtos** em vez de planejamento infinito
- **Feedback real** em vez de suposições teóricas
- **Progresso mensurável** em vez de atividade sem resultado
- **Aprendizado incorporado** através de iteração rápida

### Princípios Fundamentais

1. **ITERATION OVER PERFECTION**
   - Primeira versão pode ser básica, mas deve FUNCIONAR
   - Refinar através de ciclos rápidos
   - Cada iteração incorpora aprendizado real

2. **AUTONOMOUS EXECUTION**
   - Executor opera com mínima intervenção humana
   - Stop Hooks para gates humanos apenas quando necessário
   - Decisões estruturadas através de checkpoints

3. **FRESH CONTEXT PATTERN**
   - Cada task começa com contexto limpo (200K tokens)
   - Carregar apenas o necessário
   - Evitar poluição de contexto

4. **ATOMIC COMMITS**
   - Cada task concluída = 1 commit
   - Mensagens descritivas e padronizadas
   - Rastreabilidade total do progresso

5. **MEASURABLE COMPLETION**
   - Nada está "done" sem critério verificável
   - Completion gates com evidência objetiva
   - Dual-gate system: indicators + EXIT_SIGNAL

---

## WORKFLOW DE EXECUÇÃO

### Pipeline Completo

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ATHENA EXECUTION PIPELINE                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  FASE 1: BLUEPRINT INTAKE                                           │
│  ├─► Ler Blueprint do outputs/blueprints/                          │
│  ├─► Validar estrutura (P4 compliance)                             │
│  ├─► Carregar dependencies                                          │
│  └─► Criar .planning/ structure                                     │
│                                                                      │
│  FASE 2: PLANNING DECOMPOSITION                                     │
│  ├─► Gerar {epic}-1-PLAN.md inicial                                │
│  ├─► Fragmentar em XML tasks                                        │
│  ├─► Configurar Stop Hooks                                          │
│  └─► Inicializar STATE.md                                           │
│                                                                      │
│  FASE 3: RALPH LOOP EXECUTION                                       │
│  ├─► Processar task atual                                           │
│  ├─► Verificar completion gates                                     │
│  ├─► Circuit breaker monitoring                                     │
│  ├─► Atualizar STATE.md                                             │
│  ├─► Commit atômico                                                 │
│  └─► Loop até EXIT_SIGNAL ou max iterations                        │
│                                                                      │
│  FASE 4: COMPLETION & HANDOFF                                       │
│  ├─► Verificar dual-gate completion                                 │
│  ├─► Gerar execution report                                         │
│  ├─► Arquivar em .planning/archive/                                │
│  └─► Atualizar observability/execution_log.yaml                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Ciclo de uma Task (Ralph Loop)

```
1. LOAD CONTEXT
   └─► Ler STATE.md + task atual + files relevantes

2. EXECUTE
   └─► Implementar conforme <action>

3. VERIFY
   └─► Rodar comando do <verify>

4. CHECK GATES
   └─► Completion indicators >= 2?
   └─► EXIT_SIGNAL: true?

5. UPDATE STATE
   └─► Atualizar STATE.md com progresso

6. COMMIT
   └─► git commit -m "Task N: {description}"

7. DECISION POINT
   ├─► Gates passed → EXIT
   ├─► Stop Hook triggered → PAUSE
   ├─► Circuit breaker → ESCALATE
   └─► Continue → NEXT ITERATION
```

---

## PRINCÍPIOS CORE

### 1. Autonomous Iteration

**O executor opera independentemente até encontrar:**
- Stop Hook (checkpoint humano configurado)
- Circuit breaker trigger (3 loops sem progresso)
- Completion gate satisfeito

**Não deve:**
- Pedir permissão para cada micro-decisão
- Parar por incerteza navegável
- Esperar validação de progresso óbvio

### 2. Fresh Context Pattern

**Problema:** Contexto acumula ruído através de iterações.

**Solução:**
```yaml
Início de cada task:
  1. Carregar STATE.md (verdade atual)
  2. Carregar task XML específica
  3. Carregar apenas files mencionados em <files>
  4. Ignorar resto do histórico da conversa
```

**Benefícios:**
- 200K tokens usados com eficiência
- Zero confusão de iterações anteriores
- Foco no que importa agora

### 3. Atomic Commits

**Regra de Ouro:** 1 task completada = 1 commit

**Formato de mensagem:**
```
Task {N}: {Ação realizada}

- {Detalhe 1}
- {Detalhe 2}

Verify: {comando rodado}
Result: {resultado}

Epic: {epic-name}
Story: {story-name} ({M}/{Total})
```

**Exemplo:**
```
Task 3: Implementar autenticação JWT

- Criado middleware auth.ts
- Adicionado verificação de token
- Testes passando (12/12)

Verify: npm test -- auth
Result: All tests passed

Epic: user-auth
Story: Backend auth (3/5)
```

### 4. Dual-Gate Completion

**Sistema de duas portas para evitar exits prematuros:**

```yaml
Gate 1 - Completion Indicators (mínimo 2 de):
  - "Task completed"
  - "All tests passing"
  - "Implementation done"
  - "Verification successful"
  - "Ready to move on"

Gate 2 - Explicit Exit Signal:
  - EXIT_SIGNAL: true no output
```

**Ambos devem estar presentes para exit verdadeiro.**

Ver `COMPLETION-GATES.md` para detalhes completos.

### 5. Circuit Breaker Protection

**Prevenir loops infinitos através de triggers:**

```yaml
Trigger Conditions:
  - 3+ iterações sem progresso medido
  - Mesmo erro aparecendo 3x consecutivas
  - Token usage > 90% do limite
  - Timeout excedido (configurável)

Actions:
  - Log detalhado do estado
  - Pausar execução
  - Escalate para humano
  - Aguardar instrução de recovery
```

Ver `CIRCUIT-BREAKER.md` para detalhes.

### 6. State as Single Source of Truth

**STATE.md é a memória viva do projeto:**

```yaml
Atualizado a cada:
  - Task completada
  - Stop Hook atingido
  - Circuit breaker triggered
  - Decision gate alcançado

Contém:
  - Progresso atual (Epic/Story/Task)
  - Decisões tomadas
  - Blockers encontrados
  - Next steps
  - Iteration count
  - Token metrics
```

**Regra:** Se não está no STATE.md, não aconteceu.

---

## MODOS DE OPERAÇÃO

### 1. Full Execution Mode

```bash
/execute-blueprint {blueprint-path}
  --mode=full
  --max-iterations=50
  --timeout=2h
```

**Comportamento:**
- Processar Blueprint completo
- Criar estrutura .planning/
- Executar todas tasks sequencialmente
- Pausar apenas em Stop Hooks

### 2. Quick Mode

```bash
/execute-blueprint {blueprint-path}
  --mode=quick
  --max-iterations=10
```

**Comportamento:**
- Usar .planning/quick/ structure
- Tasks menores e mais diretas
- Menos checkpoints
- Para trabalho exploratório

### 3. Guided Mode

```bash
/execute-blueprint {blueprint-path}
  --mode=guided
  --auto-continue=false
```

**Comportamento:**
- Pausar após cada task
- Aguardar confirmação humana
- Ideal para trabalho crítico
- Mais Stop Hooks

---

## INTEGRAÇÃO COM ATHENA

### Handoff do Blueprint

```yaml
ATHENA Forge (P0-P4):
  Output: Blueprint completo em outputs/blueprints/{date}/

Execution Engine:
  Input: Mesmo Blueprint
  Process: Converte Blueprint → .planning/ → Execução
  Output: Projeto implementado + execution_log.yaml
```

### Feedback Loop (P5)

```yaml
Após execução:
  1. Execution Engine gera execution_report.md
  2. ATHENA P5 (LEARN) analisa report
  3. Patterns descobertos → pattern_library.yaml
  4. Guardrails atualizados se necessário
  5. Próximo Blueprint usa aprendizado
```

### Observability Integration

```yaml
Durante execução:
  - Real-time updates → observability/execution_log.yaml
  - Metrics tracking (tempo, tokens, iterations)
  - Pattern detection ativo
  - Anomaly alerts
```

---

## MÉTRICAS DE SUCESSO

### Quantitativas

```yaml
Eficiência:
  - Tasks/hora
  - Token usage/task
  - Iterations médias para completion
  - Circuit breaker triggers (menos é melhor)

Qualidade:
  - Tests passing %
  - Commits atômicos %
  - Zero regress deployments

Autonomia:
  - Human interventions/blueprint
  - Stop Hooks necessários vs configurados
```

### Qualitativas

```yaml
Transferibilidade:
  - Blueprint → Execution sem ambiguidade?
  - Outro executor consegue continuar?

Rastreabilidade:
  - Cada decisão documentada?
  - Git history conta história completa?

Aprendizado:
  - Patterns capturados?
  - Próxima execução mais eficiente?
```

---

## ANTI-PATTERNS

### 1. Planejamento Infinito

```diff
- Refinar plano até perfeição antes de começar
+ Plano básico → Executar → Refinar baseado em feedback real
```

### 2. Big Bang Execution

```diff
- Implementar tudo → Testar tudo junto
+ Task pequena → Testar → Commit → Próxima task
```

### 3. Silent Failures

```diff
- Task "completa" mas testes não rodados
+ Completion gate exige <verify> executado com sucesso
```

### 4. Context Pollution

```diff
- Carregar todo histórico a cada iteração
+ Fresh context: STATE.md + task atual + files específicos
```

### 5. Premature Exit

```diff
- "Acho que está pronto" → EXIT
+ Dual-gate: indicators >= 2 AND EXIT_SIGNAL: true
```

---

## COMANDOS PRINCIPAIS

| Comando | Função |
|---------|--------|
| `/execute-blueprint {path}` | Iniciar execução completa |
| `/continue-execution` | Retomar após Stop Hook |
| `/cancel` | Emergency exit com state save |
| `/status` | Ver progresso atual |
| `/replay-task {N}` | Re-executar task específica |

---

## FILOSOFIA FINAL

```
"A execução perfeita não existe.
Existem apenas ciclos de execução
que aprendem a ser melhores."

ATHENA fornece estrutura.
Ralph Loop fornece autonomia.
GSD fornece mentalidade.

Juntos: Transformam Blueprints em realidade,
iteração após iteração,
commit após commit,
aprendizado após aprendizado.
```

---

*Execution Engine v2.0.0*
*"Done is better than perfect. Iterated done is excellence."*
