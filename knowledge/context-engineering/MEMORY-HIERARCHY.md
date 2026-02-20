# MEMORY HIERARCHY — ATHENA OS 3.0

> **"O que Claude lembra determina o que Claude faz."**

---

## VISÃO GERAL

Claude Code carrega memória automaticamente no início de cada sessão através de uma hierarquia de arquivos. Entender essa hierarquia permite contexto preciso e eficiente.

---

## OS 4 NÍVEIS

```
┌─────────────────────────────────────────────────────────────────┐
│ NÍVEL 1: GLOBAL (~/.claude/CLAUDE.md)                           │
│ ├── Preferências pessoais do operador                          │
│ ├── Padrões que se aplicam a TODOS os projetos                 │
│ └── Version control: NÃO (pessoal)                             │
├─────────────────────────────────────────────────────────────────┤
│ NÍVEL 2: PROJECT (./CLAUDE.md)                                  │
│ ├── Contexto específico do projeto                             │
│ ├── Stack, comandos, convenções do time                        │
│ └── Version control: SIM (compartilhado)                       │
├─────────────────────────────────────────────────────────────────┤
│ NÍVEL 3: LOCAL (./CLAUDE.local.md)                              │
│ ├── Overrides pessoais para o projeto                          │
│ ├── Configurações que não devem ir para o repo                 │
│ └── Version control: NÃO (.gitignore)                          │
├─────────────────────────────────────────────────────────────────┤
│ NÍVEL 4: RULES (.claude/rules/*.md)                             │
│ ├── Regras condicionais por path                               │
│ ├── Carregam apenas quando arquivos matching estão ativos      │
│ └── Version control: SIM                                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## ORDEM DE CARREGAMENTO

```
1. ~/.claude/CLAUDE.md        (global, sempre)
2. ./CLAUDE.md                (project, sempre)
3. ./CLAUDE.local.md          (local, sempre)
4. .claude/rules/*.md         (condicional, por path)
```

**Override Rule:** Níveis mais específicos sobrescrevem mais genéricos.

---

## NÍVEL 1: GLOBAL

**Localização:** `~/.claude/CLAUDE.md`

**Conteúdo ideal:**
- Preferências de formatação
- Estilo de comunicação preferido
- Ferramentas favoritas
- Atalhos pessoais

**Exemplo:**
```markdown
# Global Preferences

## Communication
- Be concise, skip pleasantries
- Use code blocks liberally
- Prefer bullet points over paragraphs

## Tools
- Use Opus for complex reasoning
- Prefer Edit over Write for existing files
```

---

## NÍVEL 2: PROJECT

**Localização:** `./CLAUDE.md`

**Conteúdo ideal:**
- Stack tecnológico
- Comandos de build/test/lint
- Convenções de código
- Arquitetura overview
- Warnings importantes

**Exemplo:**
```markdown
# Project Context

## Stack
Next.js 15, TypeScript strict, pnpm, PostgreSQL

## Commands
- `pnpm build` - Build project
- `pnpm test` - Run tests
- `pnpm typecheck` - ALWAYS run after changes

## Conventions
- ES modules only
- Type annotations required
- Early returns preferred
```

---

## NÍVEL 3: LOCAL

**Localização:** `./CLAUDE.local.md`

**Conteúdo ideal:**
- API keys paths (não os keys em si!)
- Configurações de desenvolvimento local
- Overrides pessoais para o projeto

**Importante:** Adicionar ao `.gitignore`

---

## NÍVEL 4: RULES

**Localização:** `.claude/rules/*.md`

**Formato:**
```markdown
---
paths:
  - "src/api/**/*.ts"
  - "src/routes/**/*.ts"
---

# API Security Rules

- All endpoints must validate input
- Use standard error format
- Include OpenAPI comments
```

**Carregamento:** Apenas quando editando arquivos que match os paths.

---

## PROGRESSIVE LOADING

Usar `@filename` para carregar documentos sob demanda:

```markdown
# CLAUDE.md

## References
See @docs/architecture.md for system design
See @docs/api.md for API documentation
```

**Benefícios:**
- Não consome tokens upfront
- Claude carrega quando necessário
- Mantém CLAUDE.md lean

---

## BEST PRACTICES

### CLAUDE.md (Project)

**INCLUIR:**
- Comandos críticos (build, test, lint)
- Stack overview
- Convenções não-enforceadas por linters
- Decisões arquiteturais
- Warnings sobre comportamentos inesperados

**EXCLUIR:**
- Regras enforceáveis por linters (usar hooks)
- Instruções task-specific (usar slash commands)
- Informação sensível
- Exemplos de código longos
- Conselhos genéricos que Claude já sabe

### Tamanho

| Arquivo | Target |
|---------|--------|
| CLAUDE.md | < 300 linhas, < 3K tokens |
| Rules (each) | < 50 linhas |
| Total memory | < 5K tokens |

---

## HOOKS vs INSTRUCTIONS

**Hooks são determinísticos. Instruções são probabilísticas.**

| Necessidade | Usar |
|-------------|------|
| Formatação de código | Hook (Prettier/ESLint) |
| Estilo de variáveis | Instruction (CLAUDE.md) |
| Commit format | Hook (lint-staged) |
| Arquitetura decisions | Instruction |

**Exemplo de hook em settings.json:**
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "npx prettier --write $FILE_PATH"
      }]
    }]
  }
}
```

---

## ANTI-PATTERNS

### Giant Monolithic CLAUDE.md
**Problema:** 1000+ linhas, tudo misturado
**Solução:** Extrair para rules e @references

### Instructions for Lintable Rules
**Problema:** "Use 2-space indentation" no CLAUDE.md
**Solução:** Configurar Prettier + hook

### Stale Code Examples
**Problema:** Exemplos de código no CLAUDE.md ficam desatualizados
**Solução:** Usar @references para arquivos reais

### No Path-Conditional Rules
**Problema:** Mesmas regras para todos os arquivos
**Solução:** Usar .claude/rules/ com paths específicos

---

*ATHENA OS 3.0 — Memory Hierarchy*
*"Memória precisa para output preciso."*
