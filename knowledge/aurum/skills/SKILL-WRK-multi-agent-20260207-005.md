---
type: knowledge-skill
id: SKILL-WRK-multi-agent-20260207-005
source: MTH-20260207-019
domain: multi-agent
skill_type: workflow
confidence: 0.8
---

# Multi-Agent System Architecture Composition

> 6-step process to build orchestrated multi-agent systems from autonomous agents to coordinated collective with governance

## Pre-condicoes

- [ ] Understanding of distributed architecture patterns
- [ ] Use cases justifying multiple agents (high complexity, parallelism needed, domain specialization)
- [ ] Infrastructure for inter-agent communication (message queues, APIs, event streams)
- [ ] Communication protocols defined (MCP for tools, A2A for peer coordination)

## Passos

### Passo 1: Define specialized agents by category

**Acao:** Define specialized agents by category

Classify and design agents in three categories: Worker Agents (execute well-defined tasks, can be stateless or stateful, operate in parallel, domain-specialized. Example: in underwriting, one extracts documents, one computes credit scores, one generates risk assessments). Service Agents (provide shared operational capabilities: QA agents verify data/compliance, Diagnostic agents inspect inconsistencies, Healing agents retry failed extractions, Upgrade schedulers manage version transitions). Support Agents (supervisory and analytical level: Monitoring agents track latency/drift/health, Analytics agents evaluate approval patterns/anomalies, Data agents update datasets).

⚡ **Decision Point:** How many agents? Few = individual overload. Many = coordination overhead. Find balance based on task complexity.

### Passo 2: Build orchestration layer

**Acao:** Build orchestration layer

Implement four units: Planning & Policy (convert high-level objectives to structured execution plan. Planning unit as goal-decomposition engine. Policy unit embeds domain constraints and governance). Execution & Control (transition agents through init/execute/validate/conclude phases. Manage concurrency and dependencies. Allow parallel execution with checkpoint synchronization). State & Knowledge (manage checkpoints, workflow progress, agent states, activity logs. Connect external data sources as recoverable context). Quality & Operations (evaluate performance, validate outcomes, ensure compliance. Validate aggregated outputs against schemas before integrating to shared state).

⚡ **Decision Point:** Centralized vs decentralized orchestration? Centralized = more control, single point of failure. Decentralized = more resilient, more complex.

### Passo 3: Implement communication protocols

**Acao:** Implement communication protocols

Configure two complementary protocols: MCP (Model Context Protocol): standardized interface between agents and external systems (tools, data services, context repositories). Client-server design where agents are clients requesting external capabilities. Support stateless and stateful sessions for multi-step workflows. A2A (Agent-to-Agent Protocol): standardized communication between specialized agents. Supports negotiation, delegation, coordination. Direct peer communication or orchestrator-mediated. Structured metadata and standardized payloads. Security controls: cryptographic signing and role-based routing.

⚡ **Decision Point:** When to use direct agent communication vs orchestrator-mediated? Direct = lower latency, less control. Mediated = more auditable, more overhead.

### Passo 4: Implement safety and governance guardrails

**Acao:** Implement safety and governance guardrails

Embed safeguards: mitigate hallucinations with consistency checks, internal audits, event logging and least privilege policies. Privacy restrictions: agents share only task-relevant information. Continuous monitoring: latency, throughput, correctness. Schema validation in message exchanges. Authentication and access control in all communications.

⚡ **Decision Point:** Privacy restriction level: too restrictive limits collaboration, too permissive exposes sensitive data.

### Passo 5: Validate with enterprise use case

**Acao:** Validate with enterprise use case

Test system in real scenario before scaling: BFSI (underwriting with >95% accuracy, 20x faster processing, 80% cost reduction), Software Engineering (digital factory with specialized agents for docs/generation/review/integration/test, 50%+ reduction in time/effort), Customer Service (agents resolve 80% of common incidents autonomously, 60-90% cut in resolution time).

### Passo 6: Iterate and scale

**Acao:** Iterate and scale

Address emerging challenges as system scales: communication overhead between numerous agents, orchestration/infrastructure/monitoring costs, governance of decentralized autonomy. Explore hybrid and federated designs to balance centralized control with decentralized flexibility.

## Resultado Esperado

- Specialized agents operational in all three categories
- Orchestration layer managing planning, execution, state and quality
- Communication protocols (MCP and A2A) functional
- Safety guardrails and governance in place
- System validated in real enterprise scenario

## Se Algo Der Errado

If coordination overhead exceeds benefits, reduce agent count and consolidate responsibilities. If governance gap emerges, strengthen policy enforcement before scaling further. If message congestion occurs, implement queue management and rate limiting.

---
> Fonte: [[MTH-20260207-019]] | Confianca: 0.8
