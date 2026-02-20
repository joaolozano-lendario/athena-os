# /athena:execute

> Executar Blueprint completo com Ralph Loop integration

---

## Descrição

Comando principal de execução do ATHENA OS 3.0. Transforma Blueprint em realidade através de:

- **Ralph Loop** - Iteração autônoma controlada
- **Dual-gate completion** - Pattern detection + EXIT_SIGNAL
- **Multi-agent orchestration** - Delegação inteligente
- **Circuit Breaker** - Proteção contra loops infinitos
- **Atomic commits** - 1 task = 1 commit
- **Fresh context pattern** - Contexto limpo por task
- **Observability** - Logging completo de execução

Este é o motor que executa o que os Blueprints especificam.

---

## Uso

```bash
/athena:execute [blueprint-path] [options]
```

### Exemplos

```bash
# Execução completa padrão
/athena:execute outputs/blueprints/2026-01-20/my-blueprint

# Com opções customizadas
/athena:execute outputs/blueprints/2026-01-20/my-blueprint \
  --max-iterations 30 \
  --timeout 1h \
  --mode guided

# Executar epic específico
/athena:execute outputs/blueprints/2026-01-20/my-blueprint --epic E1

# Modo rápido (skip verification)
/athena:execute outputs/blueprints/2026-01-20/my-blueprint --mode quick

# Dry-run (simular sem executar)
/athena:execute outputs/blueprints/2026-01-20/my-blueprint --dry-run
```

---

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--max-iterations` | number | 50 | Máximo de loops Ralph antes de pausar |
| `--timeout` | duration | 2h | Timeout total de execução |
| `--mode` | enum | full | `full` \| `quick` \| `guided` |
| `--epic` | string | all | Executar apenas epic específico (ex: E1) |
| `--parallel` | boolean | true | Habilitar execução paralela de tasks |
| `--auto-commit` | boolean | true | Commit automático após cada task |
| `--fresh-context` | boolean | true | Usar fresh context pattern |
| `--stop-hooks` | boolean | true | Respeitar stop hooks (checkpoints) |
| `--circuit-breaker` | boolean | true | Habilitar circuit breaker |
| `--dry-run` | boolean | false | Simular execução sem modificar arquivos |
| `--resume-from` | string | null | Retomar de epic/task específico |

### Modes

**full** (padrão)
- Execução completa com todas verificações
- Stop hooks habilitados
- Human verification checkpoints
- Observability completa

**quick**
- Skip verification steps
- No stop hooks (exceto obrigatórios)
- Velocidade sobre segurança
- Usar com cautela

**guided**
- Pausar após cada epic
- Solicitar confirmação humana
- Feedback visual de progresso
- Ideal para primeira execução

---

## Processo

### 1. LOAD - Inicialização

Preparar ambiente de execução:

```yaml
1.1 Validar Blueprint
    - Ler BLUEPRINT.md completo
    - Verificar Gate G4: PASSED
    - Validar estrutura de arquivos
    - Confirmar checkpoint-map.yaml existe

1.2 Parsear Estrutura
    - Extrair epics, stories, tasks
    - Mapear dependências
    - Identificar stop hooks
    - Calcular estimativas

1.3 Inicializar .planning/
    - Criar estrutura no projeto-alvo
    - Gerar STATE.md inicial
    - Configurar observability
    - Preparar epic folders

1.4 Carregar Configuração
    - Ler ralph-config.yaml (se existe)
    - Aplicar CLI options
    - Resolver conflitos (CLI > config > defaults)
    - Validar configuração final
```

**Estrutura criada:**
```
projeto-alvo/
  .planning/
    STATE.md                    # Estado de execução
    CONTEXT.md                  # Contexto global
    ralph-config.yaml           # Configuração Ralph
    epics/
      E1-{slug}/
        CONTEXT.md              # Contexto do epic
        PLAN.md                 # Tasks em XML
        VERIFICATION.md         # Resultados
      E2-{slug}/
        ...
    logs/
      execution.log             # Log detalhado
      iterations.log            # Iterations por task
