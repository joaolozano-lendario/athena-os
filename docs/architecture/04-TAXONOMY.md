# ATHENA OS — TAXONOMIA E PADRÕES DE OUTPUT

> Sistema de Nomenclatura, Organização e Convenções

**Versão:** 1.0.0
**Princípio Regente:** P4 - Taxonomia Rígida

---

## Filosofia da Taxonomia

> "Criatividade na solução, rigidez na organização."

A taxonomia existe para eliminar duas fontes de entropia:

1. **Entropia de Localização** — "Onde está aquele arquivo?"
2. **Entropia de Nomenclatura** — "O que esse arquivo contém?"

Com taxonomia rígida, qualquer artefato pode ser localizado e compreendido sem contexto adicional.

---

## Sistema de Identificadores

### IDs de Artefatos

```
{TIPO}-{YYYY-MM-DD}-{NNN}
```

| Componente | Descrição | Exemplo |
|------------|-----------|---------|
| TIPO | Código do tipo de artefato | BP, INT, ARCH |
| YYYY-MM-DD | Data de criação | 2025-01-16 |
| NNN | Número sequencial do dia | 001, 002, 003 |

### Códigos de Tipo

| Código | Artefato |
|--------|----------|
| **BP** | Blueprint Operacional |
| **INT** | Intent Specification |
| **ARCH** | Execution Architecture |
| **CKPT** | Checkpoint Map |
| **ACT** | Activation Prompt |
| **TAX** | Taxonomy Config |

---

## Estrutura de Diretórios

### Outputs do ATHENA OS

```
athena-os/
└── outputs/
    └── blueprints/
        └── {YYYY-MM-DD}/
            └── {slug}/
                ├── BLUEPRINT.md           # Blueprint principal
                ├── ACTIVATION.md          # Prompt de ativação
                ├── intent-spec.yaml       # Intent Specification
                ├── exec-arch.yaml         # Execution Architecture
                ├── checkpoint-map.yaml    # Checkpoint Map
                ├── taxonomy-config.yaml   # Taxonomy Config
                └── _metadata.yaml         # Metadados do pacote
```

### Convenção de Slug

O `{slug}` é derivado do título do projeto:

```
Título: "Framework de Análise de Dados Tally"
Slug:   "framework-analise-dados-tally"

Regras:
- Lowercase
- Espaços → hífens
- Remove caracteres especiais
- Máximo 50 caracteres
```

---

## Convenções de Nomenclatura

### Arquivos

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Blueprint | `BLUEPRINT.md` | BLUEPRINT.md |
| Activation | `ACTIVATION.md` | ACTIVATION.md |
| YAML specs | `{tipo}-{desc}.yaml` | intent-spec.yaml |
| Prompts | `{agent}-prompt.md` | analyst-prompt.md |
| Logs | `{YYYY-MM-DD}-{tipo}.log` | 2025-01-16-execution.log |

### Pastas

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Por data | `{YYYY-MM-DD}/` | 2025-01-16/ |
| Por projeto | `{slug}/` | framework-analise-tally/ |
| Por tipo | `{tipo}s/` | blueprints/, prompts/ |

### Timestamps

**Padrão:** ISO-8601 com timezone

```
2025-01-16T14:30:00-03:00
```

### Status

| Status | Significado |
|--------|-------------|
| `TODO` | Não iniciado |
| `IN_PROGRESS` | Em execução |
| `BLOCKED` | Bloqueado |
| `DONE` | Concluído |
| `FAILED` | Falhou |
| `SKIPPED` | Pulado intencionalmente |

---

## Padrões de Documentação

### Headers de Arquivo YAML

```yaml
# ╔═══════════════════════════════════════════════════════════════════╗
# ║                         {TÍTULO}                                  ║
# ║                       {Subtítulo}                                 ║
# ╚═══════════════════════════════════════════════════════════════════╝

# Metadata obrigatória
metadata:
  id: "{ID}"
  version: "1.0.0"
  created_at: "{timestamp}"
  created_by: "{autor}"
  athena_version: "1.0.0"
```

### Headers de Arquivo Markdown

