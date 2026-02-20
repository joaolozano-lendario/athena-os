# COMPLETION GATES

> **Dual-Gate Completion System** | Pattern detection + Explicit signal | Evitar exits prematuros e loops infinitos

**Status:** OPERATIONAL
**Versão:** 2.0.0
**Owner:** Execution Engine

---

## VISÃO GERAL

Completion Gates são o sistema que determina quando Ralph Loop pode considerar uma task completa e avançar para a próxima.

**Problema que resolve:**
```yaml
Cenário A (exit prematuro):
  Claude: "Implementação iniciada..."
  Ralph: ✓ "Implementação" detectado → EXIT
  Resultado: Task incompleta marcada como completa

Cenário B (loop infinito):
  Claude: "Tentando fix... ainda não funcionou..."
  Ralph: Nenhum exit signal → LOOP
  Resultado: 20 iterações sem progresso
```

**Solução: Dual-Gate System**

```
Gate 1 (Pattern Detection)   +   Gate 2 (Explicit Signal)   =   TRUE COMPLETION
     indicators >= 2          AND    EXIT_SIGNAL: true
```

**Ambas portas devem abrir para considerar task completa.**

---

## DUAL-GATE ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                     COMPLETION GATE SYSTEM                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  GATE 1: INDICATOR DETECTION                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                                                            │ │
│  │  Scan executor output for patterns:                       │ │
│  │  □ "task completed"                                       │ │
│  │  □ "all tests passing"                                    │ │
│  │  □ "implementation done"                                  │ │
│  │  □ "verification successful"                              │ │
│  │  □ "ready to proceed"                                     │ │
│  │                                                            │ │
│  │  Minimum required: 2 indicators                           │ │
│  │                                                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                            ∧                                     │
│                            │                                     │
│                         AND (mandatory)                          │
│                            │                                     │
│                            ∨                                     │
│  GATE 2: EXPLICIT EXIT SIGNAL                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                                                            │ │
│  │  Search for exact string:                                 │ │
│  │                                                            │ │
│  │    EXIT_SIGNAL: true                                      │ │
│  │                                                            │ │
│  │  Must be present in executor output                       │ │
│  │                                                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ═══════════════════════════════════════════════════════════════│
│                                                                  │
│  IF (indicators >= 2) AND (EXIT_SIGNAL: true):                  │
│    → TASK COMPLETE                                              │
│    → Commit changes                                             │
│    → Update STATE.md                                            │
│    → Proceed to next task                                       │
│                                                                  │
│  ELSE:                                                           │
│    → CONTINUE ITERATION                                         │
│    → Check circuit breaker                                      │
│    → Loop                                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## GATE 1: INDICATOR DETECTION

### Indicators Padrão

Ralph Loop procura por estes patterns no output do executor:

```yaml
Completion Indicators (default):
  1. "task.*complete"
  2. "all.*tests.*pass"
  3. "implementation.*done"
  4. "implementation.*complete"
  5. "verification.*successful"
  6. "ready.*to.*proceed"
  7. "requirements.*satisfied"
  8. "acceptance.*criteria.*met"
  9. "deployment.*successful"
  10. "no.*errors"
```

**Configuração mínima:** Pelo menos 2 indicators devem estar presentes.

### Exemplos de Detecção

#### Exemplo 1: Passar (2 indicators)

```markdown
## Task 5 Execution Report

Implementation complete. Created login endpoint at POST /auth/login.

Verification:
$ npm test -- auth.test.ts
✓ All tests passing (15/15)
✓ Coverage: 92%

Files modified:
- src/auth/login.ts (created)
- tests/auth.test.ts (created)

EXIT_SIGNAL: true
```

**Indicators detectados:**
1. ✓ "implementation complete"
2. ✓ "all tests passing"

**Gate 1:** PASS (2/2 required)
**Gate 2:** PASS (EXIT_SIGNAL present)
**Result:** Task complete ✓

---

#### Exemplo 2: Falhar (0 indicators)

```markdown
## Task 5 Progress

Started implementation of login endpoint.
Created file structure.
Next iteration will add logic.
```

**Indicators detectados:** 0

**Gate 1:** FAIL (0/2 required)
**Gate 2:** FAIL (no EXIT_SIGNAL)
**Result:** Continue iteration

---

#### Exemplo 3: Exit prematuro prevenido (1 indicator, sem signal)

```markdown
## Task 5 Status

Implementation done for login endpoint.

Running tests...
Test suite failed (3/15 passing)

Working on fixing failing tests.
```

**Indicators detectados:**
1. ✓ "implementation done"

**Gate 1:** FAIL (1/2 required)
**Gate 2:** FAIL (no EXIT_SIGNAL)
**Result:** Continue iteration (tests não passaram)

---

### Customização de Indicators

Em `ralph-config.yaml`:

```yaml
completion:
  dual_gate: true
  indicators_required: 2

  # Adicionar indicators customizados
  custom_indicators:
    - "deployment.*verified"
    - "smoke.*test.*pass"
    - "database.*migration.*successful"
    - "api.*responding"

  # Indicators obrigatórios (além do mínimo)
  mandatory_indicators:
    - "all.*tests.*pass"  # Este DEVE estar presente sempre

  # Indicators negativos (se presentes, falhar gate)
  negative_indicators:
    - "error|failed|timeout"
    - "tests.*failed"
    - "\\d+.*failing"
```

### Indicators por Task

No XML da task:

```xml
<task type="auto" id="10">
  <name>Task 10: Deploy to staging</name>
  <action>...</action>
  <verify>...</verify>
  <done>...</done>

  <completion_promise>
    <indicators_required>3</indicators_required>
    <custom_indicators>
      <indicator>deployment.*successful</indicator>
      <indicator>health.*check.*passing</indicator>
      <indicator>smoke.*tests.*pass</indicator>
    </custom_indicators>
    <mandatory_indicators>
      <indicator>all.*tests.*pass</indicator>
      <indicator>deployment.*verified</indicator>
    </mandatory_indicators>
  </completion_promise>
</task>
```

---

## GATE 2: EXPLICIT EXIT SIGNAL

### O Sinal

Ralph Loop procura por string exata:

```
EXIT_SIGNAL: true
```

**Regras:**
- Deve estar no output do executor
- Case-insensitive
- Formato exato esperado
- Qualquer variação não é reconhecida

### Exemplos Válidos

```yaml
# Válido
EXIT_SIGNAL: true

# Válido (case-insensitive)
exit_signal: true

# Válido (com contexto)
## Completion Status
EXIT_SIGNAL: true

# INVÁLIDO (não reconhecido)
EXIT_SIGNAL: yes
EXIT_SIGNAL = true
EXITSIGNAL: true
```

### Quando Emitir

Executor deve emitir `EXIT_SIGNAL: true` quando:

1. **Todos critérios de <done> satisfeitos**
   ```
   <done>
     - Tests passing (15/15)
     - Endpoint responding
     - Coverage > 80%
   </done>

   ✓ Tests: 15/15
   ✓ Endpoint: curl returns 200
   ✓ Coverage: 87%

   → EXIT_SIGNAL: true
   ```

2. **Comando <verify> executado com sucesso**
   ```
   <verify>npm test -- auth.test.ts</verify>

   $ npm test -- auth.test.ts
   ✓ All tests passed (15/15)

   → EXIT_SIGNAL: true
   ```

3. **Verificação manual confirmada**
   ```
   Manual verification:
   $ curl localhost:3000/auth/login
   {"token": "eyJ..."}  ✓

   → EXIT_SIGNAL: true
   ```

### Quando NÃO Emitir

```yaml
NÃO emitir se:
  - Testes falharam (mesmo parcialmente)
  - Critérios de <done> não 100% satisfeitos
  - Erro encontrado
  - Incerteza sobre completion
  - Checkpoint humano necessário (use stop_hook)
```

---

## TIPOS DE CHECKPOINTS

### 1. Human Verification Checkpoint

**Gate behavior:**
- Gate 1: N/A (não aplicável)
- Gate 2: Requires human input

```xml
<task type="checkpoint:human-verify" id="15">
  <name>Task 15: Review API design</name>
  <action>Present API spec, await approval</action>
  <stop_hook>
    type: human-verify
    prompt: "API design approved? [yes/no/modify]"
  </stop_hook>
  <done>Human approval received</done>
</task>
```

**Completion:**
```
Human input: "yes" → EXIT_SIGNAL: true (automatic)
Human input: "modify" → Incorporate feedback, re-verify
Human input: "no" → Return to previous task
```

---

### 2. Decision Gate

**Gate behavior:**
- Gate 1: N/A
- Gate 2: Requires decision selection

```xml
<task type="checkpoint:decision" id="20">
  <name>Task 20: Choose caching strategy</name>
  <action>Analyze options, present recommendation</action>
  <stop_hook>
    type: decision
    options:
      - redis: "Use Redis"
      - memory: "Use in-memory"
      - hybrid: "Use hybrid approach"
    recommendation: memory
  </stop_hook>
  <done>Decision made and documented</done>
</task>
```

**Completion:**
```
Human selects option → Document decision → EXIT_SIGNAL: true (automatic)
```

---

### 3. Progress Review

**Gate behavior:**
- Gate 1: N/A
- Gate 2: Requires human acknowledgment

```xml
<task type="checkpoint:review" id="30">
  <name>Task 30: End of Epic review</name>
  <action>Generate progress report, show metrics</action>
  <stop_hook>
    type: progress-review
    show_metrics: true
  </stop_hook>
  <done>Report reviewed, acknowledged</done>
</task>
```