```

**Output esperado:**
```
════════════════════════════════════════════════════════════
ATHENA EXECUTION ENGINE v3.0
════════════════════════════════════════════════════════════

Blueprint: {nome}
ID: {BP-ID}
Path: {caminho}

Configuration:
  Mode: full
  Max iterations: 50
  Timeout: 2h
  Parallel tasks: enabled
  Auto-commit: enabled
  Stop hooks: enabled

Structure:
  Epics: 5
  Stories: 18
  Tasks: 67
  Estimated time: 4h 30min

.planning/ initialized ✓
STATE.md created ✓
Ready to execute.

Press [ENTER] to start or [Ctrl+C] to abort.
```

---

### 2. DISCUSS - Contextualização por Epic

Antes de executar cada epic, discutir e resolver gray areas:

```yaml
2.1 Carregar Epic
    - Ler objetivo e acceptance criteria
    - Identificar stories e tasks
    - Verificar dependências

2.2 Identificar Gray Areas
    - Analisar ambiguidades
    - Detectar decisões pendentes
    - Listar suposições implícitas
    - Marcar pontos de incerteza

2.3 Resolução
    - Tomar decisões de design
    - Documentar racionais
    - Explicitar suposições
    - Definir abordagem

2.4 Capturar em CONTEXT.md
    - Gravar decisões tomadas
    - Documentar gray areas resolvidas
    - Listar suposições
    - Incluir anti-patterns a evitar

2.5 Gate: Contexto Suficiente?
    - Todas decisões críticas tomadas?
    - Abordagem clara?
    - Riscos identificados?
    - Se NÃO: Iteração adicional
    - Se SIM: Prosseguir para PLAN
```

**Template CONTEXT.md:**
```markdown
# CONTEXT: {Epic ID} - {Epic Title}

## Objetivo
{objetivo detalhado do epic}

## Acceptance Criteria
- [ ] Critério 1
- [ ] Critério 2
- [ ] Critério 3

## Gray Areas Identificadas

### 1. {Área Ambígua}
**Questão:** {o que estava ambíguo}
**Decisão:** {decisão tomada}
**Racional:** {por que essa decisão}
**Alternativas consideradas:** {outras opções}

### 2. {Próxima área}
...

## Suposições
- {suposição 1}: {justificativa}
- {suposição 2}: {justificativa}

## Decisões de Design
| Decisão | Racional | Trade-offs |
|---------|----------|------------|
| {decisão} | {por que} | {o que foi sacrificado} |

## Anti-patterns a Evitar
- {anti-pattern 1}
- {anti-pattern 2}

## Riscos Identificados
| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| {risco} | MED | HIGH | {estratégia} |

## Abordagem Escolhida
{descrição da estratégia de implementação}
```

---

### 3. PLAN - Planejamento Detalhado

Gerar/validar XML tasks executáveis:

```yaml
3.1 Analisar Stories
    - Ler cada story do epic
    - Extrair requirements
    - Identificar acceptance criteria
    - Detectar dependências

3.2 Gerar XML Tasks
    SE checkpoint-map.yaml tem XML completo:
        - Validar contra requirements
        - Verificar completude
    SE NÃO:
        - Gerar XML tasks
        - Atomizar cada story em tasks
        - Definir <verify> commands
        - Especificar <done> criteria

3.3 Sequenciar
    - Ordenar tasks por dependência
    - Identificar tasks paralelas
    - Marcar checkpoints obrigatórios
    - Estimar duração

3.4 Output: PLAN.md
    - Listar todas tasks em XML
    - Mapear dependências visualmente
    - Documentar sequenciamento
    - Incluir stop hooks
