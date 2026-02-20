# CONFIDENCE GUIDE — ATHENA OS 2.0

> **"A sabedoria começa quando reconhecemos o que não sabemos."**

---

## PROPÓSITO

Este guia define como modelar, expressar e calibrar confiança em outputs de ATHENA. Confiança bem calibrada é mais valiosa que certeza falsa.

---

## A ESCALA DE CONFIANÇA

| Score | Nível | Descrição | Ação Requerida |
|-------|-------|-----------|----------------|
| 0.0-0.1 | WILD_GUESS | Sem base real | Investigar imediatamente |
| 0.1-0.3 | LOW | Especulativo | Validação urgente |
| 0.3-0.5 | MEDIUM_LOW | Evidências fracas | Verificar antes de depender |
| 0.5-0.7 | MEDIUM_HIGH | Razoável | Monitorar durante execução |
| 0.7-0.9 | HIGH | Bem fundamentado | Verificar edge cases |
| 0.9-1.0 | VERY_HIGH | Quase certeza | Atenção a unknown unknowns |

---

## COMO DETERMINAR CONFIANÇA

### Fatores que AUMENTAM confiança:

1. **Evidência direta** — Você observou ou testou
2. **Múltiplas fontes** — Informações convergentes
3. **Experiência prévia** — Padrões reconhecidos
4. **Documentação clara** — Fonte autoritativa
5. **Validação cruzada** — Perspectivas diferentes chegam ao mesmo ponto

### Fatores que DIMINUEM confiança:

1. **Suposições implícitas** — Premissas não verificadas
2. **Fonte única** — Sem corroboração
3. **Domínio novo** — Sem experiência prévia
4. **Requisitos ambíguos** — Interpretação incerta
5. **Complexidade alta** — Muitas variáveis interconectadas
6. **Pressão de tempo** — Análise apressada

---

## FRAMEWORK DE AVALIAÇÃO

Para cada output, pergunte:

### 1. Base Evidencial
- De onde vem esta informação?
- Quão confiável é a fonte?
- Foi verificada de alguma forma?

### 2. Suposições
- Que suposições estou fazendo?
- São explícitas ou implícitas?
- O que acontece se estiverem erradas?

### 3. Lacunas
- O que eu não sei que deveria saber?
- Quão críticas são essas lacunas?
- Como posso resolvê-las?

### 4. Calibração
- Minhas estimativas anteriores foram precisas?
- Tendo a ser over-confident ou under-confident?
- O que isso sugere para esta estimativa?

---

## EXEMPLOS PRÁTICOS

### Exemplo 1: Alta Confiança (0.85)

```yaml
statement: "O sistema usa PostgreSQL como banco de dados"
confidence: 0.85
basis:
  - Observado em: package.json, docker-compose.yaml
  - Confirmado em: .env.example
  - Consistente com: estrutura de migrations
remaining_uncertainty:
  - Pode haver banco secundário não identificado
```

### Exemplo 2: Média Confiança (0.55)

```yaml
statement: "A arquitetura segue padrão hexagonal"
confidence: 0.55
basis:
  - Estrutura de pastas sugere separação
  - Alguns adapters identificados
uncertainty:
  - Implementação pode não seguir rigorosamente
  - Não encontrei documentation explícita
  - Alguns módulos parecem misturar concerns
```

### Exemplo 3: Baixa Confiança (0.25)

```yaml
statement: "O sistema suporta 10k usuários simultâneos"
confidence: 0.25
basis:
  - Mencionado em um comentário de código
uncertainty:
  - Sem testes de carga encontrados
  - Infraestrutura não analisada
  - Requisito pode estar desatualizado
action_needed: Validar com stakeholder ou testes
```

---

## QUANDO USAR CADA NÍVEL

### Use LOW (0.1-0.3) quando:
- Informação vem de fonte única não verificada
- Está extrapolando de contexto diferente
- Não tem experiência no domínio
- Tempo de análise foi muito curto

### Use MEDIUM (0.3-0.7) quando:
- Tem algumas evidências mas não completas
- Padrões reconhecidos com variações possíveis
- Suposições razoáveis mas não verificadas
- Domínio familiar mas caso específico novo

### Use HIGH (0.7-0.9) quando:
- Múltiplas fontes convergentes
- Experiência prévia similar
- Documentação clara disponível
- Validação parcial realizada

### Use VERY_HIGH (0.9+) quando:
- Verificado diretamente
- Múltiplas validações independentes
- Domínio de expertise
- Casos de teste existentes

---

## ANTI-PATTERNS DE CONFIANÇA

### 1. Confidence Theater
**O que é:** Afirmar alta confiança sem base real.
**Perigo:** Decisões erradas baseadas em ilusão de certeza.
**Solução:** Sempre documentar BASE da confiança.

### 2. False Humility
**O que é:** Afirmar baixa confiança quando sabe bem.
**Perigo:** Análise paralisa, over-validation.
**Solução:** Calibrar com resultados históricos.

### 3. Anchoring
**O que é:** Primeira estimativa domina análise subsequente.
**Perigo:** Não atualizar confiança com nova informação.
**Solução:** Re-avaliar independentemente em cada fase.

### 4. Assumption Blindness
**O que é:** Não reconhecer suposições implícitas.
**Perigo:** Surpresas tardias quando suposições falham.
**Solução:** P0: REFLECT para surfacear suposições.

---

## INTEGRANDO COM O PIPELINE

### P0: REFLECT
- Documentar suposições iniciais
- Identificar lacunas de conhecimento
- Estabelecer baseline de confiança

### P1: DECODE
- Confiança na interpretação da intenção
- Ambiguidades identificadas

### P2: ARCHITECT
- Confiança nas decisões arquiteturais
- Riscos técnicos reconhecidos

### P3: FRAGMENT
- Confiança na completude da fragmentação
- Tasks que podem ter dependências ocultas

### P4: CRYSTALLIZE
- Confiança geral do Blueprint
- Áreas que precisam atenção durante execução

### P5: LEARN
- Calibrar confiança vs. resultados reais
- Atualizar heurísticas de estimativa

---

## CALIBRAÇÃO CONTÍNUA

Após cada Blueprint executado:

1. **Compare** confiança estimada vs. resultado real
2. **Identifique** vieses sistemáticos
3. **Ajuste** heurísticas futuras
4. **Documente** aprendizado no pattern_library

---

*ATHENA OS 2.0 — Confidence Guide*
*"Confiança calibrada é humildade operacionalizada."*
