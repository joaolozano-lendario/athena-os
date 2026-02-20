# XML TASK FORMAT

> **Formato padrão de tasks** para ATHENA Execution Engine | Estruturado, verificável, transferível

**Status:** OPERATIONAL
**Versão:** 2.0.0
**Owner:** Execution Engine

---

## VISÃO GERAL

Tasks no ATHENA OS são definidas em XML estruturado que permite:
- Parsing automático por Ralph Loop
- Verificação objetiva de completion
- Transferência entre executores
- Rastreabilidade completa

**Princípio:** Uma task bem definida não deixa dúvidas sobre o que fazer.

---

## ESTRUTURA BASE

### Task Mínima

```xml
<task type="auto" id="1">
  <name>Task 1: {Action-oriented name}</name>
  <files>path/to/relevant/files</files>
  <action>What to do and what to avoid</action>
  <verify>Command to prove completion</verify>
  <done>Measurable acceptance criteria</done>
</task>
```

### Task Completa

```xml
<task type="auto" id="5">
  <name>Task 5: Implement user authentication endpoint</name>
  <story>Backend Implementation (2/3)</story>
  <files>src/auth/login.ts, tests/auth.test.ts</files>
  <dependencies>
    <task>4</task>  <!-- Task 4 must be complete -->
  </dependencies>
  <context>
    Users need to authenticate with email/password to access dashboard.
    Using JWT tokens with RS256 signing.
  </context>
  <action>
    Implement POST /auth/login endpoint:
    - Accept email and password in request body
    - Validate credentials against database
    - Generate JWT token on success
    - Return 401 on invalid credentials
    - Add rate limiting (5 attempts per minute)

    AVOID:
    - Storing password in plain text
    - Using weak hashing (use bcrypt with 10 rounds)
    - Returning detailed error messages (security)
  </action>
  <verify>
    npm test -- auth.test.ts
    curl -X POST localhost:3000/auth/login -d '{"email":"test@test.com","password":"test123"}'
  </verify>
  <done>
    - POST /auth/login endpoint responds
    - Valid credentials return JWT token
    - Invalid credentials return 401
    - All tests passing (15/15)
    - Rate limiting active (tested)
  </done>
  <estimate>45m</estimate>
  <tags>auth, critical, security</tags>
</task>
```

---

## TIPOS DE TASKS

### 1. Auto Task (type="auto")

**Propósito:** Execução autônoma sem pausa.

**Quando usar:**
- Implementação de código
- Escrita de testes
- Configuração de arquivos
- Instalação de dependências

**Exemplo:**

```xml
<task type="auto" id="3">
  <name>Task 3: Install authentication dependencies</name>
  <files>package.json, package-lock.json</files>
  <action>
    Install via npm:
    - jsonwebtoken ^9.0.0
    - bcryptjs ^2.4.3
    - @types/jsonwebtoken
    - @types/bcryptjs
  </action>
  <verify>
    npm list jsonwebtoken bcryptjs
  </verify>
  <done>
    - Packages in package.json dependencies
    - npm list shows installed versions
    - TypeScript types available
  </done>
</task>
```

**Completion:** Dual-gate system (indicators + EXIT_SIGNAL).

---

### 2. Human Verification Checkpoint (type="checkpoint:human-verify")

**Propósito:** Validação humana de trabalho completado.

**Quando usar:**
- Revisão de design crítico
- Aprovação de arquitetura
- Validação de UX
- Verificação de segurança

**Exemplo:**

```xml
<task type="checkpoint:human-verify" id="10">
  <name>Task 10: Review API endpoint design</name>
  <story>Backend Implementation (2/3)</story>
  <context>
    Before implementing frontend integration, validate that API design
    meets requirements and follows best practices.
  </context>
  <files>docs/api-specification.md, examples/api-examples.json</files>
  <action>
    Present API design for review:
    - Generate OpenAPI specification
    - Provide request/response examples for all endpoints
    - Document authentication flow
    - List security measures
    - Show error handling approach
    - Await human approval
  </action>
  <stop_hook>
    type: human-verify
    prompt: |
      API design review complete. Options:
      [approve] - API design approved, continue to frontend
      [modify] - Feedback provided, incorporate and re-verify
      [reject] - Significant issues, return to task 7 for redesign
    on_approve: continue to task 11
    on_modify:
      - Incorporate feedback
      - Update documentation
      - Re-run this verification
    on_reject: return to task 7
    timeout: 24h
    timeout_action: escalate
  </stop_hook>
  <done>
    - OpenAPI spec generated
    - Examples provided and clear
    - Human approval received
    - Feedback incorporated (if any)
    - Documentation updated
  </done>
</task>
```