```

**Formato XML Task:**
```xml
<task id="T-1.1.1" type="auto">
  <title>Configurar Tailwind CSS</title>
  <description>
    Instalar e configurar Tailwind no projeto Next.js.
    Configurar PostCSS, criar tailwind.config.js.
  </description>

  <files>
    tailwind.config.js
    postcss.config.js
    app/globals.css
  </files>

  <dependencies>
    <!-- Esta task não tem dependências -->
  </dependencies>

  <verify>npm run build</verify>

  <done>
    - tailwind.config.js criado com configuração correta
    - Build executando sem erros
    - Classes Tailwind disponíveis no projeto
  </done>

  <completion_promise>
    <indicators_required>2</indicators_required>
    <patterns>
      <pattern>build.*successful</pattern>
      <pattern>configuration.*complete</pattern>
      <pattern>no.*errors</pattern>
    </patterns>
    <explicit_signal_required>true</explicit_signal_required>
  </completion_promise>

  <estimated_duration>15min</estimated_duration>
</task>

<task id="T-1.1.2" type="auto">
  <title>Definir paleta de cores</title>
  <description>
    Criar paleta de cores void-chrome no tailwind.config.js
    conforme especificado no design system.
  </description>

  <files>
    tailwind.config.js
  </files>

  <dependencies>
    <depends_on>T-1.1.1</depends_on>
  </dependencies>

  <verify>
    npm run build &&
    grep -q "void.*chrome" tailwind.config.js
  </verify>

  <done>
    - 26 tons definidos (void-50 a void-950)
    - 26 tons chrome definidos
    - Cores acessíveis via classes (bg-void-700, text-chrome-200)
    - Build sem warnings
  </done>

  <completion_promise>
    <indicators_required>2</indicators_required>
    <explicit_signal_required>true</explicit_signal_required>
  </completion_promise>

  <estimated_duration>20min</estimated_duration>
</task>

<task id="T-1.2.1" type="checkpoint:human-verify">
  <title>Revisar design system</title>
  <description>
    Checkpoint humano para validar cores, tipografia
    e components antes de prosseguir com implementação.
  </description>

  <action>
    Apresentar preview do design system:
    - Paleta de cores renderizada
    - Tipografia samples
    - Spacing scale
    - Component examples
    Solicitar aprovação para prosseguir.
  </action>

  <stop_hook>
    type: human-verify
    prompt: "Design system está aprovado? [yes/no/modify]"
    on_approve: continue
    on_reject: return to T-1.1.1
    on_modify: incorporate feedback and re-verify
  </stop_hook>

  <done>Human approval received</done>
</task>
```

---

### 4. EXECUTE - Ralph Loop com Dual-Gate

Executar cada task usando Ralph Loop:

```yaml
4.1 Para cada task no PLAN:

    4.1.1 Spawn Executor Agent
        - Fresh context (200K tokens)
        - Carregar contexto mínimo:
          * Blueprint section relevante
          * Epic CONTEXT.md
          * Task XML completa
          * STATE.md atual
          * Arquivos listados em <files>

    4.1.2 Executar Task
        Loop (max iterations configurado):

            A. Processar task
               - Ler requirements
               - Implementar solução
               - Modificar arquivos

            B. Verificar
               SE <verify> existe:
                   - Executar comando
                   - Capturar output

            C. Check Completion (DUAL-GATE)

               GATE 1: Pattern Detection
                   - Scan output para indicators
                   - Mínimo: 2 indicators
                   - Verificar negative patterns

               GATE 2: Explicit Signal
                   - Procurar "EXIT_SIGNAL: true"
                   - Deve estar presente

               SE ambos PASS:
                   → Task COMPLETE
                   → Break loop

               SE algum FAIL:
                   → Continuar iteration
                   → Incrementar counter

            D. Circuit Breaker Check
               SE no_progress >= 3:
                   → TRIGGER: Escalate
               SE same_error >= 3:
                   → TRIGGER: Pivot approach
               SE token_usage > 90%:
                   → TRIGGER: Fresh context
               SE iterations >= max:
                   → TRIGGER: Pause

    4.1.3 Commit (se task completa)
        - git add [arquivos modificados]
        - git commit -m "Task {N}: {description}

          Co-Authored-By: Ralph Loop <ralph@athena-os.ai>"

    4.1.4 Gerar SUMMARY.md
        - O que foi feito
        - Arquivos modificados
        - Decisões tomadas
        - Iterations necessárias
        - Completion gate status
        - Commit hash

    4.1.5 Update STATE.md
        - Marcar task como COMPLETED
        - Incrementar tasks_completed
        - Atualizar timestamps
        - Log metrics
