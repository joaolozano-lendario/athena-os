# GSD STRUCTURE

> **Get Shit Done** directory structure adapted for ATHENA OS | .planning/ pattern | STATE.md living memory

**Status:** OPERATIONAL
**Versão:** 2.0.0
**Owner:** Execution Engine

---

## VISÃO GERAL

GSD Structure é a organização de diretórios e arquivos que suporta execução iterativa no ATHENA OS.

**Princípio fundador:**
```
Todo projeto executável tem:
  - 1 diretório .planning/ (cérebro)
  - 1 arquivo STATE.md (memória viva)
  - N arquivos {epic}-N-PLAN.md (roteiros)
  - 1 diretório archive/ (histórico)
```

---

## ESTRUTURA DE DIRETÓRIOS

### Layout Completo

```
project-root/
│
├── .planning/                           # CÉREBRO DO PROJETO
│   ├── STATE.md                         # Memória viva (SSOT)
│   ├── ralph-config.yaml                # Configuração Ralph Loop
│   ├── execution-context.md             # Contexto permanente
│   │
│   ├── epic-1-user-auth-PLAN.md        # Plano Epic 1
│   ├── epic-2-dashboard-PLAN.md         # Plano Epic 2
│   ├── epic-3-notifications-PLAN.md     # Plano Epic 3
│   │
│   ├── quick/                           # Quick mode plans
│   │   ├── explore-api-PLAN.md
│   │   └── spike-redis-PLAN.md
│   │
│   └── archive/                         # Planos completados
│       ├── 2026-01-18/
│       │   └── epic-1-user-auth-PLAN.md
│       └── 2026-01-19/
│           └── epic-2-dashboard-PLAN.md
│
├── src/                                 # Código fonte
├── tests/                               # Testes
├── docs/                                # Documentação
└── ...                                  # Resto do projeto
```

### Hierarquia

```
┌─────────────────────────────────────────────────────────────────┐
│  PROJECT ROOT                                                    │
│  └── .planning/                    ← Planning brain             │
│      ├── STATE.md                  ← Single source of truth     │
│      ├── ralph-config.yaml         ← Execution configuration    │
│      ├── execution-context.md      ← Permanent context          │
│      │                                                           │
│      ├── {epic}-{N}-PLAN.md        ← Epic execution plans       │
│      │   ├── Metadata                                           │
│      │   ├── Context                                            │
│      │   ├── Stories                                            │
│      │   └── Tasks (XML)                                        │
│      │                                                           │
│      ├── quick/                    ← Exploratory work           │
│      │   └── {name}-PLAN.md                                     │
│      │                                                           │
│      └── archive/                  ← Completed plans            │
│          └── {date}/                                            │
│              └── {epic}-{N}-PLAN.md                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## ARQUIVOS PRINCIPAIS

### 1. STATE.md (Living Memory)

**Propósito:** Single Source of Truth do estado atual.

**Localização:** `.planning/STATE.md`

**Estrutura:**

```markdown
# PROJECT STATE

**Last Updated:** 2026-01-20T14:45:32Z
**Current Epic:** user-authentication (2/3)
**Current Story:** Backend implementation (5/8)
**Current Task:** Task 12 - JWT token validation
**Status:** IN_PROGRESS

---

## Active Work

### Epic: user-authentication (2/3)

**Story 2/3:** Backend implementation (5/8 tasks complete)

**Current Task:** 12/30
- Name: Implement JWT token validation
- Type: auto
- Started: 2026-01-20T14:30:00Z
- Iterations: 3
- Status: IN_PROGRESS

**Next Tasks:**
- Task 13: Add refresh token logic
- Task 14: Implement token revocation
- Task 15: Add rate limiting

---

## Completed Today

- [14:25] Task 11: Create JWT signing utility (2 iterations)
- [13:50] Task 10: Setup JWT secret configuration (1 iteration)
- [13:20] Task 9: Install jsonwebtoken package (1 iteration)

---

## Decisions Made

