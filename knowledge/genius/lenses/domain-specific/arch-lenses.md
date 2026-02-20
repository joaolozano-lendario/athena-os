# Architecture Lenses — Domain-Specific

> Lentes específicas para projetos de arquitetura de sistemas.

---

## 1. COUPLING LENS

**Pergunta:** "Quão acoplados estão os componentes?"

| Nível | Descrição | Sinal |
|-------|-----------|-------|
| Tight | Mudança em um quebra outros | Ruim |
| Loose | Componentes independentes | Bom |
| Zero | Nenhuma conexão | Pode ser over-engineering |

**Teste:** Posso mudar/remover componente X sem afetar Y?

---

## 2. SCALABILITY LENS

**Pergunta:** "Como se comporta com 10x, 100x load?"

Dimensões de scale:
- **Vertical** — Máquina maior
- **Horizontal** — Mais máquinas
- **Data** — Mais dados armazenados
- **Users** — Mais usuários simultâneos

**Teste:** Desenhar diagrama com 100x load. O que quebra primeiro?

---

## 3. FAILURE MODE LENS

**Pergunta:** "O que acontece quando X falha?"

Para cada componente:
- Database cai → ?
- Network instável → ?
- Terceiro não responde → ?
- Disco cheio → ?

**Regra:** Design for failure, não para caso feliz.

---

## 4. TESTABILITY LENS

**Pergunta:** "Como isso é testado? É testável isoladamente?"

Sinais de problema:
- "Precisa do banco rodando para testar"
- "Só funciona em produção"
- "Depende de serviço externo"

**Regra:** Se não é testável, refatore até ser.

---

## 5. CHANGE LENS

**Pergunta:** "Quanto esforço para mudar X?"

Mudanças comuns a considerar:
- Trocar banco de dados
- Adicionar novo tipo de autenticação
- Mudar lógica de negócio core
- Escalar para outro país/timezone

**Teste:** Estimativa honesta de esforço para cada mudança.

---

## 6. SIMPLICITY LENS

**Pergunta:** "Isso é o mais simples que funciona?"

Red flags de over-engineering:
- Abstrações sem uso real
- Patterns "porque sim"
- Configurabilidade não requisitada
- "Vai ser útil no futuro" (YAGNI)

**Teste:** Remove complexity, ainda funciona? Então remova.

---

## 7. SECURITY LENS

**Pergunta:** "Onde estão as superfícies de ataque?"

Checklist:
- [ ] Input validation
- [ ] Authentication/Authorization
- [ ] Data encryption (rest & transit)
- [ ] Secrets management
- [ ] OWASP Top 10

---

## 8. OPERATIONS LENS

**Pergunta:** "Isso é operável em produção?"

Checklist:
- [ ] Logging adequado
- [ ] Métricas expostas
- [ ] Health checks
- [ ] Deploy automatizável
- [ ] Rollback possível
- [ ] Runbook documentado

---

*Domain Lenses: ARCH | ATHENA OS 2.0*
