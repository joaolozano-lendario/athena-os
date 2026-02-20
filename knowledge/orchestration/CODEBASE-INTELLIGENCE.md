# CODEBASE INTELLIGENCE — ATHENA OS 2.0

> **"Conhecer a codebase é pré-requisito para orquestração efetiva. Inteligência precede ação."**

---

## FILOSOFIA

Antes de orquestrar agents para implementar, ATHENA precisa **conhecer profundamente** a codebase-alvo.

Codebase Intelligence é o sistema que mapeia, analisa, e mantém conhecimento sobre projetos onde Blueprints serão executados.

---

## OS 3 PILARES

```
┌─────────────────────────────────────────────────────┐
│         CODEBASE INTELLIGENCE SYSTEM                 │
├─────────────────────────────────────────────────────┤
│                                                      │
│  1. STRUCTURAL MAPPING                               │
│     └─► Arquitetura, pastas, padrões                │
│                                                      │
│  2. PATTERN DISCOVERY                                │
│     └─► Convenções, idioms, estilos                 │
│                                                      │
│  3. DEPENDENCY GRAPH                                 │
│     └─► Relações, imports, acoplamento              │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## PILAR 1: STRUCTURAL MAPPING

### Objetivo
Mapear a estrutura física e lógica da codebase.

### O Que Mapear

```yaml
Physical Structure:
  - Folder hierarchy
  - File organization
  - Module boundaries
  - Entry points

Logical Structure:
  - Application layers
  - Component architecture
  - Data flow
  - Integration points

Technology Stack:
  - Frameworks (React, Next.js, etc)
  - Languages (TypeScript, Python, etc)
  - Tools (Tailwind, Jest, etc)
  - Build system
```

### Como Mapear

**Phase 1: Quick Scan**
```bash
# Ver estrutura de pastas
ls -R

# Encontrar package.json ou equivalente
Glob: "**/package.json"

# Identificar linguagens
Glob: "**/*.ts", "**/*.tsx", "**/*.py", etc
```

**Phase 2: Deep Dive**
```bash
# Ler configurações
Read: package.json, tsconfig.json, tailwind.config.ts

# Mapear entry points
Read: src/app/layout.tsx, src/index.ts, main.py

# Identificar padrões de organização
Grep: "export default", "export const", "export function"
```

### Output: Structural Map

```markdown
# STRUCTURAL MAP: {project-name}

## Technology Stack
- Framework: Next.js 14
- Language: TypeScript
- Styling: Tailwind CSS
- State: React Context

## Folder Structure
```
src/
├── app/              # Next.js App Router
├── components/       # UI components
│   ├── ui/          # Primitives
│   ├── layout/      # Layout components
│   └── terminal/    # Domain components
├── hooks/           # Custom hooks
├── lib/             # Utilities
└── types/           # TypeScript types
```

## Entry Points
- Main: src/app/layout.tsx
- Pages: src/app/**/page.tsx
- API: src/app/api/**/route.ts

## Key Patterns
- Component naming: PascalCase
- File naming: kebab-case
- Export style: named exports preferred
```

---

## PILAR 2: PATTERN DISCOVERY

### Objetivo
Descobrir convenções, idioms, e estilos da codebase.

### O Que Descobrir

```yaml
Code Patterns:
  - Component structure
  - Function naming
  - Import organization
  - Error handling style

Style Conventions:
  - Formatting (prettier config)
  - Linting (eslint config)
  - TypeScript strictness
  - Comment style

Architecture Patterns:
  - Component composition
  - State management
  - Data fetching
  - Routing conventions
```

### Como Descobrir

**Technique 1: Exemplar Analysis**
Encontrar os melhores exemplos de cada tipo de artefato.

```bash
# Encontrar componente exemplar
Grep: "export.*function.*Component" --output_mode: files_with_matches
Read: {top 3 most complex components}

# Analisar padrão de imports
Grep: "^import" --output_mode: content -C: 0
→ Descobrir se usa alias (@/), paths relativos, etc