```markdown
# {TÍTULO}
# {Subtítulo se houver}

---

**ID:** {ID}
**Versão:** 1.0.0
**Gerado por:** ATHENA OS v1.0
**Data:** {YYYY-MM-DD HH:MM}

---
```

### Separadores de Seção

```yaml
# ─────────────────────────────────────────────────────────────────────
# NOME DA SEÇÃO
# ─────────────────────────────────────────────────────────────────────
```

---

## Estrutura no Projeto-Alvo

Quando um Blueprint é exportado para um projeto-alvo, a estrutura recomendada é:

```
{projeto-alvo}/
├── .athena/                          # Pasta ATHENA
│   ├── blueprints/                   # Blueprints ativos
│   │   └── {slug}/
│   │       ├── BLUEPRINT.md
│   │       ├── ACTIVATION.md
│   │       └── *.yaml
│   ├── history/                      # Blueprints concluídos
│   │   └── {YYYY-MM}/
│   │       └── {slug}/
│   └── state-log.yaml                # Log de estados
│
├── STATE.yaml                        # State principal (pode referenciar .athena/)
└── ... (resto do projeto)
```

---

## Referências Cruzadas

### Como Referenciar Arquivos

```yaml
# Referência absoluta (entre projetos)
reference:
  type: "absolute"
  path: "D:/athena-os/outputs/blueprints/2025-01-16/framework-tally/BLUEPRINT.md"

# Referência relativa (mesmo projeto)
reference:
  type: "relative"
  path: "./.athena/blueprints/framework-tally/BLUEPRINT.md"

# Referência por ID
reference:
  type: "id"
  id: "BP-2025-01-16-001"
  resolver: "athena-os"  # qual sistema resolve o ID
```

### Como Referenciar Seções

```yaml
# Referência a seção específica
reference:
  file: "BLUEPRINT.md"
  section: "4.2"  # Número da seção
  anchor: "checkpoint-map"  # ou anchor markdown
```

---

## Validação de Taxonomia

### Checklist de Conformidade

| Item | Verificação |
|------|-------------|
| ✓ | IDs seguem padrão `{TIPO}-{YYYY-MM-DD}-{NNN}`? |
| ✓ | Arquivos estão nas pastas corretas? |
| ✓ | Nomes de arquivo seguem convenção? |
| ✓ | Timestamps em ISO-8601? |
| ✓ | Headers de arquivo presentes? |
| ✓ | Metadados completos? |
| ✓ | Referências são resolvíveis? |

### Comando de Validação

```
/ATHENA:tasks:validate-taxonomy {path}
```

---

## Anti-Patterns de Taxonomia

| ❌ Anti-Pattern | ✅ Correto |
|-----------------|-----------|
| `documento.md` | `BLUEPRINT.md` |
| `pasta nova/` | `{YYYY-MM-DD}/` |
| `Final v2 FINAL.md` | Usar versionamento no metadata |
| Arquivos na raiz | Estrutura de pastas definida |
| IDs inventados | IDs com padrão definido |
| Timestamps locais | ISO-8601 com timezone |

---

## Migração de Outputs Existentes

Se você tem outputs existentes que não seguem a taxonomia:

### Passo 1: Inventário
```yaml
# Listar todos os arquivos fora do padrão
migration:
  files_to_migrate:
    - current: "analise.md"
      target: "outputs/blueprints/{data}/{slug}/BLUEPRINT.md"
```

### Passo 2: Renomeação
```bash
# Script sugerido de migração
# (executar manualmente ou adaptar)
```

### Passo 3: Atualização de Referências
```yaml
# Atualizar todas as referências para novos paths
```

---

## Extensibilidade

### Adicionando Novos Tipos

Para adicionar um novo tipo de artefato:

1. Definir código de 2-4 letras
2. Criar template em `templates/`
3. Documentar em `04-TAXONOMY.md`
4. Atualizar validadores

```yaml
# Exemplo: Novo tipo "Report"
new_type:
  code: "RPT"
  template: "templates/reports/REPORT-TEMPLATE.md"
  output_path: "outputs/reports/{date}/{slug}/"
```

---

*"Ordem é a primeira lei do céu." — Alexander Pope*
*"E a primeira lei de um bom sistema." — ATHENA*