**Completion:** Requires explicit human approval.

---

### 3. Decision Gate (type="checkpoint:decision")

**Propósito:** Escolha entre múltiplas opções que afetam execução futura.

**Quando usar:**
- Escolha de tecnologia
- Trade-offs arquiteturais
- Bifurcações de implementação
- Priorização de features

**Exemplo:**

```xml
<task type="checkpoint:decision" id="15">
  <name>Task 15: Choose caching strategy</name>
  <story>Performance Optimization (3/3)</story>
  <context>
    Application needs caching. Two viable options with different trade-offs.
  </context>
  <files>docs/caching-analysis.md, benchmarks/cache-comparison.md</files>
  <action>
    Analyze and present caching options:

    OPTION A: Redis
    - Pros: Distributed, persistent, feature-rich
    - Cons: Operational overhead, network latency, cost
    - Use case: Multi-server deployment, shared sessions

    OPTION B: In-Memory (node-cache)
    - Pros: Zero latency, simple setup, no infra
    - Cons: Not shared across servers, lost on restart
    - Use case: Single server, ephemeral data

    OPTION C: Hybrid
    - Pros: Best of both worlds
    - Cons: Complexity, cache coherence challenges
    - Use case: Critical data in Redis, ephemeral in-memory

    Provide recommendation based on:
    - Current deployment (single server)
    - Growth plans (multi-server in 6 months)
    - Budget constraints
    - Team expertise
  </action>
  <stop_hook>
    type: decision
    options:
      redis:
        description: "Use Redis for all caching"
        next_tasks: [16, 17, 18]  # Redis setup tasks
        estimate_impact: "+3h (setup), +$50/mo (hosting)"

      in_memory:
        description: "Use in-memory caching"
        next_tasks: [19, 20]  # In-memory implementation
        estimate_impact: "+30m (setup), $0 (hosting)"

      hybrid:
        description: "Hybrid approach (Redis + in-memory)"
        next_tasks: [16, 17, 18, 19, 20, 21]  # Both + orchestration
        estimate_impact: "+4h (setup), +$50/mo (hosting)"

    recommendation: in_memory
    recommendation_rationale: |
      Current single-server deployment doesn't need Redis complexity.
      Can migrate to Redis when scaling to multi-server.
      In-memory sufficient for MVP.

    timeout: 12h
    timeout_action: use_recommendation
  </stop_hook>
  <done>
    - All options analyzed and documented
    - Benchmarks run and compared
    - Recommendation provided with rationale
    - Decision made and documented
    - Next tasks adjusted accordingly
  </done>
</task>
```

**Completion:** Requires explicit decision selection.

---

### 4. Progress Review (type="checkpoint:review")

**Propósito:** Checkpoint de progresso sem decisão específica.

**Quando usar:**
- Fim de Story
- Fim de Epic
- Milestones de tempo (ex: fim de dia)
- Antes de deployments

**Exemplo:**

```xml
<task type="checkpoint:review" id="20">
  <name>Task 20: Mid-Epic progress review</name>
  <story>N/A (Review)</story>
  <context>
    10/20 tasks complete. Checkpoint before continuing to ensure on track.
  </context>
  <action>
    Generate progress report:

    COMPLETED (Tasks 1-10):
    - List each task with verification status
    - Show test coverage metrics
    - List commits made
    - Time spent vs estimated

    METRICS:
    - Tasks completed: 10/20
    - Stories completed: 1/3
    - Time elapsed vs estimated
    - Token usage
    - Iterations per task average
    - Circuit breaker triggers (if any)

    BLOCKERS:
    - List any blockers encountered
    - Document workarounds applied

    LEARNINGS:
    - Patterns discovered
    - Anti-patterns identified
    - Adjustments needed

    RECOMMENDATION:
    - Continue as planned?
    - Adjust plan?
    - Escalate issues?
  </action>
  <stop_hook>
    type: progress-review
    show_metrics: true
    allow_plan_adjustment: true
    continue_options:
      - "continue: Proceed to task 11 as planned"
      - "adjust: Modify remaining tasks based on learnings"
      - "pause: Stop for deeper review before continuing"
    default: continue
  </stop_hook>
  <done>
    - Progress report generated
    - Metrics calculated and presented
    - Human acknowledgment received
    - Plan adjusted if needed
  </done>
</task>
```