```

**Completion Indicators (padrão):**
```yaml
indicators:
  - "task.*complete"
  - "all.*tests.*pass"
  - "implementation.*complete"
  - "implementation.*done"
  - "verification.*successful"
  - "ready.*to.*proceed"
  - "requirements.*satisfied"
  - "acceptance.*criteria.*met"
  - "no.*errors"
  - "build.*successful"
```

**EXIT_SIGNAL format:**
```yaml
EXIT_SIGNAL: true
COMPLETION_REASON: "Tests passing (15/15), build successful, requirements satisfied"
```

**SUMMARY.md template:**
```markdown
# TASK SUMMARY: {task_id} - {title}

## Status
**COMPLETED** ✓

## O Que Foi Feito
{descrição detalhada da implementação}

## Arquivos Modificados
| Arquivo | Mudança |
|---------|---------|
| {path} | {descrição} |
| {path} | {descrição} |

## Decisões Tomadas
- **{decisão}**: {racional}
- **{decisão}**: {racional}

## Iterations
- **Iteration 1**: {o que foi tentado} → {resultado}
- **Iteration 2**: {o que foi tentado} → {resultado} (se aplicável)

## Verification
Command: `{verify_command}`
Result:
```
{output do comando}
```

## Completion Gate
**Gate 1 (Indicators):** PASS
- ✓ "all tests passing (15/15)"
- ✓ "implementation complete"
- ✓ "verification successful"

**Gate 2 (Exit Signal):** PASS
- ✓ EXIT_SIGNAL: true

## Commit
- **Hash:** {git_hash}
- **Message:**
  ```
  Task {N}: {description}

  Co-Authored-By: Ralph Loop <ralph@athena-os.ai>
  ```

## Metrics
- Iterations: {N}
- Time: {duration}
- Tokens used: {estimate}

---
*Generated by ATHENA Execution Engine v3.0*
```

---

### 5. VERIFY - Validação por Epic

Após completar todas tasks de um epic, verificar:

```yaml
5.1 Consolidar Tasks
    - Verificar: Todas tasks = COMPLETED?
    - Listar tasks completadas
    - Identificar blockers (se houver)

5.2 Executar Testes
    - Rodar test suite (se aplicável)
    - Executar build
    - Verificar linting
    - Rodar type checking

5.3 Validar Acceptance Criteria
    Para cada critério do epic:
        - Verificar se atendido
        - Documentar evidência
        - Marcar ✓ ou ✗

5.4 Human Checkpoint (se configurado)
    SE epic tem checkpoint:human-verify:
        - Apresentar resultados
        - Solicitar aprovação humana
        - Aguardar resposta
        - Processar feedback

5.5 Gerar VERIFICATION.md
    - Status de cada critério
    - Resultados de testes
    - Build status
    - Human feedback (se aplicável)
    - Status final: APPROVED | NEEDS_REVISION

5.6 Gate: Epic Completo?
    SE APPROVED:
        - Marcar epic como COMPLETED
        - Prosseguir para próximo epic
    SE NEEDS_REVISION:
        - Identificar task específica
        - Re-executar task
        - Re-verificar
```

**VERIFICATION.md template:**
```markdown
# EPIC VERIFICATION: {epic_id} - {epic_title}

## Status
**{APPROVED | NEEDS_REVISION}**

