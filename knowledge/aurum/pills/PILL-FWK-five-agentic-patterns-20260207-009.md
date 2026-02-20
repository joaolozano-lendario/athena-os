---
type: knowledge-pill
id: PILL-FWK-orchestration-20260207-009
source: FWK-20260207-013
domain: orchestration
confidence: 0.95
---

**Five composable LLM orchestration patterns: Chaining, Routing, Parallelization, Orchestrator-Workers, Evaluator-Optimizer - start simple.**

Definitive taxonomy of LLM composition patterns: 1. Prompt Chaining (sequential steps with validation), 2. Routing (classify input → specialized handlers), 3. Parallelization (split work or vote for confidence), 4. Orchestrator-Workers (dynamic decomposition for unpredictable tasks), 5. Evaluator-Optimizer (generate → evaluate → refine loop). Patterns are COMPOSABLE, not exclusive. Golden rule: Start simple. Add complexity only when simpler approaches demonstrably underperform.

**Quando aplicar:**
- When designing multi-agent systems, choosing orchestration architecture, or diagnosing agent performance issues
- Need to structure agent interactions
- Deciding between orchestration approaches
- System complexity growing beyond single agent

**Exemplo:** Unpredictable complex task (code project) → Orchestrator-Workers pattern with dynamic decomposition. Multi-stage document processing with clear steps → Prompt Chaining with validation gates. Different input types need different approaches → Routing to specialized handlers.

> Fonte: [[FWK-20260207-013]] | Confianca: 0.95