# Analisar padrão de types
Read: src/types/*.ts
→ Descobrir convenções de typing
```

**Technique 2: Frequency Analysis**
Identificar padrões mais comuns.

```bash
# Qual pattern de export é mais usado?
Grep: "export default" --output_mode: count
Grep: "export const" --output_mode: count
Grep: "export function" --output_mode: count

# Qual style de component?
Grep: "function.*Component" --output_mode: count
Grep: "const.*:.*FC" --output_mode: count
Grep: "class.*Component" --output_mode: count
```

**Technique 3: Config Analysis**
Ler configurações para entender standards.

```bash
Read: .eslintrc.json, .prettierrc, tsconfig.json
→ Identificar rules, strictness, preferences
```

### Output: Pattern Library

```markdown
# PATTERN LIBRARY: {project-name}

## Component Pattern
```typescript
// Standard component structure
interface ComponentProps {
  // Props definition
}

export function ComponentName({ prop1, prop2 }: ComponentProps) {
  // Hooks first
  const [state, setState] = useState();

  // Event handlers
  const handleEvent = () => {};

  // Render
  return <div>...</div>;
}
```

## Import Organization
```typescript
// 1. External libraries
import { useState } from 'react';

// 2. Internal absolute (@/ alias)
import { Component } from '@/components/ui';

// 3. Relative imports
import { helper } from './helpers';
```

## Naming Conventions
- Components: PascalCase
- Functions: camelCase
- Constants: UPPER_SNAKE_CASE
- Files: kebab-case.tsx
- Types: PascalCase with descriptive suffix (UserProfile, ButtonProps)

## TypeScript Style
- Strict mode enabled
- Explicit return types on public functions
- Interface for props, type for unions
- No any (use unknown if needed)
```

---

## PILAR 3: DEPENDENCY GRAPH

### Objetivo
Mapear relações entre módulos, identificar acoplamento, encontrar pontos de integração.

### O Que Mapear

```yaml
Module Dependencies:
  - What imports what
  - Circular dependencies
  - Depth of dependency chains

Integration Points:
  - External APIs
  - Third-party libraries
  - Shared utilities
  - Global state

Coupling Analysis:
  - Highly coupled modules
  - God objects/modules
  - Isolated islands
```

### Como Mapear

**Technique 1: Import Analysis**
```bash
# Encontrar todos imports
Grep: "^import.*from ['\"](.*)['\"]; --output_mode: content

# Identificar módulos mais importados
Grep: "from '@/components/ui'" --output_mode: count
Grep: "from '@/lib/utils'" --output_mode: count

# Detectar circular dependencies
Read: {module A}
→ Se A importa B, ler B
→ Se B importa A, circular detectado
```

**Technique 2: Usage Analysis**
```bash
# Quem usa Component X?
Grep: "import.*ComponentX" --output_mode: files_with_matches

# Quem usa function Y?
Grep: "import.*functionY|functionY\(" --output_mode: files_with_matches
```

**Technique 3: Shared Resource Analysis**
```bash
# Identificar utilities compartilhadas
Glob: "src/lib/**/*.ts"
Read: {cada utility}
Grep: "import.*from.*lib/utils" --output_mode: count

# Identificar global state
Grep: "createContext|Context.Provider" --output_mode: files_with_matches
```

### Output: Dependency Map

```markdown
# DEPENDENCY MAP: {project-name}

## Core Dependencies
### Most Imported Modules
1. @/components/ui/trigger (32 imports)
2. @/lib/utils (28 imports)
3. @/hooks/use-typing-effect (15 imports)

## Integration Points
### Global State
- PortalProvider (app/layout.tsx)
  └─► Used by: all pages

### Shared Utilities
- cn() from lib/utils
  └─► Used by: all components

### External APIs
- None (static site)