**Completion:** Requires human acknowledgment.

---

## ELEMENTOS DO XML

### Elementos Obrigatórios

| Elemento | Propósito | Exemplo |
|----------|-----------|---------|
| `type` | Tipo de task | `auto`, `checkpoint:human-verify`, `checkpoint:decision`, `checkpoint:review` |
| `id` | Identificador único | `1`, `2`, `3` (sequencial) |
| `<name>` | Nome action-oriented | `Task 5: Implement login endpoint` |
| `<action>` | O que fazer | `Create POST /login endpoint with JWT...` |
| `<verify>` | Como verificar completion | `npm test -- auth.test.ts` |
| `<done>` | Critérios de aceitação | `- Tests passing (15/15)\n- Endpoint responds` |

### Elementos Opcionais

| Elemento | Propósito | Quando usar |
|----------|-----------|-------------|
| `<story>` | Story a que pertence | Sempre que task faz parte de Story |
| `<files>` | Arquivos relevantes | Para fresh context pattern |
| `<context>` | Contexto adicional | Quando ação precisa explicação |
| `<dependencies>` | Tasks que devem vir antes | Quando há dependências explícitas |
| `<estimate>` | Tempo estimado | Para tracking de eficiência |
| `<tags>` | Tags de categorização | Para filtering e analytics |
| `<stop_hook>` | Configuração de pausa | Apenas em checkpoints |
| `<completion_promise>` | Config de completion | Para tasks complexas |

---

## PADRÕES POR CENÁRIO

### Scenario 1: Implementação de Feature

```xml
<task type="auto" id="8">
  <name>Task 8: Implement password reset flow</name>
  <story>User Management (1/3)</story>
  <files>
    src/auth/password-reset.ts,
    src/email/templates/reset-password.html,
    tests/password-reset.test.ts
  </files>
  <dependencies>
    <task>7</task>  <!-- Email service must exist -->
  </dependencies>
  <action>
    Implement password reset:
    1. POST /auth/reset-request endpoint
       - Accept email
       - Generate reset token (UUID)
       - Store token with expiry (1h) in DB
       - Send reset email with link

    2. POST /auth/reset-password endpoint
       - Accept token + new password
       - Validate token (exists, not expired)
       - Hash new password (bcrypt, 10 rounds)
       - Update user password
       - Invalidate token

    3. Create email template
       - Clear reset link
       - Security warnings
       - Expiry notice

    AVOID:
    - Revealing if email exists (security)
    - Using predictable tokens
    - Allowing token reuse
  </action>
  <verify>
    npm test -- password-reset.test.ts
    # Manual test:
    # curl -X POST localhost:3000/auth/reset-request -d '{"email":"test@test.com"}'
    # Check email received
    # Use token to reset password
  </verify>
  <done>
    - Both endpoints respond correctly
    - Token generated and stored with expiry
    - Email sent with correct link
    - Password updated on valid token
    - Token invalidated after use
    - Expired tokens rejected
    - All tests passing (20/20)
  </done>
  <estimate>60m</estimate>
  <tags>auth, security, email</tags>
</task>
```

---

### Scenario 2: Configuração de Infraestrutura

