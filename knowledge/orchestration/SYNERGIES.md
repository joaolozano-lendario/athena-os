# SYNERGIES — ATHENA OS 2.0

> **"Combinações certas criam resultados maiores que a soma das partes."**

---

## CONCEITO

Synergies são combinações de ferramentas, técnicas ou abordagens que, quando usadas juntas, produzem resultados multiplicados.

Este documento cataloga as synergies descobertas e validadas.

---

## SYNERGIES DE FERRAMENTAS

### S1: Glob → Read Pipeline

**Combinação:** Glob para descobrir, Read para examinar

**Quando usar:**
- Precisa encontrar e analisar arquivos
- Não sabe exatamente quais arquivos existem
- Quer examinar múltiplos arquivos do mesmo tipo

**Flow:**
```
1. Glob("**/*.yaml") → Lista de arquivos
2. Read(arquivo1) → Conteúdo
3. Read(arquivo2) → Conteúdo
4. Sintetizar
```

**Multiplicador:** 3x mais eficiente que busca manual

---

### S2: Grep → Read Context

**Combinação:** Grep para localizar, Read com offset para contexto

**Quando usar:**
- Sabe o que procura mas não onde está
- Precisa ver contexto ao redor do match

**Flow:**
```
1. Grep("epistemic_state") → Arquivo:linha
2. Read(arquivo, offset=linha-10, limit=30) → Contexto
```

**Multiplicador:** Encontra rapidamente sem ler arquivos inteiros

---

### S3: Parallel Agents → Synthesis

**Combinação:** Múltiplos agents em paralelo + síntese no main

**Quando usar:**
- Tasks independentes
- Tempo é crítico
- Expertise diferente necessária

**Flow:**
```
1. Spawn Agent A (Epic 1)
2. Spawn Agent B (Epic 2) — paralelo
3. Spawn Agent C (Epic 3) — paralelo
4. Collect results
5. Synthesize no main
```

**Multiplicador:** N agents = tempo de 1 agent (não N*tempo)

---

### S4: Read → Edit → Validate

**Combinação:** Entender, modificar, verificar

**Quando usar:**
- Modificando código existente
- Mudança precisa ser precisa
- Risco de quebrar algo

**Flow:**
```
1. Read(arquivo) → Entender estado atual
2. Edit(arquivo, old, new) → Fazer mudança
3. Read(arquivo) → Verificar resultado
```

**Multiplicador:** Evita erros de edição cega

---

### S5: Template + Write

**Combinação:** Template definido + Write com substituição

**Quando usar:**
- Criar múltiplos arquivos similares
- Consistência é importante
- Padrão já estabelecido

**Flow:**
```
1. Read(template) → Estrutura base
2. Substituir placeholders
3. Write(novo_arquivo) → Arquivo customizado
```

**Multiplicador:** Consistência garantida, velocidade alta

---

## SYNERGIES DE WORKFLOW

### W1: P0 + Genius Layer

**Combinação:** Reflexão pré-execução + ativação de kit cognitivo

**Quando usar:**
- Início de qualquer Blueprint
- Contexto novo ou complexo

**Flow:**
```
1. P0: REFLECT → Identificar natureza
2. Detectar nature code (COPY, ARCH, META...)
3. Ativar cognitive kit correspondente
4. Carregar lentes relevantes
5. Prosseguir com Dream Team ativo
```

**Multiplicador:** Perspectivas certas desde o início

---

### W2: Gates + Pattern Capture

**Combinação:** Validação de quality gates + captura de padrões

**Quando usar:**
- Fim de cada fase
- Padrões emergindo

**Flow:**
```
1. Executar fase
2. Validar gate
3. SE PASSED:
   - Documentar o que funcionou
   - Capturar padrão se novo
4. SE FAILED:
   - Documentar anti-pattern
   - Corrigir e re-tentar
```

**Multiplicador:** Aprendizado estruturado contínuo

---

### W3: Epistemic + Orchestration

**Combinação:** Modelagem de incerteza + decisão de orquestração

**Quando usar:**
- Decidindo quanto paralelizar
- Escolhendo entre abordagens

**Flow:**
```
1. Avaliar confidence em cada path
2. SE confidence ALTA em todos:
   - Paralelizar agressivamente
3. SE confidence BAIXA em algum:
   - Ir depth-first no incerto primeiro
   - Depois paralelo no que sobra
```

**Multiplicador:** Riscos mitigados antes de escalar

---

## SYNERGIES DE COMUNICAÇÃO

### C1: Structured Briefing + Clear Exit Criteria

**Combinação:** Briefing completo + critérios de sucesso claros

**Quando usar:**
- Delegando para agents
- Handoff entre sessões

**Flow:**
```
BRIEFING:
- Contexto (2-3 sentenças)
- Objetivo (1 frase)
- Deliverables (lista)
- Constraints (o que NÃO fazer)

EXIT CRITERIA:
- [ ] Critério verificável 1
- [ ] Critério verificável 2
```

**Multiplicador:** Zero re-briefing necessário

---

### C2: Confidence Annotation + Validation Focus

**Combinação:** Documentar incertezas + focar validação onde importa

**Quando usar:**
- Revisão de outputs
- Planejamento de testes

**Flow:**
```
1. Gerar output com confidence annotation
2. Identificar áreas de LOW confidence
3. Focar validação/teste nessas áreas
4. Atualizar confidence após validação
```

**Multiplicador:** Validação eficiente, não exaustiva

---

## ANTI-SYNERGIES (Combinações a Evitar)

### AS1: Parallel + Shared State

**Problema:** Agents paralelos tentando modificar mesmo recurso
**Resultado:** Conflitos, perda de dados
**Evitar:** Particionar trabalho por recurso

---

### AS2: Deep Read + Tight Context

**Problema:** Ler muito quando contexto já está apertado
**Resultado:** Degradação de qualidade
**Evitar:** Compactar antes de carregar mais

---

### AS3: Vague Briefing + Autonomous Agent

**Problema:** Delegar sem especificação clara
**Resultado:** Output incorreto, retrabalho
**Evitar:** Sempre briefing estruturado completo

---

## DESCOBRINDO NOVAS SYNERGIES

Ao identificar uma nova synergy:

1. **Documentar** no pattern_library
2. **Nomear** de forma memorável
3. **Definir** quando usar
4. **Quantificar** multiplicador se possível
5. **Validar** em 3+ usos antes de promover

---

*ATHENA OS 2.0 — Synergies*
*"1 + 1 = 3 quando a combinação é certa."*
