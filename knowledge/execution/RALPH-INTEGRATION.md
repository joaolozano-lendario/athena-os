# RALPH LOOP INTEGRATION

> **Ralph Loop**: Autonomous iteration system para ATHENA OS | Stop Hook mechanism | Dual-gate completion

**Status:** OPERATIONAL
**Versão:** 2.0.0
**Integração:** ATHENA Execution Engine

---

## VISÃO GERAL

**Ralph Loop** é o motor de iteração autônoma que permite ao Execution Engine processar tasks sem intervenção humana constante, enquanto mantém controle através de Stop Hooks e completion gates.

### O Problema que Resolve

```yaml
Antes (linear):
  Human → Instrução → Claude executa → Para → Aguarda próxima instrução

Depois (Ralph Loop):
  Human → Blueprint → Ralph Loop → 50 tasks executadas → Para apenas em gates
```

### Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                         RALPH LOOP                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  ITERATION CYCLE                                             │  │
│  │                                                              │  │
│  │  1. Load Context (STATE.md + Task XML)                     │  │
│  │  2. Execute Task                                            │  │
│  │  3. Verify Completion                                       │  │
│  │  4. Check Gates                                             │  │
│  │  5. Update State                                            │  │
│  │  6. Commit                                                  │  │
│  │                                                              │  │
│  │  ┌─────────────────────────────────────────────────────┐   │  │
│  │  │ DECISION POINT                                      │   │  │
│  │  │                                                     │   │  │
│  │  │  ├─► Completion Gates Passed? → EXIT              │   │  │
│  │  │  ├─► Stop Hook Triggered? → PAUSE                 │   │  │
│  │  │  ├─► Circuit Breaker? → ESCALATE                  │   │  │
│  │  │  └─► Continue → NEXT ITERATION                    │   │  │
│  │  └─────────────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## STOP HOOK MECHANISM

### O Que São Stop Hooks

**Stop Hooks** são pontos de pausa configurados onde Ralph Loop para e aguarda input humano.

```yaml
Conceito:
  - Executor roda autonomamente
  - Para APENAS em hooks pré-definidos
  - Humano valida/decide
  - Loop continua

Analogia:
  "Rodovia com pedágios planejados,
   não semáforos aleatórios."
```

### Tipos de Stop Hooks

#### 1. Human Verification Checkpoint

```xml
<task type="checkpoint:human-verify">
  <name>Task 5: Validar design de API</name>
  <context>
    API endpoint structure precisa aprovação antes de implementar
  </context>
  <files>docs/api-spec.md</files>
  <action>
    - Apresentar proposta de endpoints
    - Mostrar request/response examples
    - Aguardar aprovação humana
  </action>
  <stop_hook>
    type: human-verify
    prompt: "API design está correto? [y/n/modify]"
    on_approve: continue
    on_reject: return to task 4
    on_modify: incorporate feedback and re-verify
  </stop_hook>
</task>
```

**Quando usar:**
- Decisões de design críticas
- Antes de operações irreversíveis
- Pontos de qualidade especiais

#### 2. Decision Gate

```xml
<task type="checkpoint:decision">
  <name>Task 10: Escolher estratégia de cache</name>
  <context>
    Duas estratégias viáveis: Redis ou in-memory
  </context>
  <files>docs/caching-options.md</files>
  <action>
    - Analisar pros/cons de cada opção
    - Apresentar recomendação com justificativa
    - Aguardar decisão final
  </action>
  <stop_hook>
    type: decision
    options:
      - redis: "Continuar com Redis (tasks 11-15)"
      - memory: "Usar in-memory (tasks 16-20)"
      - hybrid: "Implementar híbrido (nova branch)"
    timeout: 24h
    default: redis
  </stop_hook>
</task>
```

**Quando usar:**
- Bifurcações de execução
- Trade-offs técnicos significativos
- Escolhas que afetam arquitetura

#### 3. Progress Review

```xml
<task type="checkpoint:review">
  <name>Task 20: Review de meio de Sprint</name>
  <context>
    10/20 tasks completadas, checkpoint de progresso
  </context>
  <action>
    - Gerar relatório de progresso
    - Listar tasks completadas com evidências
    - Mostrar metrics (tempo, tokens, issues)
    - Recomendar ajustes se necessário
  </action>
  <stop_hook>
    type: progress-review
    show_metrics: true
    allow_plan_adjustment: true
    continue_after: human-ack
  </stop_hook>
</task>
```

**Quando usar:**
- Milestones de projeto
- Final de cada Epic
- Antes de deployments