```xml
<task type="auto" id="2">
  <name>Task 2: Setup PostgreSQL database</name>
  <story>Infrastructure (1/3)</story>
  <files>
    docker-compose.yml,
    .env.example,
    scripts/init-db.sh
  </files>
  <action>
    Setup local PostgreSQL:
    1. Add postgres service to docker-compose.yml
       - Image: postgres:15-alpine
       - Port: 5432
       - Environment: POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD
       - Volume for persistence

    2. Create .env.example with database config
       - DATABASE_URL template
       - Connection pool settings

    3. Create init-db.sh script
       - Create database if not exists
       - Run initial migrations (if any)
       - Create test database

    4. Start and verify
       - docker-compose up -d postgres
       - Wait for healthy status
       - Test connection
  </action>
  <verify>
    docker-compose ps | grep postgres | grep "healthy"
    psql $DATABASE_URL -c "SELECT 1"
  </verify>
  <done>
    - docker-compose.yml has postgres service
    - Container starts successfully
    - Health check passing
    - Can connect via psql
    - .env.example documented
    - init-db.sh script works
  </done>
  <estimate>20m</estimate>
  <tags>infra, database, docker</tags>
</task>
```

---

### Scenario 3: Escrita de Testes

```xml
<task type="auto" id="12">
  <name>Task 12: Write integration tests for auth flow</name>
  <story>Testing (4/4)</story>
  <files>
    tests/integration/auth.integration.test.ts,
    tests/helpers/test-db.ts,
    tests/fixtures/users.ts
  </files>
  <dependencies>
    <task>6</task>  <!-- Login endpoint -->
    <task>8</task>  <!-- Password reset -->
    <task>10</task> <!-- Token refresh -->
  </dependencies>
  <action>
    Write integration tests covering full auth flow:

    1. Setup test helpers
       - Test database creation/cleanup
       - Test user fixtures
       - API client wrapper

    2. Test scenarios:
       a. Successful registration → login → access protected route
       b. Login with wrong password → 401
       c. Login → wait for expiry → 401 → refresh token → success
       d. Password reset request → use token → login with new password
       e. Rate limiting on login (6th attempt fails)
       f. Token revocation → access fails

    3. Each test should:
       - Start with clean database
       - Create necessary fixtures
       - Test full flow end-to-end
       - Verify HTTP status codes
       - Verify response bodies
       - Clean up after

    AVOID:
    - Tests that depend on each other
    - Shared state between tests
    - Incomplete cleanup
  </action>
  <verify>
    npm test -- auth.integration.test.ts
  </verify>
  <done>
    - 6 integration tests written
    - All tests passing (6/6)
    - Test coverage for auth module > 90%
    - Tests run in isolation
    - Cleanup working (no orphan data)
  </done>
  <estimate>90m</estimate>
  <tags>testing, integration, auth</tags>
</task>
```

---

### Scenario 4: Refactoring

```xml
<task type="auto" id="18">
  <name>Task 18: Refactor auth middleware for reusability</name>
  <story>Code Quality (3/3)</story>
  <files>
    src/auth/middleware.ts,
    src/auth/types.ts,
    tests/middleware.test.ts
  </files>
  <context>
    Current auth middleware is duplicated across routes.
    Extract to reusable middleware with options.
  </context>
  <action>
    Refactor middleware:

    1. Extract to src/auth/middleware.ts:
       - requireAuth() - Basic JWT validation
       - requireAuth({roles: ['admin']}) - Role-based
       - requireAuth({permissions: ['write:users']}) - Permission-based
       - optionalAuth() - Attach user if token present, don't fail

    2. Create TypeScript types:
       - AuthOptions interface
       - AuthenticatedRequest type
       - JWTPayload type

    3. Update existing routes to use new middleware
       - Remove duplicated code
       - Use appropriate variant

    4. Update tests
       - Test each middleware variant
       - Ensure backward compatibility

    VERIFY BEHAVIOR UNCHANGED:
    - All existing tests still pass
    - Same status codes for same requests
  </action>
  <verify>
    npm test
    # All tests should pass, including existing route tests
  </verify>
  <done>
    - Middleware extracted and reusable
    - 4 variants implemented (require, role, permission, optional)
    - All routes updated to use new middleware
    - No code duplication
    - Types properly defined
    - All tests passing (including existing)
    - No behavior changed (regression)
  </done>
  <estimate>45m</estimate>
  <tags>refactoring, middleware, code-quality</tags>
</task>
```

---

### Scenario 5: Documentation