| When | Decision | Rationale | Impact |
|------|----------|-----------|--------|
| 2026-01-20 14:00 | Use RS256 instead of HS256 | Better security for microservices | Tasks 11-15 adapted |
| 2026-01-20 12:30 | PostgreSQL over MongoDB | Relational data model fits better | Epic 3 delayed |

---

## Blockers

| ID | Task | Blocker | Status | Owner |
|----|------|---------|--------|-------|
| B1 | 14 | Awaiting Redis setup | ACTIVE | DevOps |
| B2 | 20 | API design approval needed | PENDING | Product |

---

## Metrics (Current Epic)

| Metric | Value |
|--------|-------|
| Tasks completed | 11/30 |
| Iterations total | 47 |
| Avg iterations/task | 4.3 |
| Token usage | 145K / 200K |
| Time elapsed | 2h 15m |
| Estimated remaining | 3h 30m |

---

## Circuit Breaker Status

| Check | Status |
|-------|--------|
| Failed iterations | 0/3 |
| Same error count | 1/3 |
| Token threshold | 72.5% (OK) |
| Timeout status | OK (2h 15m / 8h) |

---

## Stop Hooks Upcoming

| Task | Type | Required | ETA |
|------|------|----------|-----|
| 15 | human-verify | Yes | +2 tasks |
| 20 | progress-review | No | +8 tasks |
| 25 | decision | Yes | +13 tasks |

---

## Context Files Currently Loaded

- .planning/STATE.md
- .planning/epic-2-user-auth-PLAN.md
- src/auth/jwt.ts
- tests/auth.test.ts
- docs/auth-architecture.md

---

## Notes

- RS256 requires key pair generation (added to task 13)
- Consider adding JWT debugging endpoint for dev (backlog)
- Tests running slow, investigate in next sprint
```

**Atualização:**
- A cada task completada
- A cada Stop Hook
- A cada decision gate
- A cada circuit breaker trigger
- A cada blocker identificado

**Regra de Ouro:** Se não está no STATE.md, não aconteceu.

---

### 2. {epic}-{N}-PLAN.md (Execution Plan)

**Propósito:** Roteiro detalhado para executar um Epic.

**Naming Convention:** `{epic-name}-{sequential-number}-PLAN.md`

**Exemplos:**
- `user-auth-1-PLAN.md`
- `dashboard-2-PLAN.md`
- `payment-integration-3-PLAN.md`

**Estrutura:**

```markdown
# PLAN: User Authentication

**Epic:** user-authentication
**Epic Number:** 2
**Status:** IN_PROGRESS
**Started:** 2026-01-20T10:00:00Z
**Estimated Duration:** 8h
**Blueprint Source:** outputs/blueprints/2026-01-20/user-auth-BLUEPRINT.md

---

## Context

### Project
Full-stack web app requiring user authentication for dashboard access.

### Epic Goal
Implement complete user authentication flow:
- Login/logout endpoints
- JWT-based session management
- Password hashing and validation
- Token refresh mechanism

### Dependencies
- Epic 1 (database setup) - COMPLETE
- PostgreSQL running locally
- Node.js 18+ installed

### Success Criteria
- Users can register, login, logout
- Tokens expire and refresh correctly
- All auth tests passing (50+ tests)
- Security audit passed

---

## Stories

### Story 1: Database Schema (Tasks 1-5)
- User table with credentials
- Session tracking table
- Indexes for performance

**Estimated:** 1h | **Actual:** 0h 45m | **Status:** COMPLETE

### Story 2: Backend Implementation (Tasks 6-15)
- JWT utilities
- Auth middleware
- Login/logout endpoints
- Token refresh logic

**Estimated:** 3h | **Actual:** 2h 15m | **Status:** IN_PROGRESS (Task 12/15)

### Story 3: Frontend Integration (Tasks 16-25)
- Login form component
- Auth context provider
- Protected routes
- Session management

**Estimated:** 3h | **Actual:** - | **Status:** NOT_STARTED

### Story 4: Testing & Security (Tasks 26-30)
- Unit tests
- Integration tests
- Security audit
- Performance optimization

**Estimated:** 1h | **Actual:** - | **Status:** NOT_STARTED

---

## Tasks

