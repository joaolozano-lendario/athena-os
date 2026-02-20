# /ATHENA:tasks:compile-context

> Compilar payload de contexto otimizado para uma task específica

---

## Descrição

Gera um context payload otimizado aplicando a estratégia apropriada baseada na natureza da task. Seleciona template, estima token usage, e produz payload pronto para execução.

---

## Uso

```
/ATHENA:tasks:compile-context [mode] [task-description]
```

**mode:** Estratégia de contexto (quick/deep/creative)
**task-description:** Descrição da task que receberá o contexto

---

## Modes

| Mode | Use Case | Strategy | Token Estimate |
|------|----------|----------|----------------|
| `quick` | Tarefas simples, repetitivas | Zero-Shot | ~500-1000 |
| `deep` | Análises complexas, pesquisa | CoT + RAG | ~2000-3000 |
| `creative` | Ideação, brainstorming | Creative-Context | ~1500-2500 |
| `auto` | Detecção automática | Seleção inteligente | Variável |

---

## Processo

1. **Analyze Task**
   - Extrair keywords da task description
   - Detectar complexidade (simples/média/alta)
   - Identificar domínio (CODE/DATA/META/etc)

2. **Select Strategy**
   - Se mode = auto: aplicar heurísticas
   - Consultar `STRATEGY-SELECTOR.md` para regras
   - Considerar token budget atual

3. **Choose Template**
   - Buscar em `templates/context/payload-variants/`
   - Aplicar template apropriado
   - Personalizar para task específica

4. **Optimize Payload**
   - Remover redundâncias
   - Compactar referências
   - Estimar token usage final

5. **Output Payload**
   - Formato YAML estruturado
   - Ready para injection

---

## Output

```yaml
compiled_payload:
  metadata:
    strategy: "Few-Shot"
    template: "deep-context"
    token_estimate: 2500
    confidence: 0.85

  context:
    system_prompt: "..."
    examples:
      - input: "..."
        output: "..."
    references:
      - "@knowledge/orchestration/MANIFESTO.md"

  validation:
    budget_check: "PASS (65% usage)"
    completeness: "HIGH"
```

---

## Estratégias de Seleção

### Zero-Shot (quick)
**Quando usar:**
- Task é familiar e bem definida
- Não requer exemplos complexos
- Budget limitado

**Template:** `zero-shot-minimal.md`

### Few-Shot (deep)
**Quando usar:**
- Task requer exemplos para clareza
- Padrão específico deve ser seguido
- Medium token budget

**Template:** `few-shot-standard.md`

### Chain-of-Thought (deep)
**Quando usar:**
- Raciocínio complexo necessário
- Multi-step problem solving
- High token budget disponível

**Template:** `cot-reasoning.md`

### RAG-Enhanced (deep)
**Quando usar:**
- Task referencia conhecimento específico
- Documentação deve ser injetada
- Precision é crítica

**Template:** `rag-enhanced.md`

### Creative-Context (creative)
**Quando usar:**
- Ideação, brainstorming
- Múltiplas perspectivas necessárias
- Thinking outside box

**Template:** `creative-expansive.md`

---

## Exemplos Práticos

### Exemplo 1: Quick Mode
```
/ATHENA:tasks:compile-context quick "Criar função de validação de email"
```

**Output:**
```yaml
strategy: "Zero-Shot"
template: "zero-shot-minimal"
token_estimate: 750
context: |
  Criar função TypeScript que valide emails usando regex.
  Retornar boolean. Seguir convenções do projeto.
```

### Exemplo 2: Deep Mode
```
/ATHENA:tasks:compile-context deep "Analisar arquitetura e sugerir refactoring"
```

**Output:**
```yaml
strategy: "CoT + RAG"
template: "cot-reasoning"
token_estimate: 2800
context: |
  [System] Você é arquiteto de software especializado...
  [Examples] 3 exemplos de análise arquitetural...
  [References] @docs/architecture/*.md
  [Chain] 1. Scan → 2. Identify smells → 3. Suggest → 4. Validate
```

### Exemplo 3: Auto Mode
```
/ATHENA:tasks:compile-context auto "Escrever copy para landing page de SaaS B2B"
```

**Output:**
```yaml
strategy: "Creative-Context + Personas"
template: "creative-expansive"
token_estimate: 2200
context: |
  [Genius Layer] Nature: COPY
  [Dream Team] Schwartz, Hopkins, Ogilvy ativados
  [Lenses] Persuasion, Value Props, Social Proof
```

---

## Heurísticas de Seleção Automática

| Pattern | Strategy |
|---------|----------|
| "criar função", "implementar" | Zero-Shot |
| "analisar", "investigar", "pesquisar" | CoT + RAG |
| "escrever copy", "idear", "explorar" | Creative-Context |
| "refatorar codebase X" | RAG-Enhanced |
| "explicar conceito Y" | Few-Shot |

---

## Validação de Payload

Antes de output, verificar:
- [ ] Token estimate < 80% budget atual
- [ ] Referências existem e são válidas
- [ ] Template aplicado corretamente
- [ ] Strategy alinha com task complexity

Se validação falha:
1. Tentar strategy mais leve
2. Compactar referências
3. Sugerir delegation se ainda excede

---

## Referências

@knowledge/context-engineering/STRATEGY-SELECTOR.md
@knowledge/context-engineering/PAYLOAD-TEMPLATES.md
@templates/context/payload-variants/
@.claude/rules/context-budget.md

---

*ATHENA OS 3.0 — Context Engineering*