```xml
<task type="auto" id="25">
  <name>Task 25: Document authentication system</name>
  <story>Documentation (4/4)</story>
  <files>
    docs/auth/README.md,
    docs/auth/api-reference.md,
    docs/auth/architecture.md,
    docs/auth/troubleshooting.md
  </files>
  <action>
    Create comprehensive auth documentation:

    1. README.md (overview)
       - What is the auth system
       - Key features
       - Quick start guide
       - Links to other docs

    2. api-reference.md
       - All endpoints with examples
       - Request/response schemas
       - Error codes and meanings
       - Rate limiting rules
       - Authentication headers

    3. architecture.md
       - System architecture diagram
       - JWT flow diagrams
       - Database schema
       - Security measures
       - Token lifecycle

    4. troubleshooting.md
       - Common issues and solutions
       - Debugging tips
       - Error message reference
       - FAQ

    Use:
    - Clear examples
    - Code snippets
    - Diagrams (mermaid)
    - Real curl commands
  </action>
  <verify>
    # Verify all files created
    ls docs/auth/*.md

    # Verify diagrams render (if using mermaid in markdown)
    # Verify no broken links
    markdown-link-check docs/auth/*.md
  </verify>
  <done>
    - All 4 documentation files created
    - Each file complete per spec above
    - Examples tested and working
    - Diagrams clear and accurate
    - No broken links
    - Peer review approved (if checkpoint)
  </done>
  <estimate>120m</estimate>
  <tags>documentation, auth</tags>
</task>
```

---

## COMPLETION PROMISE AVANÇADO

Para tasks complexas, especificar completion_promise detalhado:

```xml
<task type="auto" id="15">
  <name>Task 15: Complex microservice integration</name>
  <files>src/integration/*.ts</files>
  <action>...</action>
  <verify>npm test && npm run integration-test</verify>
  <done>...</done>

  <completion_promise>
    <!-- Mínimo de indicators necessários -->
    <indicators_required>3</indicators_required>

    <!-- Patterns de sucesso (regex) -->
    <success_patterns>
      <pattern>all.*tests.*pass.*\d+/\d+</pattern>
      <pattern>integration.*successful</pattern>
      <pattern>coverage.*>.*80%</pattern>
      <pattern>no.*lint.*errors</pattern>
    </success_patterns>

    <!-- Patterns de falha (deve estar ausente) -->
    <failure_patterns>
      <pattern>error|failed|timeout</pattern>
      <pattern>0/\d+.*tests.*pass</pattern>
    </failure_patterns>

    <!-- Comandos que DEVEM passar -->
    <required_verifications>
      <command>npm test</command>
      <command>npm run lint</command>
      <command>npm run typecheck</command>
    </required_verifications>

    <!-- Sinal de exit explícito obrigatório -->
    <explicit_signal_required>true</explicit_signal_required>

    <!-- Máximo de iterations permitidas -->
    <max_iterations>5</max_iterations>
  </completion_promise>
</task>
```

---

## ANTI-PATTERNS

### ❌ Task Vaga

```xml
<!-- MAU -->
<task type="auto" id="5">
  <name>Task 5: Fix authentication</name>
  <action>Fix the auth issues</action>
  <verify>Test it</verify>
  <done>It works</done>
</task>
```

**Problemas:**
- "Fix authentication" - qual problema?
- "Test it" - como?
- "It works" - critério subjetivo

### ✅ Task Específica

```xml
<!-- BOM -->
<task type="auto" id="5">
  <name>Task 5: Fix JWT expiry validation bug</name>
  <context>
    Bug: Expired tokens are accepted due to missing exp claim validation
  </context>
  <action>
    In src/auth/jwt.ts:
    1. Add expiry check in verifyToken()
    2. Compare exp claim with current timestamp
    3. Throw TokenExpiredError if expired
    4. Add test case for expired token
  </action>
  <verify>
    npm test -- jwt.test.ts
    # Test should fail with expired token
  </verify>
  <done>
    - Expiry validation added to verifyToken()
    - TokenExpiredError thrown for expired tokens
    - Test case added and passing
    - Manual test: generate token with exp:-1, verify fails
  </done>
</task>
```

---

### ❌ Task Gigante