## Coupling Analysis
### High Coupling
- components/ui/* → lib/utils (tight)
- pages/* → components/terminal/* (medium)

### Isolated Modules
- hooks/* (low coupling, good)
- components/feedback/* (isolated, good)

## Circular Dependencies
- None detected ✓

## Recommendations
- Consider splitting lib/utils (too many responsibilities)
- Good isolation of hooks
- Clean component boundaries
```

---

## INTEGRATION WORKFLOW

### When to Gather Intelligence

**Before P1 (DECODE):**
- Quick scan of target project
- Identify tech stack
- Understand basic structure

**Before P2 (ARCHITECT):**
- Deep structural mapping
- Pattern discovery
- Dependency analysis

**Before Execution:**
- Verify patterns still valid
- Update if project evolved
- Confirm integration points

### Intelligence Storage

```yaml
Location: {project}/.athena/intelligence/

Files:
  - structural-map.md
  - pattern-library.md
  - dependency-map.md
  - last-updated.yaml
```

### Intelligence Updates

```yaml
Triggers:
  - New Blueprint for project
  - Major refactor detected
  - New patterns observed

Process:
  1. Run automated scans
  2. Compare with stored intelligence
  3. Update if significant changes
  4. Version intelligence files
```

---

## AUTOMATED INTELLIGENCE GATHERING

### Slash Command: `/ATHENA:tasks:scan-codebase`

**Purpose:** Automated intelligence gathering for target project

**Input:**
```yaml
project_path: "D:/target-project"
depth: "quick" | "deep" | "comprehensive"
```

**Output:**
```yaml
intelligence:
  structural_map: {path}
  pattern_library: {path}
  dependency_map: {path}
  confidence: 0.85
```

**Process:**
```
1. STRUCTURAL MAPPING
   └─► Glob + Read key files

2. PATTERN DISCOVERY
   └─► Grep analysis + Exemplar reading

3. DEPENDENCY GRAPH
   └─► Import analysis + Usage tracking

4. SYNTHESIS
   └─► Generate intelligence files

5. VALIDATION
   └─► Confidence scoring
```

---

## INTELLIGENCE-DRIVEN ORCHESTRATION

### How Intelligence Informs Orchestration

**Example 1: Component Implementation**
```yaml
Intelligence Says:
  - Component pattern: functional with hooks
  - File naming: kebab-case.tsx
  - Export style: named exports
  - Imports: @/ alias for absolute paths

Orchestration Decision:
  - Brief executor with exact pattern
  - Reference exemplar component
  - Specify naming convention
  - Auto-configure imports
```

**Example 2: Multi-Epic Execution**
```yaml
Intelligence Says:
  - Dependency: pages depend on components/ui
  - Integration point: lib/utils is shared
  - Coupling: terminal/* is isolated

Orchestration Decision:
  - Epic 1: Create lib/utils first (dependency)
  - Epic 2-4: Parallel (components/ui, terminal, hooks)
  - Epic 5: Pages last (depends on all)
  - Coordinator: Monitor lib/utils conflicts
```

**Example 3: Quality Gates**
```yaml
Intelligence Says:
  - TypeScript: strict mode
  - Testing: Jest with >80% coverage
  - Linting: ESLint with Airbnb rules

Orchestration Decision:
  - Executor: Run `npm run typecheck` after each file
  - Reviewer: Check test coverage in review
  - Quality gate: Lint must pass before merge
```

---

## INTELLIGENCE QUALITY METRICS

### Confidence Scoring

```yaml
Structural Map Confidence:
  - All key files read: +0.3
  - Package.json analyzed: +0.2
  - Folder structure complete: +0.2
  - Entry points identified: +0.3

Pattern Library Confidence:
  - 5+ exemplars analyzed: +0.3
  - Config files read: +0.2
  - Frequency analysis done: +0.3
  - Validated with human: +0.2

Dependency Map Confidence:
  - Import analysis complete: +0.3
  - Circular deps checked: +0.2
  - Coupling scored: +0.3
  - Integration points mapped: +0.2
```

**Minimum Confidence:** 0.7 to proceed with orchestration

---

## ANTI-PATTERNS

### 1. No Intelligence Gathering
**Problema:** Orquestrar sem conhecer codebase
**Resultado:** Agents criam código incompatível
**Solução:** Sempre gather intelligence antes de P2

### 2. Stale Intelligence
**Problema:** Usar intelligence de 6 meses atrás
**Resultado:** Padrões não batem com realidade atual
**Solução:** Re-scan antes de cada Blueprint

### 3. Surface-Level Scan
**Problema:** Apenas ler package.json
**Resultado:** Perder convenções críticas
**Solução:** Deep dive em exemplars

### 4. Ignore Config Files
**Problema:** Não ler .eslintrc, tsconfig
**Resultado:** Violação de rules
**Solução:** Config files são fonte de verdade

### 5. No Dependency Analysis
**Problema:** Não mapear imports
**Resultado:** Ordens de execução erradas, conflitos
**Solução:** Dependency graph é obrigatório

---

## CHECKLIST PRÉ-ORCHESTRAÇÃO

Antes de orquestrar execução de Blueprint:

- [ ] Structural map completo
- [ ] Pattern library com exemplars
- [ ] Dependency map gerado
- [ ] Integration points identificados
- [ ] Tech stack confirmado
- [ ] Confidence > 0.7
- [ ] Intelligence versionada
- [ ] Agents briefados com intelligence

---

*ATHENA OS 2.0 — Codebase Intelligence*
*"Conhecimento da codebase é a base de orquestração efetiva."*