### Story 1: Database Schema

<task type="auto" id="1">
  <name>Task 1: Create users table migration</name>
  <story>Database Schema (1/3)</story>
  <files>migrations/001_create_users.sql</files>
  <action>
    Create migration file with users table:
    - id (UUID, primary key)
    - email (unique, not null)
    - password_hash (not null)
    - created_at, updated_at timestamps
  </action>
  <verify>
    psql -d myapp -c "\d users"
  </verify>
  <done>
    - Migration file created
    - Table structure matches spec
    - psql shows table with correct columns
  </done>
</task>

<task type="auto" id="2">
  <name>Task 2: Create sessions table migration</name>
  <story>Database Schema (1/3)</story>
  <files>migrations/002_create_sessions.sql</files>
  <action>
    Create sessions table:
    - id (UUID, primary key)
    - user_id (foreign key to users)
    - token_hash (indexed)
    - expires_at (timestamp)
    - created_at
  </action>
  <verify>
    psql -d myapp -c "\d sessions"
  </verify>
  <done>
    - Sessions table created
    - Foreign key constraint present
    - Index on token_hash exists
  </done>
</task>

<!-- Tasks 3-5 omitted for brevity -->

### Story 2: Backend Implementation

<task type="auto" id="6">
  <name>Task 6: Install auth dependencies</name>
  <story>Backend Implementation (2/3)</story>
  <files>package.json</files>
  <action>
    Install:
    - jsonwebtoken
    - bcryptjs
    - @types for both
  </action>
  <verify>
    npm list jsonwebtoken bcryptjs
  </verify>
  <done>
    - Packages in package.json
    - npm list shows versions
    - node_modules populated
  </done>
</task>

<!-- Tasks 7-14 omitted -->

<task type="checkpoint:human-verify" id="15">
  <name>Task 15: Review authentication architecture</name>
  <story>Backend Implementation (2/3)</story>
  <context>
    Before proceeding to frontend, validate backend auth design
  </context>
  <files>src/auth/*, tests/auth.test.ts, docs/auth-flow.md</files>
  <action>
    - Generate architecture diagram
    - Document auth flow
    - List security measures implemented
    - Show test coverage report
    - Await human approval
  </action>
  <stop_hook>
    type: human-verify
    prompt: "Auth backend ready for frontend integration? [approve/modify/reject]"
    on_approve: continue to Story 3
    on_modify: incorporate feedback and re-verify
    on_reject: return to task 10 for redesign
  </stop_hook>
  <done>
    - Architecture documented
    - Human approval received
    - Feedback incorporated if any
  </done>
</task>

<!-- Story 3 & 4 tasks omitted -->

---

## Stop Hooks Configured

| Task | Type | Reason | Required | ETA |
|------|------|--------|----------|-----|
| 15 | human-verify | Auth architecture approval | Yes | Story 2 end |
| 20 | decision | Choose frontend auth library | Yes | Mid Story 3 |
| 30 | progress-review | Pre-deployment checklist | Yes | Epic end |

---

## Metrics

### Estimates vs Actuals

| Story | Estimated | Actual | Variance |
|-------|-----------|--------|----------|
| 1 | 1h | 0h 45m | -25% |
| 2 | 3h | 2h 15m (in progress) | On track |
| 3 | 3h | - | - |
| 4 | 1h | - | - |

### Task Completion

| Metric | Value |
|--------|-------|
| Total tasks | 30 |
| Completed | 11 |
| In progress | 1 (Task 12) |
| Blocked | 0 |
| Not started | 18 |

---

## Notes

- Using RS256 for JWT (decision made task 11)
- Redis setup delayed, using in-memory for dev
- Consider rate limiting in next epic
```

---

### 3. ralph-config.yaml (Execution Configuration)

**Propósito:** Configuração de execução para Ralph Loop.

**Localização:** `.planning/ralph-config.yaml`

**Estrutura:**

```yaml
# Ralph Loop Configuration
version: 2.0.0
project: user-authentication-app

execution:
  mode: full                    # full | quick | guided
  max_iterations: 50
  timeout: 28800                # 8h in seconds
  auto_commit: true
  fresh_context: true

stop_hooks:
  enabled: true
  notify_via: console           # console | slack | webhook
  default_action: pause         # pause | continue | escalate
  timeout_action: continue      # Auto-continue após timeout

  webhook_config:               # Se notify_via: webhook
    url: https://hooks.slack.com/services/XXX
    on_stop: true
    on_complete: true
    on_error: true

completion:
  dual_gate: true
  indicators_required: 2
  explicit_signal_required: true
  verify_command_required: true

circuit_breaker:
  enabled: true
  max_failed_iterations: 3
  max_same_error: 3
  token_threshold: 0.90         # 90% de 200K
  time_threshold: 0.90          # 90% do timeout

context:
  fresh_context_pattern: true
  max_context_files: 10
  state_always_loaded: true
  include_patterns:
    - "*.md"
    - "src/**/*.ts"
    - "tests/**/*.test.ts"
  exclude_patterns:
    - "node_modules/**"
    - "dist/**"
    - ".git/**"