### Configuração de Stop Hooks

**No Blueprint:**

```yaml
execution_config:
  stop_hooks:
    enabled: true
    modes:
      - human-verify
      - decision
      - progress-review

    global_settings:
      timeout: 24h              # Auto-continue após timeout
      default_action: pause     # pause | continue | escalate
      notification: slack       # Como notificar humano

    specific_hooks:
      - task_id: 5
        type: human-verify
        required: true

      - task_id: 10
        type: decision
        timeout: 12h

      - task_pattern: "end_of_epic"
        type: progress-review
```

**No .planning/{epic}-N-PLAN.md:**

```yaml
## Stop Hooks Configured

| Task | Type | Reason | Required |
|------|------|--------|----------|
| 5 | human-verify | API design approval | Yes |
| 10 | decision | Cache strategy choice | Yes |
| 20 | progress-review | Mid-sprint checkpoint | No |
| 30 | human-verify | Pre-deployment check | Yes |
```

---

## COMPLETION PROMISE PATTERN

### O Conceito

**Completion Promise** é o contrato entre Ralph Loop e a task sobre quando parar.

```yaml
Problema:
  - Como Ralph sabe que task está realmente completa?
  - Como evitar exit prematuro?
  - Como evitar loop infinito?

Solução:
  Dual-Gate System
```

### Dual-Gate Exit System

```
┌────────────────────────────────────────────────────────────┐
│  COMPLETION GATE 1: Indicators (mínimo 2)                  │
│  ─────────────────────────────────────────────────────────│
│  □ "Task completed successfully"                           │
│  □ "All tests passing"                                     │
│  □ "Implementation verified"                               │
│  □ "Requirements satisfied"                                │
│  □ "Ready to proceed"                                      │
└────────────────────────────────────────────────────────────┘
                        ∧
                        │
                    AND (mandatory)
                        │
                        ∨
┌────────────────────────────────────────────────────────────┐
│  COMPLETION GATE 2: Explicit Signal                        │
│  ─────────────────────────────────────────────────────────│
│  EXIT_SIGNAL: true                                         │
└────────────────────────────────────────────────────────────┘
```

**Ambas portas devem abrir para exit.**

### Exemplo de Completion Promise

```xml
<task type="auto">
  <name>Task 7: Implementar user authentication</name>
  <files>src/auth/*, tests/auth.test.ts</files>
  <action>
    Implementar login/logout com JWT
    Adicionar testes unitários
    Verificar integração com DB
  </action>
  <verify>
    npm test -- auth.test.ts
  </verify>
  <done>
    - Todos testes passando (15/15)
    - JWT gerado e validado corretamente
    - Endpoints /login e /logout funcionais
    - Coverage > 80%
  </done>
  <completion_promise>
    indicators_required: 2
    patterns:
      - "all.*tests.*pass"
      - "implementation.*complete"
      - "verification.*successful"
    explicit_signal: EXIT_SIGNAL
  </completion_promise>
</task>
```

### Output de Completion

```yaml
# Task 7 Execution Report

## Status: COMPLETE

## Indicators Detected: 3/2 required
✓ "All tests passing (15/15)"
✓ "Implementation complete and verified"
✓ "Coverage at 87%, exceeds 80% requirement"

## Verification
Command: npm test -- auth.test.ts
Result: PASS (15/15)
Coverage: 87%

## Files Modified
- src/auth/jwt.ts (new)
- src/auth/middleware.ts (new)
- tests/auth.test.ts (new)

## Metrics
Iterations: 2
Time: 8m 23s
Tokens: 12,450

EXIT_SIGNAL: true
```

**Ralph Loop detecta:**
- Indicators >= 2 ✓
- EXIT_SIGNAL: true ✓
- **→ Exit and proceed to Task 8**

---

## OPÇÕES DE CONFIGURAÇÃO

### Command-line Options

```bash
# Full execution
/execute-blueprint outputs/blueprints/2026-01-20/user-auth-BLUEPRINT.md \
  --max-iterations=50 \
  --timeout=2h \
  --stop-hooks=enabled \
  --auto-commit=true

# Quick mode
/execute-blueprint outputs/blueprints/2026-01-20/user-auth-BLUEPRINT.md \
  --mode=quick \
  --max-iterations=10 \
  --stop-hooks=disabled

# Guided mode
/execute-blueprint outputs/blueprints/2026-01-20/user-auth-BLUEPRINT.md \
  --mode=guided \
  --auto-continue=false \
  --commit-after-each=true
```

### Parâmetros Disponíveis