```xml
<!-- MAU -->
<task type="auto" id="10">
  <name>Task 10: Implement entire authentication system</name>
  <action>
    Build auth system with login, logout, registration,
    password reset, email verification, OAuth, 2FA...
  </action>
  <verify>Everything works</verify>
  <done>Auth system complete</done>
</task>
```

**Problemas:**
- Múltiplas responsabilidades
- Impossível completar em < 30 min
- Verification não específica
- Difícil tracking de progresso

### ✅ Tasks Fragmentadas

```xml
<!-- BOM -->
<task type="auto" id="10">
  <name>Task 10: Implement login endpoint</name>
  <action>POST /auth/login - validate credentials, return JWT</action>
  <verify>curl -X POST localhost:3000/auth/login -d '{...}'</verify>
  <done>Endpoint responds, valid creds return token, invalid return 401</done>
</task>

<task type="auto" id="11">
  <name>Task 11: Implement logout endpoint</name>
  <action>POST /auth/logout - invalidate token</action>
  <verify>curl -X POST localhost:3000/auth/logout -H 'Authorization: ...'</verify>
  <done>Token invalidated, subsequent requests with it fail</done>
</task>

<task type="auto" id="12">
  <name>Task 12: Implement registration endpoint</name>
  <action>POST /auth/register - create user, hash password</action>
  <verify>curl -X POST localhost:3000/auth/register -d '{...}'</verify>
  <done>User created in DB, password hashed, can login</done>
</task>
```

---

### ❌ Verification Ausente

```xml
<!-- MAU -->
<task type="auto" id="7">
  <name>Task 7: Add JWT token generation</name>
  <action>Create generateToken() function in jwt.ts</action>
  <verify></verify>  <!-- VAZIO -->
  <done>Function created</done>
</task>
```

**Problemas:**
- Sem verificação objetiva
- Não sabemos se funciona
- Completion baseado em "código existe"

### ✅ Verification Objetiva

```xml
<!-- BOM -->
<task type="auto" id="7">
  <name>Task 7: Add JWT token generation</name>
  <action>
    Create generateToken() in src/auth/jwt.ts:
    - Accept user payload
    - Sign with RS256
    - Set expiry to 1h
    - Return token string
  </action>
  <verify>
    npm test -- jwt.test.ts
    node -e "const {generateToken} = require('./src/auth/jwt'); console.log(generateToken({id:1}))"
  </verify>
  <done>
    - generateToken() function exists
    - Returns valid JWT token
    - Token contains user payload
    - Token expiry set to 1h
    - Token signed with RS256
    - Tests passing (5/5)
  </done>
</task>
```

---

## TEMPLATES RÁPIDOS

### Template: Auto Task

```xml
<task type="auto" id="{N}">
  <name>Task {N}: {Action verb} {specific target}</name>
  <story>{Story name} ({X}/{Total})</story>
  <files>{paths}</files>
  <action>
    {Specific steps}
    AVOID: {Common pitfalls}
  </action>
  <verify>{Command to run}</verify>
  <done>
    - {Measurable criterion 1}
    - {Measurable criterion 2}
    - {Measurable criterion 3}
  </done>
</task>
```

### Template: Checkpoint

```xml
<task type="checkpoint:human-verify" id="{N}">
  <name>Task {N}: Review {what}</name>
  <context>{Why this checkpoint matters}</context>
  <files>{paths}</files>
  <action>
    Present for review:
    - {Artifact 1}
    - {Artifact 2}
    Await approval
  </action>
  <stop_hook>
    type: human-verify
    prompt: "{Question} [approve/modify/reject]"
    on_approve: {next action}
    on_modify: {modification action}
    on_reject: {fallback action}
  </stop_hook>
  <done>
    - {Artifacts presented}
    - Human approval received
    - {Feedback incorporated}
  </done>
</task>
```

---

## FILOSOFIA DO XML

```
XML estruturado não é burocracia.
É contrato entre intenção e execução.

Task bem definida = Executor sabe exatamente o que fazer
Verification clara = Progresso é objetivo
Done específico = Completion é inequívoco

Ralph Loop não precisa adivinhar.
Humanos não precisam explicar de novo.
Transferibilidade total.
```

---

*XML Task Format v2.0.0*
*"Structure is not overhead. Ambiguity is."*
