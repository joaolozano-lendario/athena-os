# /ATHENA:tasks:analyze-codebase

> Analisa o codebase e gera intelligence para .planning/intel/

---

## Descrição

Escaneia o projeto para extrair exports, imports, convenções de nomenclatura, e dependências. Atualiza `.planning/intel/` com informações estruturadas para context injection.

---

## Uso

```
/ATHENA:tasks:analyze-codebase [path]
```

**path:** Diretório a escanear (default: projeto atual)

---

## Processo

1. **Scan:** Escanear arquivos do projeto
   - Incluir: src/, lib/, components/, etc
   - Excluir: node_modules/, .git/, dist/, build/

2. **Extract:** Para cada arquivo relevante
   - TypeScript/JavaScript: exports, imports
   - Python: imports, classes, functions
   - Markdown: headings, links

3. **Detect Patterns:**
   - Naming conventions (camelCase, snake_case, etc)
   - File organization patterns
   - Common prefixes/suffixes

4. **Map Dependencies:**
   - Internal imports (project files)
   - External imports (packages)

5. **Generate Summary:**
   - Human-readable overview
   - Key patterns detected
   - Dependency highlights

---

## Output

| Arquivo | Conteúdo |
|---------|----------|
| `.planning/intel/index.json` | Exports/imports por arquivo |
| `.planning/intel/conventions.json` | Padrões de nomenclatura |
| `.planning/intel/summary.md` | Resumo para context injection |

---

## Exemplo de Output

### index.json
```json
{
  "version": "1.0.0",
  "last_updated": "2026-01-20T14:00:00Z",
  "exports": {
    "src/utils/helpers.ts": ["formatDate", "parseJSON"],
    "src/components/Button.tsx": ["Button", "ButtonProps"]
  },
  "imports": {
    "src/components/Button.tsx": ["react", "../utils/helpers"]
  }
}
```

### conventions.json
```json
{
  "version": "1.0.0",
  "naming": {
    "components": "PascalCase",
    "utilities": "camelCase",
    "constants": "UPPER_SNAKE"
  },
  "patterns": [
    "Components in src/components/",
    "Utils in src/utils/",
    "Types alongside implementation"
  ]
}
```

---

## Referências

@knowledge/orchestration/CODEBASE-INTELLIGENCE.md
@.planning/intel/

---

*ATHENA OS 3.0 — Codebase Analysis*
