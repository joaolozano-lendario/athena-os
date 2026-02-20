# /athena:execute-quick

> Modo rápido - skip discuss/verify phases

---

## Descrição

Execução acelerada que bypassa fases interativas para máxima velocidade.

**Características:**
- Skip DISCUSS phase (sem confirmações)
- Skip VERIFY intermediário (apenas verificação final)
- Track em .planning/quick/
- Overhead mínimo

**ATENÇÃO:** Use apenas quando:
- Blueprint já foi validado/testado antes
- Projeto é de baixo risco
- Você tem backup (branch git limpo)
- Pode reverter facilmente se algo der errado

---

## Uso

```bash
/athena:execute-quick [options]
```

### Options

| Option | Descrição | Default |
|--------|-----------|---------|
| `--blueprint PATH` | Path do Blueprint | STATE.yaml → active_blueprint |
| `--max-iterations N` | Limite de iterações Ralph | 30 (reduzido vs 50) |
| `--timeout N` | Timeout em minutos | 15 |
| `--parallel-tasks` | Executar tasks independentes em paralelo | false |
| `--no-tests` | Skip testes finais | false |
| `--verbose` | Logging detalhado | false |

---

## Processo

### 1. LOAD (upfront)

```yaml
Ações:
  - LER: Blueprint completo
  - PARSEAR: Estrutura completa (épicos → tasks)
  - GERAR: Todas tasks XML upfront (não on-demand)
  - BUILD: Dependency graph
  - INIT: .planning/quick/
```

### 2. EXECUTE (sem interrupções)

```yaml
Serial Mode (default):
  Para cada épico:
    Para cada task:
      - Spawn executor
      - Execute (Ralph Loop)
      - Completion gate (simplificado)
      - Next task

Parallel Mode (--parallel-tasks):
  Para cada épico:
    - Identificar tasks independentes
    - Spawn N executors em paralelo
    - Respeitar dependencies
    - Aguardar completion de deps
    - Merge results

SKIPPED:
  - ✗ DISCUSS phases
  - ✗ VERIFY intermediário
  - ✗ Confirmações interativas
```

### 3. VERIFY (apenas final)

```yaml
Se --no-tests=false:
  - Rodar testes automatizados
  - Validar artifacts críticos
  - Log de issues encontradas
```

### 4. REPORT & LEARN

```yaml
Gerar:
  - Execution report
  - Trigger P6: LEARN
  - Archive para .planning/history/
```

---

## Diferenças vs /athena:execute

| Aspecto | Normal | Quick |
|---------|--------|-------|
| DISCUSS | Por épico | Skipped |
| VERIFY | Por épico | Apenas final |
| Confirmações | Interativas | Auto-yes |
| Tasks XML | Geradas on-demand | Todas upfront |
| Parallelização | Não | Opcional (--parallel-tasks) |
| Segurança | Alta | Média |
| Velocidade | Média | Alta |

---

## Completion Gate Simplificado

No modo quick, completion gate é **menos rigoroso**:

```yaml
completion_check:
  minimum_indicators: 1  # vs 2 no modo normal

  accepted_indicators:
    - EXIT_SIGNAL: true
    - Files created/modified
    - No errors in last loop

  skip:
    - Manual confirmation
    - Interactive verification
```

---

## Exemplo de Uso

```bash
# Quick execution básica (usa Blueprint ativo)
/athena:execute-quick

# Especificar Blueprint
/athena:execute-quick --blueprint outputs/blueprints/2026-01-20/simple-api/BLUEPRINT.md

# Com parallel tasks
/athena:execute-quick --parallel-tasks

# Skip testes finais (DANGER)
/athena:execute-quick --no-tests

# Verbose para ver o que está acontecendo
/athena:execute-quick --verbose
```

---

## Quando Usar

| Situação | Use Quick? |
|----------|------------|
| Blueprint bem testado anteriormente | ✓ Sim |
| Prototype/MVP rápido | ✓ Sim |
| Projeto crítico | ✗ Não |
| Blueprint novo/não validado | ✗ Não |
| Debugging | ✗ Não |
| Produção | ✗ Não (use normal) |
| Experimentação | ✓ Sim (com backup) |

---

## Safety Measures

Mesmo no modo quick:

```yaml
circuit_breaker:
  - Ativo (mesmos thresholds)
  - Para se detectar loops

git_safety:
  - Nunca push automático
  - Easy rollback

state_tracking:
  - .planning/STATE.md atualizado
  - Logs completos
  - Execution report
```

---

## Regras

- **NUNCA** usar em produção sem review
- **SEMPRE** ter backup/branch limpo
- **VALIDAR** Blueprint rigorosamente antes
- **MONITORAR** logs mesmo no quick mode
- **REVERTER** imediatamente se algo estranho

---

## Referências

- @knowledge/execution/RALPH-LOOP.md
- @knowledge/execution/COMPLETION-GATES.md
- @protocols/P5-EXECUTE.md

---

*ATHENA OS 3.0 - Execution Module*
*"Velocidade com segurança."*
