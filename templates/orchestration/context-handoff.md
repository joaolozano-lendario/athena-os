# CONTEXT HANDOFF: {SESSION_ID}

> Template para transferência de contexto entre sessões ou agents

---

## METADATA

| Campo | Valor |
|-------|-------|
| From | {origem - sessão/agent} |
| To | {destino - sessão/agent} |
| Timestamp | {ISO-8601} |
| Blueprint | {BP-ID se aplicável} |

---

## OBJETIVO DA SESSÃO ORIGINAL

{Uma frase clara do que estava sendo feito}

---

## ESTADO ATUAL

### Progresso
- **Phase:** {P0/P1/P2/P3/P4/P5}
- **Épico:** {E1/E2/E3/.../E6}
- **Tasks Completas:** {X de Y}

### Status
```
[X] Task completada 1
[X] Task completada 2
[ ] Task pendente 3 ← PRÓXIMO
[ ] Task pendente 4
```

### Blockers
- {blocker 1 se houver}
- {blocker 2 se houver}
- *Nenhum* se não houver

---

## DECISÕES ESTRUTURAIS

| Decisão | Razão | Impacto |
|---------|-------|---------|
| {decisão 1} | {por quê} | {onde afeta} |
| {decisão 2} | {por quê} | {onde afeta} |

---

## CONTEXTO CRÍTICO

### Arquivos-Chave
| Arquivo | Relevância |
|---------|------------|
| `{path}` | {por que importante} |
| `{path}` | {por que importante} |

### Conceitos Ativos
- **{conceito 1}:** {breve explicação}
- **{conceito 2}:** {breve explicação}

### Constraints Descobertos
- {constraint 1}
- {constraint 2}

---

## PRÓXIMAS AÇÕES

### Imediatas (fazer primeiro)
1. [ ] {ação prioritária 1}
2. [ ] {ação prioritária 2}

### Subsequentes
3. [ ] {ação 3}
4. [ ] {ação 4}

---

## O QUE NÃO TRANSFERIR

{Coisas que podem ser descartadas - não mais relevantes}

- {contexto obsoleto 1}
- {contexto obsoleto 2}
- {tentativa falha que não precisa ser lembrada}

---

## REFERÊNCIAS PARA RELEITURA

Se precisar de mais contexto, ler:

1. `{path}` — {o que contém}
2. `{path}` — {o que contém}

---

## NOTAS DO OPERADOR

{Qualquer informação adicional que ajude a continuação}

---

*Handoff: {SESSION_ID} | ATHENA OS 2.0*