| Parâmetro | Tipo | Default | Descrição |
|-----------|------|---------|-----------|
| `--max-iterations` | number | 50 | Máximo de loops antes de forçar pausa |
| `--timeout` | duration | 2h | Timeout total de execução |
| `--stop-hooks` | boolean | true | Habilitar/desabilitar hooks |
| `--auto-commit` | boolean | true | Commit automático após cada task |
| `--mode` | enum | full | full \| quick \| guided |
| `--auto-continue` | boolean | true | Continuar após gates (se false = pause) |
| `--circuit-breaker` | boolean | true | Habilitar circuit breaker |
| `--fresh-context` | boolean | true | Usar fresh context pattern |

### Configuration File

```yaml
# .planning/ralph-config.yaml

execution:
  max_iterations: 50
  timeout: 7200  # seconds
  mode: full

stop_hooks:
  enabled: true
  notify_via: console  # console | slack | webhook
  default_action: pause

completion:
  dual_gate: true
  indicators_required: 2
  explicit_signal_required: true

circuit_breaker:
  enabled: true
  max_failed_iterations: 3
  max_same_error: 3
  token_threshold: 0.9

context:
  fresh_context_pattern: true
  max_context_files: 10
  state_always_loaded: true

commits:
  auto_commit: true
  atomic: true
  format: "Task {N}: {description}"
  co_author: "Ralph Loop <ralph@athena-os.ai>"
```

---

## EMERGENCY EXIT: /cancel

### Quando Usar

```yaml
Situações:
  - Execução saiu do controle
  - Erro crítico detectado
  - Precisa pausar imediatamente
  - Blueprint está incorreto
```

### Como Funciona

```bash
# Durante qualquer iteração Ralph
/cancel

# Ralph Loop:
# 1. Para execução imediatamente
# 2. Salva estado atual em STATE.md
# 3. Gera emergency-report.md
# 4. Marca task atual como "interrupted"
# 5. Exit sem completion
```

### Emergency Report

```yaml
# emergency-report.md

## Emergency Exit Triggered

Timestamp: 2026-01-20T14:32:17Z
Triggered by: User command /cancel
Current task: Task 12 (in progress)

## State at Exit

Epic: user-authentication
Story: Backend auth (2/3)
Task: 12/30
Iterations current task: 7
Total iterations: 42/50

## Last Actions
- [14:31:45] Modified src/auth/middleware.ts
- [14:32:03] Running tests
- [14:32:15] Test failure detected (3rd consecutive)
- [14:32:17] /cancel received

## Uncommitted Changes
M src/auth/middleware.ts
M tests/auth.test.ts

## Recommended Recovery
1. Review last changes: git diff
2. Check test failures: npm test
3. Decide: commit partial work or revert
4. Fix issues
5. Resume: /continue-execution or restart task 12

## Circuit Breaker Status
Warnings: 2
Triggers: 0
Would have triggered in: 1 more iteration
```

---

## TROUBLESHOOTING

### Problema: Ralph não para em Stop Hook

**Sintomas:**
```
Task 5 (checkpoint:human-verify) executou e continuou
sem pausar
```

**Diagnóstico:**
```bash
# Verificar configuração
cat .planning/ralph-config.yaml | grep -A5 "stop_hooks"

# Verificar task XML
grep -A10 "task 5" .planning/*-PLAN.md
```

**Soluções:**
```yaml
1. Verificar stop_hooks.enabled: true
2. Confirmar type="checkpoint:*" no XML
3. Checar se <stop_hook> tag está presente
4. Verificar logs em observability/execution_log.yaml
```

---

### Problema: Exit prematuro (antes de task completa)

**Sintomas:**
```
Ralph marcou task como completa mas testes não rodaram
```

**Diagnóstico:**
```yaml
Verificar completion_promise:
  - indicators_required está configurado?
  - EXIT_SIGNAL foi emitido por engano?
```

**Soluções:**
```yaml
1. Aumentar indicators_required para 3
2. Adicionar patterns mais específicos
3. Tornar <verify> obrigatório
4. Usar explicit_signal_required: true
```

**Configuração mais rigorosa:**
```yaml
completion_promise:
  indicators_required: 3
  patterns:
    - "all.*tests.*pass.*\\d+/\\d+"  # Exigir contagem
    - "verification.*successful"
    - "coverage.*>.*\\d+%"           # Exigir métrica
  explicit_signal_required: true
  verify_command_required: true
```

---

### Problema: Loop infinito em task

**Sintomas:**
```
Task 8 executando há 15 iterações sem progresso
Circuit breaker deveria ter ativado
```

