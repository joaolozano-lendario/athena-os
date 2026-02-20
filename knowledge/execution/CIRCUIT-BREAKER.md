# CIRCUIT BREAKER — ATHENA OS 3.0

> **"Falha rápida é feature, não bug."**

---

## VISÃO GERAL

O Circuit Breaker protege contra loops infinitos, erros repetidos, e consumo excessivo de recursos. Quando ativado, interrompe a execução e escala para o operador ou reseta.

---

## TRIGGERS

### Trigger 1: Loops Sem Progresso

**Threshold:** 3+ iterations consecutivas sem avanço

**Detecção:**
```python
progress_indicators = [
    "file created",
    "file modified",
    "test passed",
    "error fixed",
    "commit made"
]

if last_3_iterations_have_no_indicators:
    trigger_circuit_breaker("no_progress")
```

**Sintomas:**
- Mesmo output repetido
- Nenhum arquivo modificado
- Nenhum teste novo passando

---

### Trigger 2: Mesmo Erro Repetido

**Threshold:** 3x o mesmo erro

**Detecção:**
```python
error_hashes = []
for iteration in iterations:
    if iteration.has_error:
        error_hashes.append(hash(iteration.error))

if error_hashes[-3:] are all same:
    trigger_circuit_breaker("repeated_error")
```

**Sintomas:**
- TypeScript error no mesmo arquivo/linha
- Test failing com mesma mensagem
- Build error idêntico

---

### Trigger 3: Token Limit Approaching

**Threshold:** 90% do context budget

**Detecção:**
```python
if estimated_tokens / max_tokens > 0.90:
    trigger_circuit_breaker("token_limit")
```

**Sintomas:**
- Conversa muito longa
- Muitos arquivos lidos
- Output extenso acumulado

---

### Trigger 4: Time Limit

**Threshold:** --timeout configurado (default 30min)

**Detecção:**
```python
if elapsed_time > timeout_minutes * 60:
    trigger_circuit_breaker("timeout")
```

---

### Trigger 5: Max Iterations

**Threshold:** --max-iterations configurado (default 50)

**Detecção:**
```python
if iteration_count >= max_iterations:
    trigger_circuit_breaker("max_iterations")
```

---

## AÇÕES

### Action Matrix

| Trigger | Severidade | Ação Padrão |
|---------|------------|-------------|
| no_progress | MEDIUM | Escalate to operator |
| repeated_error | HIGH | Reset session + escalate |
| token_limit | MEDIUM | Compact + continue OR escalate |
| timeout | LOW | Save state + pause |
| max_iterations | LOW | Save state + pause |

---

### Action: ESCALATE

Interrompe execução e solicita intervenção do operador.

```
╔═══════════════════════════════════════════════════════════════╗
║              CIRCUIT BREAKER ACTIVATED                        ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Trigger: no_progress                                         ║
║  Task: T1.2.3 - Implement user validation                     ║
║  Iterations: 5                                                ║
║                                                               ║
║  Last 3 attempts:                                             ║
║  - Iteration 3: Modified auth.ts, test still failing          ║
║  - Iteration 4: Modified auth.ts, test still failing          ║
║  - Iteration 5: Modified auth.ts, test still failing          ║
║                                                               ║
║  Apparent blocker:                                            ║
║  Test expects `validateUser` but function returns Promise     ║
║                                                               ║
║  Options:                                                     ║
║  1. [Provide guidance] - Give hint to resolve                 ║
║  2. [Skip task] - Mark as blocked, continue                   ║
║  3. [Abort execution] - Stop completely                       ║
║  4. [Reset and retry] - Fresh context, try again              ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

### Action: RESET SESSION

Limpa contexto e inicia fresh.

```python
def reset_session():
    # Save current state
    save_state_to_file()

    # Clear conversation
    clear_context()

    # Reload minimal context
    load_blueprint()
    load_current_task()

    # Resume with fresh 200K
    continue_execution()
```

---

### Action: COMPACT + CONTINUE

Summariza histórico e continua.

```python
def compact_and_continue():
    # Summarize conversation
    summary = summarize_history()

    # Clear old turns
    clear_old_turns()

    # Inject summary
    inject_summary(summary)

    # Continue
    continue_execution()
```

---

### Action: SAVE STATE + PAUSE

Salva estado para resume posterior.

```python
def save_and_pause():
    # Save to .planning/
    save_state({
        "task": current_task,
        "iteration": iteration_count,
        "last_output": last_output,
        "error_context": error_context
    })

    # Log to observability
    log_circuit_breaker_activation()

    # Exit gracefully
    exit(0)
```

---

## LOGGING

### Circuit Breaker Log

```yaml
# observability/circuit_breaker_log.yaml
version: "1.0.0"
entries:
  - timestamp: "2026-01-20T14:45:00Z"
    blueprint_id: "BP-2026-01-20-001"
    epic: "E1"
    story: "S1.2"
    task: "T1.2.3"
    trigger: "no_progress"
    iterations_at_trigger: 5
    context:
      last_error: "Test failing: validateUser returns Promise"
      files_touched:
        - "src/auth.ts"
      attempts_summary:
        - "Added async/await - still failing"
        - "Changed return type - still failing"
        - "Modified test - still failing"
    action_taken: "escalated_to_operator"
    operator_response: "provided_hint"
    resolution: "resolved_in_iteration_6"
```

---

## RECOVERY PATTERNS

### Pattern 1: Incremental Backoff

Após circuit breaker, reduzir scope:

```
Original: Implement full auth system
After CB: Just implement login endpoint
After success: Add remaining endpoints one by one
```

### Pattern 2: Pivot Approach

Mudar estratégia completamente:

```
Original approach: Build from scratch
After CB: Use existing library (e.g., next-auth)
```

### Pattern 3: Decompose Further

Quebrar task em sub-tasks menores:

```
Original: T1.2.3 - Implement user validation
After CB:
  - T1.2.3a - Add validation schema
  - T1.2.3b - Add validation function
  - T1.2.3c - Add validation tests
```

---

## PREVENÇÃO

### Boas Práticas para Evitar Circuit Breaker

1. **Tasks Atômicas**
   - Scope pequeno e claro
   - Verificação objetiva

2. **Critérios Claros**
   - `<done>` mensurável
   - `<verify>` executável

3. **Progressive Complexity**
   - Começar simples
   - Adicionar complexidade gradualmente

4. **Early Failure Detection**
   - Verificar após cada passo
   - Não acumular mudanças

---

## CONFIGURAÇÃO

### Via Command Line

```bash
/athena:execute blueprint.md \
  --max-iterations 30 \
  --timeout 20 \
  --on-circuit-break escalate
```

### Via Blueprint

```yaml
# ACTIVATION.md
execution_config:
  max_iterations: 50
  timeout_minutes: 30
  circuit_breaker:
    no_progress_threshold: 3
    repeated_error_threshold: 3
    token_limit_percent: 90
    default_action: escalate
```

---

*ATHENA OS 3.0 — Circuit Breaker*
*"Proteção inteligente contra loops infinitos."*