## Acceptance Criteria
| # | Critério | Status | Evidência |
|---|----------|--------|-----------|
| 1 | {critério} | ✓ | {link/screenshot/output} |
| 2 | {critério} | ✓ | {evidência} |
| 3 | {critério} | ✗ | {razão da falha} |

## Automated Tests
```bash
{comando de teste}
```

**Result:**
```
{output}
```

- Unit tests: {N/N} PASS ✓
- Integration tests: {N/N} PASS ✓
- E2E tests: {N/N} PASS ✓

## Build
```bash
{comando de build}
```

**Result:** {SUCCESS | FAILED}

## Type Checking
```bash
{comando typecheck}
```

**Result:** {PASS | FAIL}

## Human Checkpoint
{se aplicável}

**Reviewer:** {nome}
**Approved:** {yes/no}
**Comments:**
{feedback detalhado}

## Issues Found
{se houver}
- {issue 1}: {descrição}
- {issue 2}: {descrição}

## Next Steps
{se NEEDS_REVISION}
- Re-executar Task {N}
- Ajustar {X}
- Re-verificar

## Status Final
**{APPROVED | NEEDS_REVISION}**

{se APPROVED}
Epic completo. Prosseguir para {próximo epic}.

---
*Generated by ATHENA Execution Engine v3.0*
```

---

### 6. COMPLETE - Finalização

Após todos epics verificados:

```yaml
6.1 Verificar Completude
    - Todos epics = COMPLETED?
    - Todos acceptance criteria atendidos?
    - Todos checkpoints aprovados?
    - Build final funcionando?

6.2 Consolidar Resultados
    - Gerar relatório executivo
    - Agregar métricas
    - Listar deliverables
    - Capturar aprendizados

6.3 Trigger P6: LEARN
    SE P6 existe:
        - Executar protocolo de aprendizado
        - Capturar padrões
        - Atualizar pattern_library.yaml
        - Gerar lições aprendidas

6.4 Archive (opcional)
    - Compactar .planning/
    - Mover para archive/
    - Preservar logs
    - Limpar workspace

6.5 Update STATE.yaml
    - Marcar blueprint como COMPLETED
    - Atualizar métricas
    - Timestamp de conclusão
    - Transição para IDLE

6.6 Gerar EXECUTION-REPORT.md
    - Resumo executivo
    - Métricas finais
    - Padrões detectados
    - Próximos passos
```

**EXECUTION-REPORT.md template:**
```markdown
# EXECUTION REPORT: {blueprint_name}

## Overview
- **Blueprint ID:** {BP-ID}
- **Started:** {timestamp}
- **Completed:** {timestamp}
- **Duration:** {total_duration}
- **Status:** COMPLETED ✓

## Metrics

### Scope
- Epics: {N} completed
- Stories: {N} completed
- Tasks: {N} completed / {total}

### Performance
- Average time per task: {duration}
- Iterations per task (avg): {N}
- Circuit breaker triggers: {N}
- Stop hooks activated: {N}

### Quality
- First-time gate passes: {N}%
- Tests passing: 100%
- Build status: SUCCESS
- Type errors: 0

### Resources
- Tokens used (estimated): {N}
- Agents spawned: {N}
- Parallel tasks executed: {N}

## Epics Summary

### E1: {title}
- Tasks: {N}/{N} ✓
- Duration: {time}
- Status: APPROVED

### E2: {title}
- Tasks: {N}/{N} ✓
- Duration: {time}
- Status: APPROVED

{...}

## Deliverables
- [ ] {deliverable 1}
- [ ] {deliverable 2}
- [ ] {deliverable 3}

## Patterns Detected

### Success Patterns
- {pattern 1}: {descrição}
- {pattern 2}: {descrição}

### Anti-patterns Avoided
- {anti-pattern}: {como foi evitado}

### Blockers Encountered
- {blocker}: {como foi resolvido}

## Lessons Learned

### What Worked Well
- {lição 1}
- {lição 2}

