# P4: PROTOCOLO DE CRISTALIZACAO

> Transformar em artefatos prontos para exportar

**Versao:** 1.0.0
**Gate de Saida:** G4 - O Blueprint e auto-contido e transferivel?
**Referencia:** docs/architecture/02-PROTOCOLS.md

---

## Objetivo

Consolidar todos os outputs anteriores em artefatos finais, prontos para exportacao e execucao no projeto-alvo:
- Blueprint Operacional
- Activation Prompt
- Taxonomy Config
- Metadata

---

## Entrada

- Intent Specification (P1)
- Execution Architecture (P2)
- Checkpoint Map (P3)

---

## Saida

- `BLUEPRINT.md` - Documento mestre
- `ACTIVATION.md` - Prompt de ativacao
- `taxonomy-config.yaml` - Configuracao de outputs
- `_metadata.yaml` - Metadados do pacote
- Gate G4 PASSED

---

## Processo de Execucao

### Passo 4.1: Consolidacao de Artefatos

Reunir todos os outputs anteriores:

```yaml
artifacts_to_consolidate:
  - source: "outputs/intent-spec.yaml"
    target: "Blueprint secao 2"

  - source: "outputs/exec-arch.yaml"
    target: "Blueprint secao 3"

  - source: "outputs/checkpoint-map.yaml"
    target: "Blueprint secao 4"
```

### Passo 4.2: Geracao do BLUEPRINT.md

Criar documento mestre usando template:

**Estrutura:**

```markdown
# BLUEPRINT OPERACIONAL
# {TITULO DO PROJETO}

## 1. SUMARIO EXECUTIVO
   - 1.1 O Que E
   - 1.2 Por Que Existe (JTBD)
   - 1.3 Resultado Esperado
   - 1.4 Estimativas

## 2. INTENT SPECIFICATION
   - 2.1 Dimensoes
   - 2.2 Criterios de Sucesso

## 3. EXECUTION ARCHITECTURE
   - 3.1 Visao Geral (Diagrama)
   - 3.2 Fases
   - 3.3 Detalhamento das Fases
   - 3.4 Agentes

## 4. CHECKPOINT MAP
   - 4.1 Visao Geral
   - 4.2 Epicos Detalhados
   - 4.3 Checkpoints

## 5. TAXONOMY CONFIG
   - 5.1 Estrutura de Outputs
   - 5.2 Convencoes

## 6. GUIA DE EXECUCAO
   - 6.1 Pre-requisitos
   - 6.2 Primeiro Passo
   - 6.3 Fluxo de Execucao
   - 6.4 Pontos de Atencao

## 7. CRITERIOS DE SUCESSO FINAL

## ANEXOS
```

Ver template completo: `templates/blueprints/BLUEPRINT-TEMPLATE.md`

### Passo 4.3: Geracao do ACTIVATION.md

Criar prompt de ativacao:

**Estrutura:**

```markdown
# ACTIVATION PROMPT
# {TITULO}

## CONTEXTO
- Operador
- Projeto
- Blueprint ID
- Data

## BLUEPRINT
- Localizacao
- Acao Obrigatoria (ler primeiro)

## INSTRUCOES DE EXECUCAO
1. Preparacao
2. Iniciar Execucao
3. Durante Execucao
4. Finalizacao

## REGRAS INVIOLAVEIS
- NAO pular etapas
- NAO ignorar checkpoints
- SEMPRE atualizar STATE

## PRIMEIRO COMANDO
{comando inicial}

## EM CASO DE BLOQUEIO
{procedimento}
```

Ver template: `templates/prompts/ACTIVATION-TEMPLATE.md`

### Passo 4.4: Geracao do taxonomy-config.yaml

Definir onde cada output vai:

```yaml
# taxonomy-config.yaml

project_root: "{caminho/do/projeto}"

output_structure:
  primary_output:
    path: "{onde vai o output principal}"
    format: "md | yaml | json"
    naming: "{convencao}"

  secondary_outputs:
    - type: "{tipo}"
      path: "{caminho}"
      format: "{formato}"

  logs:
    path: "{caminho/logs}"

  temp:
    path: "{caminho/temp}"
    cleanup: true

naming_conventions:
  files: "{padrao}"
  folders: "{padrao}"
  timestamps: "YYYY-MM-DD"

state_file:
  path: "{caminho/STATE.yaml}"
  update_frequency: "on_checkpoint"
```

### Passo 4.5: Geracao do _metadata.yaml

Criar metadados do pacote:

```yaml
# _metadata.yaml

blueprint:
  id: "BP-{YYYY-MM-DD}-{NNN}"
  version: "1.0.0"
  created_at: "{ISO-8601}"
  created_by: "ATHENA OS v1.0"

source_artifacts:
  intent_spec: "INT-{id}"
  exec_arch: "ARCH-{id}"
  checkpoint_map: "CKPT-{id}"

artifacts:
  - file: "BLUEPRINT.md"
    type: "primary"
    size: "{bytes}"
    checksum: "{md5}"

  - file: "ACTIVATION.md"
    type: "activation"

  - file: "intent-spec.yaml"
    type: "specification"

  - file: "exec-arch.yaml"
    type: "architecture"

  - file: "checkpoint-map.yaml"
    type: "execution"

  - file: "taxonomy-config.yaml"
    type: "configuration"

validation:
  gates_passed: ["G1", "G2", "G3", "G4"]
  validated_at: "{ISO-8601}"

export_history: []
```

### Passo 4.6: Salvamento dos Arquivos

Salvar tudo na estrutura correta:

```
outputs/blueprints/{YYYY-MM-DD}/{slug}/
+-- BLUEPRINT.md
+-- ACTIVATION.md
+-- intent-spec.yaml
+-- exec-arch.yaml
+-- checkpoint-map.yaml
+-- taxonomy-config.yaml
+-- _metadata.yaml
```

---

## Gate G4: Validacao Final

**Pergunta Central:** O Blueprint e auto-contido e transferivel?

### Teste de Transferibilidade

> Se alguem que nunca viu este projeto ler apenas o Blueprint, consegue executar sem perguntas adicionais?

### Checklist de Validacao

| Criterio | Peso | Verificacao |
|----------|------|-------------|
| Blueprint completo? | CRITICO | Todas as 7 secoes preenchidas? |
| Activation funciona? | CRITICO | Instrucoes sao executaveis? |
| Taxonomy definida? | CRITICO | Outputs tem destino? |
| Sem referencias quebradas? | ALTO | Todos os links funcionam? |
| Linguagem clara? | ALTO | Sem jargao inexplicado? |
| JTBD claro? | ALTO | Qualquer um entende o objetivo? |
| Primeiro passo acionavel? | MEDIO | Pode comecar imediatamente? |

### Regra de Passagem

- Todos os criterios CRITICO devem ser atendidos
- Todos os criterios ALTO devem ser atendidos

### Se Falhar

1. Identificar quais criterios falharam
2. Revisar e completar secoes faltantes
3. Clarificar linguagem ambigua
4. Corrigir referencias quebradas
5. Re-executar Gate G4

---

## Verificacoes de Qualidade

### Verificacao 1: Completude

```yaml
completeness_check:
  blueprint:
    - secao_1_sumario: true
    - secao_2_intent: true
    - secao_3_arch: true
    - secao_4_checkpoints: true
    - secao_5_taxonomy: true
    - secao_6_guia: true
    - secao_7_criterios: true

  activation:
    - contexto: true
    - instrucoes: true
    - primeiro_comando: true
```

### Verificacao 2: Consistencia

```yaml
consistency_check:
  - "IDs no Blueprint = IDs nos YAMLs"
  - "Fases no Blueprint = Fases na Architecture"
  - "Tasks no Blueprint = Tasks no Checkpoint Map"
  - "Projeto-alvo consistente em todos os arquivos"
```

### Verificacao 3: Referencias

```yaml
reference_check:
  - "Todos os arquivos referenciados existem"
  - "Todos os paths sao validos"
  - "Todos os IDs resolvem"
```

---

## Output Final

### Resumo para o Operador

Apos G4 PASS, apresentar:

```
==================================================
BLUEPRINT GERADO COM SUCESSO
==================================================

ID: BP-2025-01-16-001
Titulo: {titulo}
Projeto-alvo: {projeto}

Arquivos gerados:
- outputs/blueprints/2025-01-16/{slug}/BLUEPRINT.md
- outputs/blueprints/2025-01-16/{slug}/ACTIVATION.md
- outputs/blueprints/2025-01-16/{slug}/*.yaml

Proximos passos:
1. Revisar BLUEPRINT.md
2. Executar /ATHENA:tasks:export-to-project {path}
3. Ou copiar arquivos manualmente

==================================================
```

---

## Checklist Final

Antes de finalizar:

- [ ] BLUEPRINT.md com todas as 7 secoes
- [ ] ACTIVATION.md com instrucoes claras
- [ ] taxonomy-config.yaml definido
- [ ] _metadata.yaml completo
- [ ] Arquivos salvos na estrutura correta
- [ ] Gate G4 PASSED
- [ ] STATE.yaml atualizado
- [ ] Resumo apresentado ao operador

---

*"Um Blueprint que nao pode ser executado por outro e um Blueprint que falhou." - ATHENA*