**Completion:**
```
Human acknowledges → EXIT_SIGNAL: true (automatic)
```

---

## PATTERN DETECTION EXAMPLES

### Scenario 1: Implementação de Feature

**Task XML:**
```xml
<task type="auto" id="8">
  <name>Task 8: Implement login endpoint</name>
  <verify>npm test -- auth.test.ts</verify>
  <done>
    - POST /auth/login endpoint responding
    - Valid credentials return JWT
    - Invalid credentials return 401
    - All tests passing (10/10)
  </done>
</task>
```

**Executor Output (SUCCESS):**
```markdown
## Task 8: Login Endpoint Implementation

### Implementation
Created POST /auth/login endpoint at src/auth/login.ts.

Logic:
1. Extract email/password from request body
2. Query user from database
3. Compare password hash with bcrypt
4. If valid: generate JWT and return
5. If invalid: return 401 Unauthorized

### Verification
$ npm test -- auth.test.ts

PASS  tests/auth.test.ts
  ✓ should return JWT on valid credentials (42ms)
  ✓ should return 401 on invalid password (38ms)
  ✓ should return 401 on non-existent email (35ms)
  ✓ should validate request body schema (12ms)
  ✓ should hash password with bcrypt (45ms)
  [... 5 more tests ...]

Test Suites: 1 passed, 1 total
Tests:       10 passed, 10 total

All tests passing (10/10) ✓

### Manual Test
$ curl -X POST localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}'

Response: 200 OK
{"token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."}

Endpoint responding correctly ✓

### Done Criteria Check
✓ POST /auth/login endpoint responding
✓ Valid credentials return JWT
✓ Invalid credentials return 401
✓ All tests passing (10/10)

All acceptance criteria satisfied.

EXIT_SIGNAL: true
```

**Gate Detection:**
- Indicator 1: ✓ "all tests passing"
- Indicator 2: ✓ "endpoint responding correctly"
- Indicator 3: ✓ "acceptance criteria satisfied"
- Exit Signal: ✓ "EXIT_SIGNAL: true"

**Result:** Task COMPLETE ✓

---

### Scenario 2: Implementação com Erro

**Executor Output (FAILURE):**
```markdown
## Task 8: Login Endpoint Implementation

### Implementation
Created POST /auth/login endpoint.

### Verification
$ npm test -- auth.test.ts

FAIL  tests/auth.test.ts
  ✓ should return JWT on valid credentials (42ms)
  ✗ should return 401 on invalid password (38ms)
    Expected: 401
    Received: 500
  ✗ should return 401 on non-existent email (35ms)
    Expected: 401
    Received: 500
  [... more failures ...]

Test Suites: 1 failed, 1 total
Tests:       3 failed, 7 passed, 10 total

Tests failing (3/10). Investigating errors.

Issue found: Not handling bcrypt comparison errors correctly.
Fixing in next iteration...
```

**Gate Detection:**
- Indicator 1: ✗ (no completion indicators)
- Exit Signal: ✗ (no EXIT_SIGNAL)

**Result:** Continue iteration (fix errors)

---

### Scenario 3: Progresso Parcial

**Executor Output (IN PROGRESS):**
```markdown
## Task 8: Login Endpoint - Iteration 2

### Progress
Implementation done. Endpoint created and basic logic in place.

### Testing
Running tests...

$ npm test -- auth.test.ts

PASS  tests/auth.test.ts
  ✓ should return JWT on valid credentials (42ms)
  ✓ should return 401 on invalid password (38ms)
  [... 8/10 passing ...]
  ✗ should rate limit after 5 attempts (timeout)
  ✗ should log failed attempts (assertion error)

Test Suites: 1 failed, 1 total
Tests:       2 failed, 8 passed, 10 total

Implementation done, but 2 tests still failing.
Working on rate limiting and logging in next iteration.
```

**Gate Detection:**
- Indicator 1: ✓ "implementation done"
- Indicator 2: ✗ (tests not all passing)
- Exit Signal: ✗

**Result:** Continue iteration (Gate 1 failed: only 1/2 indicators)

---

## CIRCUIT BREAKER INTEGRATION

Completion Gates trabalham com Circuit Breaker para prevenir loops infinitos.

```yaml
Scenario: Task iterando sem progresso

Iteration 1:
  Indicators: 0/2
  EXIT_SIGNAL: false
  Circuit Breaker: No progress (1/3)
  → Continue

Iteration 2:
  Indicators: 0/2
  EXIT_SIGNAL: false
  Circuit Breaker: No progress (2/3)
  → Continue

Iteration 3:
  Indicators: 0/2
  EXIT_SIGNAL: false
  Circuit Breaker: No progress (3/3) → TRIGGERED
  → Pause, escalate to human
```