**Diagnóstico:**
```bash
# Verificar circuit breaker config
grep -A10 "circuit_breaker" .planning/ralph-config.yaml

# Ver iterations
grep "iteration" .planning/STATE.md

# Logs de progresso
tail -50 observability/execution_log.yaml
```

**Soluções:**
```yaml
1. Reduzir max_failed_iterations de 3 para 2
2. Habilitar circuit_breaker: true
3. Adicionar progress tracking mais rigoroso
4. Usar /cancel e revisar task definition
```

**Fix na task XML:**
```xml
<!-- Antes: vago -->
<done>Authentication working</done>

<!-- Depois: específico -->
<done>
  - npm test -- auth.test.ts shows 15/15 PASS
  - curl localhost:3000/login returns JWT token
  - curl with token returns 200, without returns 401
</done>
```

---

### Problema: Fresh context não carregando arquivos corretos

**Sintomas:**
```
Ralph Loop não encontra função que deveria existir
Parece não ter lido arquivo necessário
```

**Diagnóstico:**
```xml
<!-- Verificar <files> na task XML -->
<task type="auto">
  <name>Task 10: Use helper function</name>
  <files>src/utils/helpers.ts</files>  <!-- Está especificado? -->
  ...
</task>
```

**Soluções:**
```yaml
1. Adicionar arquivo em <files>
2. Usar wildcards: src/utils/*.ts
3. Incluir STATE.md sempre (automático)
4. Verificar fresh_context_pattern: true em config
```

---

### Problema: Commits não são atômicos

**Sintomas:**
```
git log mostra commits com múltiplas tasks
ou tasks sem commit
```

**Diagnóstico:**
```bash
git log --oneline -10
# Verificar se cada commit = 1 task

grep "auto_commit" .planning/ralph-config.yaml
```

**Soluções:**
```yaml
Config:
  auto_commit: true
  atomic: true

Enforced pattern:
  - 1 task complete → 1 commit
  - Task incomplete → no commit
  - Circuit breaker → commit with [WIP] tag
```

---

## INTEGRAÇÃO COM ATHENA OBSERVABILITY

### Real-time Logging

```yaml
# Durante execução, Ralph Loop escreve em:
observability/execution_log.yaml

Formato:
  - timestamp
  - task_id
  - iteration_count
  - action_taken
  - completion_indicators_detected
  - exit_signal_status
  - tokens_used
  - duration
```

### Pattern Detection

```yaml
# ATHENA P5 (LEARN) analisa logs e detecta:

Patterns positivos:
  - Tasks que completam em 1 iteration consistentemente
  - Verification commands que sempre passam
  - Estruturas de task bem definidas

Patterns negativos:
  - Tasks com 5+ iterations frequentemente
  - Circuit breakers repetidos
  - Exit prematuro patterns
```

### Feedback para Blueprint Generation

```yaml
# Aprendizados alimentam próximo P2 (ARCHITECT):

Se task tipo X sempre precisa 5+ iterations:
  → Fragmentar mais no próximo Blueprint

Se stop_hook tipo Y nunca é necessário:
  → Reduzir uso no próximo Blueprint

Se verification command Z sempre falha primeiro:
  → Incluir setup step antes no próximo
```

---

## COMANDOS DE CONTROLE

| Comando | Função | Quando Usar |
|---------|--------|-------------|
| `/execute-blueprint {path}` | Iniciar Ralph Loop | Começar execução |
| `/continue-execution` | Retomar após Stop Hook | Após validação humana |
| `/cancel` | Emergency exit | Erro crítico / pausa necessária |
| `/status` | Ver estado atual | Checar progresso |
| `/skip-task {N}` | Pular task específica | Task não aplicável |
| `/replay-task {N}` | Re-executar task | Task falhou, fix feito |
| `/adjust-plan` | Modificar plan mid-flight | Descoberta de mudança necessária |

---

## FILOSOFIA RALPH

```
"Autonomia não é ausência de controle.
É controle distribuído através de estruturas inteligentes."

Ralph Loop não é um bot rodando cego.
É um executor que:
  - Sabe quando parar (Stop Hooks)
  - Sabe quando continuar (Completion Gates)
  - Sabe quando pedir ajuda (Circuit Breaker)
  - Sabe onde está (STATE.md)

Humanos configuram as regras.
Ralph executa com precisão.
Juntos: Produtividade sem caos.
```

---

*Ralph Loop Integration v2.0.0*
*"Autonomous iteration with intelligent boundaries."*
