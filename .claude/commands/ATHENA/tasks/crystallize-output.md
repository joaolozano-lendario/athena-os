# /ATHENA:tasks:crystallize-output

> Fase P4: Cristalização de Output (execução isolada)

---

## Descrição

Executa apenas a Fase P4 do pipeline, consolidando todos os artefatos anteriores em um Blueprint Operacional completo e um Activation Prompt pronto para uso.

---

## Pré-requisitos

- Intent Specification (P1)
- Execution Architecture (P2)
- Checkpoint Map (P3)

---

## Fluxo

```
INPUT: Todos os artefatos anteriores
   │
   ▼
CONSOLIDAÇÃO
   └── Reunir intent, arch, checkpoints
   │
   ▼
GERAÇÃO DE BLUEPRINT.md
   ├── Sumário executivo
   ├── Intent Specification
   ├── Execution Architecture
   ├── Checkpoint Map
   ├── Taxonomy Config
   ├── Guia de Execução
   └── Critérios de Sucesso
   │
   ▼
GERAÇÃO DE ACTIVATION.md
   ├── Contexto
   ├── Referência ao Blueprint
   ├── Instruções de execução
   ├── Primeiro comando
   └── Regras
   │
   ▼
GERAÇÃO DE taxonomy-config.yaml
   └── Estrutura de outputs no projeto-alvo
   │
   ▼
GERAÇÃO DE _metadata.yaml
   └── Metadados do pacote
   │
   ▼
GATE G4: Pronto para exportar?
   │
   ├── PASS ──► Arquivos salvos
   └── FAIL ──► Refinar
```

---

## Critérios Gate G4

O Blueprint é aprovado quando:

1. ✓ Todas as seções do BLUEPRINT.md preenchidas
2. ✓ ACTIVATION.md tem instruções executáveis
3. ✓ Taxonomy definida
4. ✓ Sem referências quebradas
5. ✓ Linguagem clara, sem jargão inexplicado
6. ✓ **Teste de Transferibilidade:** Alguém sem contexto consegue executar lendo apenas o Blueprint

---

## Instruções para ATHENA

1. Carregar todos os artefatos anteriores
2. Processar usando protocolo `protocols/P4-CRYSTALLIZE.md`
3. Gerar BLUEPRINT.md usando template
4. Gerar ACTIVATION.md usando template
5. Gerar taxonomy-config.yaml
6. Gerar _metadata.yaml
7. Apresentar resumo dos artefatos
8. Solicitar validação final (Gate G4)
9. Se aprovado, salvar em:
   ```
   outputs/blueprints/{date}/{slug}/
   ├── BLUEPRINT.md
   ├── ACTIVATION.md
   ├── intent-spec.yaml
   ├── exec-arch.yaml
   ├── checkpoint-map.yaml
   ├── taxonomy-config.yaml
   └── _metadata.yaml
   ```

---

## Output

### BLUEPRINT.md
Documento mestre com 7 seções (ver template completo em `templates/blueprints/BLUEPRINT-TEMPLATE.md`)

### ACTIVATION.md
Prompt pronto para colar no projeto-alvo (ver template em `templates/prompts/ACTIVATION-TEMPLATE.md`)

### taxonomy-config.yaml
```yaml
project_root: ""
output_structure:
  primary_output:
    path: ""
    format: ""
  secondary_outputs: []
naming_conventions:
  files: ""
  folders: ""
```

### _metadata.yaml
```yaml
blueprint:
  id: "BP-{YYYY-MM-DD}-{NNN}"
  version: "1.0.0"
  created_at: ""
  created_by: "ATHENA OS v1.0"
  
artifacts:
  - file: "BLUEPRINT.md"
    type: "primary"
  - file: "ACTIVATION.md"
    type: "activation"
  # ...

export_history: []
```

---

*Comando do ATHENA OS v1.0.0*