Ver `CIRCUIT-BREAKER.md` para detalhes.

---

## CONFIGURAÇÃO AVANÇADA

### Por Projeto (ralph-config.yaml)

```yaml
completion:
  # Sistema dual-gate ativo
  dual_gate: true

  # Mínimo de indicators
  indicators_required: 2

  # Aumentar para tasks críticas
  critical_task_indicators: 3

  # Exit signal obrigatório
  explicit_signal_required: true

  # Verificação de comando obrigatória
  verify_command_required: true

  # Indicators customizados
  custom_indicators:
    - "deployment.*verified"
    - "smoke.*tests.*pass"

  # Mandatory (além do mínimo)
  mandatory_indicators:
    - "all.*tests.*pass"

  # Negative (se presentes, fail)
  negative_indicators:
    - "error|failed|timeout"
    - "tests.*failed"

  # Timeout: considerar incomplete após X iterations
  max_iterations_per_task: 5
```

### Por Task (completion_promise)

```xml
<task type="auto" id="25">
  <name>Task 25: Deploy to production</name>
  <action>...</action>
  <verify>...</verify>
  <done>...</done>

  <completion_promise>
    <!-- Mais rigoroso para produção -->
    <indicators_required>4</indicators_required>

    <success_patterns>
      <pattern>deployment.*successful</pattern>
      <pattern>all.*tests.*pass</pattern>
      <pattern>health.*check.*pass</pattern>
      <pattern>smoke.*test.*pass</pattern>
      <pattern>rollback.*plan.*ready</pattern>
    </success_patterns>

    <mandatory_indicators>
      <indicator>all.*tests.*pass</indicator>
      <indicator>deployment.*verified</indicator>
      <indicator>health.*check.*pass</indicator>
    </mandatory_indicators>

    <failure_patterns>
      <pattern>deployment.*failed</pattern>
      <pattern>health.*check.*fail</pattern>
      <pattern>error.*rate.*high</pattern>
    </failure_patterns>

    <required_verifications>
      <command>npm test</command>
      <command>npm run deploy:verify</command>
      <command>npm run smoke-test</command>
    </required_verifications>

    <explicit_signal_required>true</explicit_signal_required>
    <max_iterations>3</max_iterations>
  </completion_promise>
</task>
```

---

## TROUBLESHOOTING

### Problema: Task marcada completa prematuramente

**Sintoma:**
```
Task 10 marcada como completa, mas testes não rodaram
```

**Diagnóstico:**
```yaml
Verificar output do executor:
  - Quantos indicators detectados?
  - EXIT_SIGNAL presente?
  - Falso positivo em pattern detection?
```

**Solução:**
```yaml
1. Aumentar indicators_required de 2 para 3
2. Adicionar mandatory_indicators específicos
3. Tornar verify_command_required: true
4. Usar patterns mais específicos (evitar genéricos)
```

---

### Problema: Task nunca completa (loop infinito)

**Sintoma:**
```
Task 12 em 8ª iteração, sempre "quase pronto"
```

**Diagnóstico:**
```yaml
Verificar:
  - EXIT_SIGNAL sendo emitido?
  - Indicators sendo detectados mas signal ausente?
  - Circuit breaker deveria ter ativado?
```

**Solução:**
```yaml
1. Adicionar max_iterations à completion_promise
2. Verificar se executor entende quando emitir EXIT_SIGNAL
3. Reduzir max_failed_iterations no circuit breaker
4. Revisar <done> criteria (muito vagos?)
```

---

### Problema: Indicators detectados incorretamente

**Sintoma:**
```
Ralph detecta "implementation done" quando executor disse
"implementation done reviewing options" (não conclusão)
```

**Diagnóstico:**
```
Pattern muito amplo: "implementation.*done"
```

**Solução:**
```yaml
Usar patterns mais específicos:

# Antes (amplo)
- "implementation.*done"

# Depois (específico)
- "implementation.*complete.*and.*verified"
- "implementation.*done.*all.*tests.*pass"

Ou adicionar negative patterns:
- "done.*reviewing"
- "done.*analyzing"
```

---

## FILOSOFIA DUAL-GATE

```
Um portão falha.
Dois portões, protegem.

Pattern detection sozinho → falsos positivos
Exit signal sozinho → esquecimento humano

Juntos → precisão

Completion não é guess work.
É verificação estruturada.
```

**Por que dois gates:**

1. **Gate 1 (Indicators)** - Evidência objetiva
   - Previne exit sem trabalho feito
   - Patterns validam progresso real

2. **Gate 2 (Exit Signal)** - Intenção explícita
   - Previne exit acidental
   - Executor confirma completion consciente

**Resultado:** Confiança em automation com safety.

---

*Completion Gates v2.0.0*
*"Two gates are better than one guess."*