commits:
  auto_commit: true
  atomic: true                  # 1 task = 1 commit
  format: "Task {N}: {description}"
  co_author: "Ralph Loop <ralph@athena-os.ai>"
  sign_commits: false
  verify_before_commit: true    # Rodar <verify> antes de commit

logging:
  level: info                   # debug | info | warn | error
  output: observability/execution_log.yaml
  real_time: true
  include_metrics: true

quality_gates:
  enforce_tests: true           # <verify> deve passar
  enforce_coverage: false       # Verificar coverage threshold
  coverage_threshold: 80
  enforce_lint: false           # Rodar linter antes de commit
```

---

### 4. execution-context.md (Permanent Context)

**Propósito:** Contexto que deve ser carregado em TODAS as iterações.

**Localização:** `.planning/execution-context.md`

**Estrutura:**

```markdown
# Execution Context

**Project:** User Authentication App
**Tech Stack:** Node.js, TypeScript, PostgreSQL, React
**Started:** 2026-01-18

---

## Project Structure

```
src/
├── auth/          # Authentication logic
├── db/            # Database client and migrations
├── api/           # API routes
└── utils/         # Shared utilities

tests/
├── unit/          # Unit tests
└── integration/   # Integration tests
```

---

## Key Decisions

1. **JWT Strategy:** RS256 (not HS256)
   - Rationale: Better for microservices
   - Impact: Need public/private key pair

2. **Database:** PostgreSQL (not MongoDB)
   - Rationale: Relational model fits auth data
   - Impact: Use SQL migrations

3. **Password Hashing:** bcrypt with 10 rounds
   - Rationale: Industry standard
   - Impact: ~100ms per hash (acceptable)

---

## Environment

```bash
# Required environment variables
DATABASE_URL=postgresql://localhost:5432/myapp
JWT_PRIVATE_KEY_PATH=./keys/jwt-private.pem
JWT_PUBLIC_KEY_PATH=./keys/jwt-public.pem
JWT_EXPIRY=1h
REFRESH_TOKEN_EXPIRY=7d
```

---

## Commands Reference

```bash
# Run tests
npm test

# Run specific test file
npm test -- auth.test.ts

# Database migrations
npm run migrate:up
npm run migrate:down

# Lint
npm run lint

# Type check
npm run typecheck

# Build
npm run build
```

---

## Code Conventions

- Use TypeScript strict mode
- All functions must have return types
- Use async/await (not .then())
- Error handling: try/catch with typed errors
- File naming: kebab-case
- Function naming: camelCase
- Class naming: PascalCase

---

## Testing Standards

- Unit tests: Jest
- Coverage target: 80%+
- Integration tests: Supertest
- Test naming: "should {expected behavior} when {condition}"

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| express | ^4.18 | Web framework |
| typescript | ^5.0 | Type safety |
| jsonwebtoken | ^9.0 | JWT handling |
| bcryptjs | ^2.4 | Password hashing |
| pg | ^8.11 | PostgreSQL client |

---

## Patterns to Follow

### Error Handling