### What Could Improve
- {melhoria 1}
- {melhoria 2}

### Recommendations for Next Blueprint
- {recomendação 1}
- {recomendação 2}

## Next Steps
{se aplicável}
- [ ] Deploy to staging
- [ ] Human testing
- [ ] Deploy to production

---
*Generated by ATHENA Execution Engine v3.0*
```

---

## Circuit Breakers

Proteção contra loops infinitos e desperdício de recursos.

### Triggers

| Trigger | Threshold | Action |
|---------|-----------|--------|
| **Loops sem progresso** | 3 iterations | Escalate to human |
| **Mesmo erro repetido** | 3 vezes | Pivot approach |
| **Token limit** | 90% usage | Fresh context ou escalate |
| **Max iterations** | 50 (configurável) | Pause e solicitar input |
| **Timeout** | 2h (configurável) | Save state e pause |

### Ações

**ESCALATE**
- Pausar execução
- Gerar emergency-report.md
- Apresentar contexto ao operador
- Aguardar guidance
- Retomar com nova abordagem

**PIVOT**
- Analisar falha repetida
- Mudar estratégia completamente
- Documentar tentativas anteriores
- Tentar abordagem alternativa

**FRESH CONTEXT**
- Salvar estado atual
- Limpar contexto
- Spawn novo agent
- Recarregar mínimo necessário
- Continuar execução

---

## Agentes Disponíveis

### Executor Agent
```yaml
role: "Implementador principal"
expertise: [código, configuração, integração]
use_for: "Maioria das tasks de implementação"
context_size: "200K tokens (fresh)"
```

### Reviewer Agent
```yaml
role: "Validador de qualidade"
expertise: [code review, best practices, anti-patterns]
use_for: "Verificação de epics, quality gates"
context_size: "100K tokens"
```

### Researcher Agent
```yaml
role: "Pesquisa profunda"
expertise: [documentação, APIs, libraries]
use_for: "Gray areas, decisões técnicas complexas"
context_size: "200K tokens"
```

### Debugger Agent
```yaml
role: "Diagnóstico de problemas"
expertise: [troubleshooting, root cause analysis, error recovery]
use_for: "Tasks que falharam 2+ vezes"
context_size: "150K tokens"
```

---

## Referências

- `@protocols/P5-EXECUTE.md` - Protocolo completo de execução
- `@knowledge/execution/RALPH-INTEGRATION.md` - Ralph Loop detalhado
- `@knowledge/execution/COMPLETION-GATES.md` - Sistema dual-gate
- `@knowledge/execution/CIRCUIT-BREAKER.md` - Proteção contra loops
- `@knowledge/orchestration/MULTI-AGENT-PATTERNS.md` - Padrões de delegação
- `@docs/architecture/10-EXECUTION.md` - Arquitetura do Execution Engine

---

## Instruções para ATHENA

Ao executar este comando:

### 1. Pré-execução

```yaml
1. Validar argumentos
   - Blueprint path existe?
   - BLUEPRINT.md presente?
   - checkpoint-map.yaml presente?
   - Gate G4 passou?

2. Parsear options
   - Resolver conflitos (CLI > config > defaults)
   - Validar valores
   - Gerar configuração final

3. Verificar projeto-alvo
   - Path acessível?
   - Git repository (se auto-commit)?
   - Dependencies instaladas?

4. Confirmar com operador
   - Mostrar configuração
   - Listar scope (epics, tasks)
   - Estimativa de tempo
   - Aguardar confirmação
