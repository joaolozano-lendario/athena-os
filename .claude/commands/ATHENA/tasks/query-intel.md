# /ATHENA:tasks:query-intel

> Consulta a inteligência do codebase

---

## Descrição

Consulta dados estruturados sobre o codebase gerados por `/ATHENA:tasks:analyze-codebase`.

---

## Uso

```
/ATHENA:tasks:query-intel <type>
```

---

## Types

| Type | Descrição |
|------|-----------|
| `exports` | Lista todos os exports do projeto |
| `imports` | Mostra grafo de imports |
| `conventions` | Mostra padrões de nomenclatura detectados |
| `summary` | Mostra resumo geral do codebase |
| `file <path>` | Mostra intel de arquivo específico |

---

## Exemplos

```bash
# Ver todos os exports
/ATHENA:tasks:query-intel exports

# Ver convenções de nomenclatura
/ATHENA:tasks:query-intel conventions

# Ver resumo do codebase
/ATHENA:tasks:query-intel summary

# Ver intel de arquivo específico
/ATHENA:tasks:query-intel file src/components/Button.tsx
```

---

## Pré-requisitos

- `.planning/intel/` deve existir
- Rodar `/ATHENA:tasks:analyze-codebase` primeiro se não existir

---

## Output Format

### exports
```
=== Exports do Projeto ===

src/utils/helpers.ts:
  - formatDate
  - parseJSON

src/components/Button.tsx:
  - Button
  - ButtonProps
```

### conventions
```
=== Convenções Detectadas ===

Naming:
  - Components: PascalCase
  - Utilities: camelCase
  - Constants: UPPER_SNAKE

Patterns:
  - Components em src/components/
  - Utils em src/utils/
```

---

## Referências

@.planning/intel/index.json
@.planning/intel/conventions.json
@.planning/intel/summary.md

---

*ATHENA OS 3.0 — Intel Query*