```typescript
class AuthError extends Error {
  constructor(public code: string, message: string) {
    super(message);
  }
}

// Usage
throw new AuthError('INVALID_TOKEN', 'Token expired');
```

### Async Route Handlers

```typescript
const asyncHandler = (fn: RequestHandler) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

// Usage
router.post('/login', asyncHandler(async (req, res) => {
  // ...
}));
```

---

## Anti-Patterns to Avoid

- ❌ Storing passwords in plain text
- ❌ Using any type
- ❌ Silent error swallowing
- ❌ Hardcoded secrets
- ❌ Synchronous crypto operations
```

---

## QUICK MODE

**Propósito:** Execuções exploratórias, spikes, experimentos.

**Localização:** `.planning/quick/`

**Características:**
- Plans mais simples
- Menos checkpoints
- Menos tasks fragmentadas
- Objetivo: aprender rápido

**Exemplo: `.planning/quick/explore-redis-PLAN.md`**

```markdown
# QUICK PLAN: Explore Redis for Caching

**Type:** Spike / Exploration
**Duration:** 30-60 min
**Goal:** Avaliar se Redis é viável para caching

---

## Tasks

<task type="auto" id="1">
  <name>Install and run Redis locally</name>
  <action>
    - Install Redis via docker
    - Start container
    - Verify connection
  </action>
  <verify>redis-cli ping</verify>
  <done>PONG response received</done>
</task>

<task type="auto" id="2">
  <name>Create simple cache wrapper</name>
  <action>
    - Install ioredis
    - Create CacheService class
    - Implement get/set/del
  </action>
  <verify>npm test -- cache.test.ts</verify>
  <done>Tests passing</done>
</task>

<task type="auto" id="3">
  <name>Benchmark cache performance</name>
  <action>
    - Write benchmark script
    - Test 1000 get/set operations
    - Compare with in-memory
  </action>
  <verify>node benchmark.js</verify>
  <done>Results logged, decision documented</done>
</task>

---

## Decision Criteria

- [ ] Redis faster than in-memory for this use case?
- [ ] Setup complexity acceptable?
- [ ] Worth the operational overhead?

**Recommendation:** [To be filled after execution]
```

---

## ARCHIVE STRUCTURE

**Propósito:** Histórico de plans executados.

**Localização:** `.planning/archive/{date}/`

**Organização:**

```
.planning/archive/
├── 2026-01-18/
│   ├── database-setup-1-PLAN.md
│   └── execution-report-2026-01-18.md
│
├── 2026-01-19/
│   ├── user-auth-2-PLAN.md
│   └── execution-report-2026-01-19.md
│
└── 2026-01-20/
    ├── dashboard-3-PLAN.md
    └── execution-report-2026-01-20.md
```

**Execution Report Template:**

```markdown
# Execution Report: 2026-01-20

**Epic:** user-authentication
**Plan:** user-auth-2-PLAN.md
**Status:** COMPLETE
**Duration:** 6h 32m
**Efficiency:** 82% (6.5h estimated, 6.5h actual)

---

## Summary

Completed user authentication Epic 2:
- 30/30 tasks executed
- 3 Stop Hooks processed
- 0 circuit breakers triggered
- 127 iterations total
- 4.23 avg iterations/task

---

## Stories Completed

1. Database Schema (5 tasks) - 45m
2. Backend Implementation (10 tasks) - 3h 15m
3. Frontend Integration (10 tasks) - 2h 10m
4. Testing & Security (5 tasks) - 22m

---

## Metrics

| Metric | Value |
|--------|-------|
| Total tasks | 30 |
| Tasks/hour | 4.6 |
| Avg iterations/task | 4.23 |
| Token usage | 172K / 200K (86%) |
| Commits | 30 (atomic) |
| Tests added | 52 |
| Coverage | 89% |

---

## Decisions Made

1. RS256 over HS256 (task 11)
2. React Context over Redux (task 18)
3. Skip rate limiting for MVP (task 25)

---

## Blockers Encountered

| Blocker | Task | Resolution | Delay |
|---------|------|------------|-------|
| Redis not available | 14 | Used in-memory for dev | 15m |
| API design approval | 15 | Received in 1h | 1h |