```

### 2. Durante execução

```yaml
Loop principal:
  Para cada epic:
    1. DISCUSS
       - Carregar epic
       - Identificar gray areas
       - Resolver ambiguidades
       - Gerar CONTEXT.md

    2. PLAN
       - Gerar/validar XML tasks
       - Sequenciar
       - Gerar PLAN.md

    3. EXECUTE
       Para cada task:
         - Spawn executor agent
         - Ralph Loop com dual-gate
         - Verificar completion
         - Commit se completo
         - Gerar SUMMARY.md
         - Update STATE.md

    4. VERIFY
       - Consolidar tasks
       - Rodar testes
       - Validar acceptance criteria
       - Human checkpoint (se aplicável)
       - Gerar VERIFICATION.md

  5. COMPLETE
     - Verificar todos epics
     - Consolidar resultados
     - Trigger P6 (se existir)
     - Gerar EXECUTION-REPORT.md
     - Update STATE.yaml
```

### 3. Tratamento de erros

```yaml
SE Circuit Breaker triggered:
  - Pausar imediatamente
  - Gerar emergency-report.md
  - Salvar STATE atual
  - Apresentar opções ao operador
  - Aguardar decisão

SE Human checkpoint REJECTED:
  - Identificar task específica
  - Incorporar feedback
  - Re-executar task
  - Re-verificar

SE Task falha 3+ vezes:
  - Marcar como BLOCKED
  - Documentar tentativas
  - Solicitar guidance humana
  - Continuar com próxima task (se independente)
```

### 4. Observability

```yaml
Durante toda execução:
  - Log para observability/execution_log.yaml
  - Capturar métricas em tempo real
  - Detectar padrões
  - Identificar anti-patterns
  - Preparar dados para P6
```

### 5. Comunicação com operador

```yaml
Mostrar progresso:
  - Epic atual e progresso (X/Y)
  - Task atual
  - Iteration count
  - Tempo decorrido
  - ETA para conclusão

Pausar para input em:
  - Stop hooks (human-verify, decision)
  - Circuit breaker triggers
  - Epic verification fails
  - Completion

Fornecer controles:
  - /athena:progress - Ver status
  - /athena:cancel - Parada de emergência
  - /continue - Continuar após checkpoint
  - /skip-task {N} - Pular task
```

---

## Troubleshooting

### Task marca completa prematuramente

**Sintoma:** Task marcada como completa mas trabalho não finalizado

**Diagnóstico:**
- Indicators muito genéricos?
- EXIT_SIGNAL emitido por engano?
- Completion promise mal configurada?

**Solução:**
- Aumentar `indicators_required` para 3
- Adicionar `mandatory_indicators` específicos
- Usar patterns mais rigorosos
- Tornar `verify_command_required: true`

### Task nunca completa (loop infinito)

**Sintoma:** 8+ iterations sem exit

**Diagnóstico:**
- EXIT_SIGNAL não sendo emitido?
- Criteria muito vagos?
- Circuit breaker deveria ter ativado?

**Solução:**
- Reduzir `max_iterations` para 5
- Habilitar circuit breaker
- Revisar `<done>` criteria (mais específicos)
- Adicionar `<verify>` command executável

### Circuit breaker não ativa

**Sintoma:** Loop infinito sem proteção

**Diagnóstico:**
- Circuit breaker desabilitado?
- Thresholds muito altos?
- Progress não sendo detectado?

**Solução:**
- Verificar `--circuit-breaker=true`
- Reduzir thresholds (3 → 2)
- Melhorar detecção de progresso

---

## Critérios de Sucesso

Gate G5: A execução atingiu os critérios de sucesso?

### Checklist

- [ ] Todos epics executados (status: COMPLETED)
- [ ] Todos acceptance criteria atendidos
- [ ] Tests passando (100%)
- [ ] Build funcionando sem erros
- [ ] Type checking sem erros
- [ ] Checkpoints humanos aprovados
- [ ] STATE.md em COMPLETED
- [ ] Commits atômicos realizados (1 por task)
- [ ] VERIFICATION.md por epic gerado
- [ ] execution_log.yaml atualizado
- [ ] Deliverables conforme especificado

**Regra:** Todos os itens DEVEM estar ✓ para considerar G5 PASSED.

---

*ATHENA OS 3.0 — Execution Command*
*"Da arquitetura à realidade — precisão autônoma."*
