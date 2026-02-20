# Data Lenses — Domain-Specific

> Lentes específicas para projetos de análise de dados e insights.

---

## 1. DATA INTEGRITY LENS

**Pergunta:** "Os dados são confiáveis? Qual a proveniência?"

Checklist:
- [ ] Fonte dos dados documentada
- [ ] Método de coleta conhecido
- [ ] Período de cobertura claro
- [ ] Missing data identificado
- [ ] Outliers investigados

**Regra:** Garbage in, garbage out.

---

## 2. BIAS LENS

**Pergunta:** "Que vieses podem estar afetando esta análise?"

Vieses comuns:
- **Selection bias** — Amostra não representativa
- **Survivorship bias** — Só vemos os que sobreviveram
- **Confirmation bias** — Buscamos o que queremos encontrar
- **Recency bias** — Dados recentes pesam demais

**Teste:** Alguém com agenda oposta encontraria o mesmo?

---

## 3. CORRELATION VS CAUSATION LENS

**Pergunta:** "Isso é correlação ou causação?"

Níveis de evidência:
1. **Correlação** — X e Y andam juntos
2. **Precedência** — X vem antes de Y
3. **Exclusão** — Não há Z causando ambos
4. **Mecanismo** — Entendemos como X causa Y
5. **Experimento** — Manipular X muda Y

**Regra:** Correlação ≠ causação. Sempre.

---

## 4. SIGNAL VS NOISE LENS

**Pergunta:** "Isso é sinal real ou ruído aleatório?"

Perguntas:
- O padrão persiste com mais dados?
- É estatisticamente significante?
- Faz sentido logicamente?
- Replica em outra amostra?

**Teste:** Se randomizar labels, padrão desaparece?

---

## 5. BLACK SWAN LENS

**Pergunta:** "Que eventos raros não estamos considerando?"

Considerações:
- Distribuição tem fat tails?
- Eventos raros têm impacto desproporcional?
- Modelos assumem normalidade?
- Estresse-testado com extremos?

**Regra:** Raro não significa impossível.

---

## 6. SO WHAT LENS

**Pergunta:** "E daí? Que ação isso informa?"

Checklist:
- [ ] Insight leva a ação específica
- [ ] Ação é viável
- [ ] Impacto esperado é claro
- [ ] Pode ser medido depois

**Regra:** Insight sem ação é trivia.

---

## 7. SIMPSON'S PARADOX LENS

**Pergunta:** "O padrão inverte quando segmentamos?"

Exemplo clássico:
- Agregado: Tratamento A parece melhor
- Segmentado: Tratamento B é melhor em cada grupo

**Teste:** Cortar dados por segmentos relevantes muda conclusão?

---

## 8. BASE RATE LENS

**Pergunta:** "Qual é a base rate que ignoro?"

Exemplo:
- Teste tem 99% accuracy
- Doença afeta 1 em 10.000
- Positivo? Provavelmente falso positivo

**Regra:** Probabilidades condicionais precisam de base rates.

---

*Domain Lenses: DATA | ATHENA OS 2.0*
