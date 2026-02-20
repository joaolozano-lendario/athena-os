# ATHENA: Reflect

Executa o protocolo **P0: REFLECT** — reflexão pré-execução para preparar o sistema cognitivo.

---

## TRIGGER

Este comando foi invocado. Execute P0: REFLECT.

---

## INSTRUÇÕES

### 1. CARREGAR CONTEXTO

Ler:
- `D:/athena-os/STATE.yaml` — estado atual
- `D:/athena-os/observability/execution_log.yaml` — últimas execuções
- `D:/athena-os/observability/pattern_library.yaml` — padrões conhecidos

### 2. ANALISAR REQUEST

Se houver contexto da conversa anterior:
- Identificar intenção do operador
- Detectar nature code (COPY|ARCH|META|DATA|PROD|BRAND|LEARN|CODE)
- Avaliar complexidade

Se não houver contexto:
- Perguntar ao operador sobre o projeto

### 3. VERIFICAR SIMILARIDADE

Com base nas últimas 5 execuções:
- Este request é similar a algum anterior?
- Que lições se aplicam?
- Que erros evitar?

### 4. CARREGAR COGNITIVE KIT

Baseado na nature detectada:
- Carregar kit de `knowledge/genius/kits/{NATURE}.yaml`
- Identificar dream team
- Selecionar lenses relevantes

### 5. ANTECIPAR RISCOS

- Onde pode travar?
- Que clarificações são necessárias?
- Que suposições estão sendo feitas?

### 6. GERAR OUTPUT

Apresentar ao operador:

```markdown
## P0: REFLECT — Reflexão Completa

### Nature Detectada
- **Código:** {nature}
- **Confidence:** {0.0-1.0}

### Kit Ativado
- **Dream Team:** {personas}
- **Lenses:** {lenses principais}

### Contexto Histórico
- **Blueprints similares:** {lista}
- **Lições aplicáveis:** {lista}

### Riscos Antecipados
- {risco 1}
- {risco 2}

### Clarificações Necessárias
- {pergunta 1}
- {pergunta 2}

### Status
- **Pronto para P1:** Sim/Não
- **Blockers:** {se houver}
```

### 7. PRÓXIMOS PASSOS

Se pronto:
- Operador pode prosseguir com `/ATHENA:tasks:forge-blueprint`

Se não pronto:
- Resolver clarificações antes de prosseguir

---

*P0: REFLECT | ATHENA OS 2.0*