---

## Learnings

- JWT RS256 setup more complex than expected (add to next Blueprint)
- Frontend auth context pattern worked well (template created)
- bcrypt 10 rounds acceptable perf (document in standards)

---

## Patterns Discovered

**Positive:**
- Task structure for auth endpoints (reusable)
- Test setup pattern (add to template library)

**Negative:**
- Tasks 6-8 could have been merged (too granular)
- Stop Hook at task 20 unnecessary (remove pattern)

---

## Next Epic

**Epic 3:** Dashboard implementation
**Estimated:** 10h
**Dependencies:** Epic 2 complete ✓
**Start:** 2026-01-21
```

---

## FILE NAMING CONVENTIONS

```yaml
Plans:
  Format: "{epic-name}-{N}-PLAN.md"
  Examples:
    - user-auth-1-PLAN.md
    - dashboard-2-PLAN.md
    - payment-integration-3-PLAN.md

Quick Plans:
  Format: "{purpose}-PLAN.md"
  Location: .planning/quick/
  Examples:
    - explore-redis-PLAN.md
    - spike-graphql-PLAN.md
    - test-deployment-PLAN.md

Reports:
  Format: "execution-report-{YYYY-MM-DD}.md"
  Location: .planning/archive/{date}/
  Examples:
    - execution-report-2026-01-20.md

Config:
  - ralph-config.yaml
  - execution-context.md
  - STATE.md
```

---

## INTEGRAÇÃO COM BLUEPRINT

### Blueprint → GSD Structure Mapping

```yaml
ATHENA Blueprint (output):
  outputs/blueprints/2026-01-20/user-auth-BLUEPRINT.md

Transformação para GSD:
  1. Criar .planning/ no projeto-alvo
  2. Gerar {epic}-N-PLAN.md para cada Epic do Blueprint
  3. Converter Stories/Tasks para XML format
  4. Configurar Stop Hooks baseado em checkpoints do Blueprint
  5. Gerar ralph-config.yaml com defaults
  6. Criar execution-context.md com project info
  7. Inicializar STATE.md vazio

Ralph Loop:
  Ler .planning/{epic}-N-PLAN.md
  Começar execução
  Atualizar STATE.md em tempo real
```

---

## WORKFLOWS COMUNS

### 1. Iniciar novo Epic

```bash
# 1. Blueprint já existe
# outputs/blueprints/2026-01-20/dashboard-BLUEPRINT.md

# 2. Converter para GSD structure
/convert-blueprint-to-gsd \
  outputs/blueprints/2026-01-20/dashboard-BLUEPRINT.md \
  --target=./project/

# 3. Ralph Loop cria:
# ./project/.planning/dashboard-3-PLAN.md
# ./project/.planning/STATE.md (se não existe)
# ./project/.planning/ralph-config.yaml (se não existe)
```

### 2. Retomar Epic em progresso

```bash
# 1. Ler STATE.md
cat .planning/STATE.md

# 2. Ver task atual
# Current Task: 12/30 - JWT validation

# 3. Continuar execução
/continue-execution
```

### 3. Quick exploration

```bash
# 1. Criar quick plan
/create-quick-plan "Explore GraphQL integration"

# 2. Ralph gera:
# .planning/quick/explore-graphql-PLAN.md

# 3. Executar em quick mode
/execute-blueprint .planning/quick/explore-graphql-PLAN.md \
  --mode=quick \
  --max-iterations=10
```

---

## FILOSOFIA GSD

```
.planning/ é o cérebro
STATE.md é a memória
{epic}-N-PLAN.md são os roteiros
Ralph Loop é o executor

Juntos formam um sistema onde:
  - Todo progresso é rastreado
  - Nada é perdido entre sessões
  - Qualquer executor pode continuar
  - Decisões são documentadas
  - Aprendizado é capturado
```

**GSD não é apenas "fazer rápido".**
**É fazer com estrutura que permite velocidade sustentável.**

---

*GSD Structure v2.0.0*
*"Structure enables speed. Chaos only feels fast."*
