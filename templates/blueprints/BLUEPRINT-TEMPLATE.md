# BLUEPRINT OPERACIONAL
# {TITULO DO PROJETO}

---

**ID:** BP-{YYYY-MM-DD}-{NNN}
**Versao:** 1.0.0
**Gerado por:** ATHENA OS v1.0
**Data:** {YYYY-MM-DD HH:MM}
**Projeto-alvo:** {nome do projeto}
**Caminho:** {path do projeto}

---

## 1. SUMARIO EXECUTIVO

### 1.1 O Que E

{Descricao clara em 2-3 frases do que este Blueprint realiza}

### 1.2 Por Que Existe

> "Quando {SITUACAO}, eu quero {MOTIVACAO}, para que {RESULTADO}."

### 1.3 Resultado Esperado

Ao final da execucao deste Blueprint:

- [ ] {Deliverable 1}
- [ ] {Deliverable 2}
- [ ] {Deliverable 3}

### 1.4 Estimativas

| Metrica | Valor |
|---------|-------|
| Complexidade | {LOW/MEDIUM/HIGH/EXTREME} |
| Esforco estimado | {X horas/dias} |
| Numero de epicos | {N} |
| Numero de tasks | {N} |

---

## 2. INTENT SPECIFICATION

### 2.1 Dimensoes

#### O QUE

**Explicito:**
{O que foi pedido}

**Implicito:**
{O que e necessario mas nao foi dito}

**Fora do Escopo:**
{O que NAO esta incluido}

#### POR QUE

**Razao de Superficie:**
{A razao aparente}

**Razao Profunda:**
{A motivacao real}

#### QUEM

- **Operador:** {quem executa}
- **Beneficiario:** {quem se beneficia}

#### ONDE

- **Projeto:** {nome}
- **Path:** `{caminho}`

#### QUANDO

- **Urgencia:** {nivel}
- **Deadline:** {data ou N/A}

#### COMO

**Constraints:**
- {Limitacao 1}
- {Limitacao 2}

**Anti-Patterns:**
- {O que NAO fazer}

### 2.2 Criterios de Sucesso

**MUST HAVE:**
- [ ] {Criterio obrigatorio 1}
- [ ] {Criterio obrigatorio 2}

**SHOULD HAVE:**
- [ ] {Criterio desejavel}

**MUST NOT:**
- {O que nao pode acontecer}

---

## 3. EXECUTION ARCHITECTURE

### 3.1 Visao Geral

```mermaid
{Diagrama do workflow}
```

### 3.2 Fases

| # | Fase | Objetivo | Output | Gate |
|---|------|----------|--------|------|
| 1 | {Nome} | {Objetivo} | {Output} | {Criterio} |
| 2 | {Nome} | {Objetivo} | {Output} | {Criterio} |

### 3.3 Detalhamento das Fases

#### Fase 1: {Nome}

**Objetivo:**
{Descricao}

**Inputs:**
- {Input 1}

**Outputs:**
- {Output 1}

**Gate:**
- {Criterio de passagem}

{Repetir para cada fase}

### 3.4 Agentes (se aplicavel)

| Agente | Role | Invocado em |
|--------|------|-------------|
| {Nome} | {Papel} | {Fases} |

---

## 4. CHECKPOINT MAP

### 4.1 Visao Geral

| Epico | Stories | Tasks | Status |
|-------|---------|-------|--------|
| E-1: {Nome} | {N} | {N} | TODO |

### 4.2 Epicos Detalhados

#### E-1: {Nome do Epico}

**Objetivo:** {Descricao}
**Acceptance Criteria:** {Como saber que terminou}

##### S-1.1: {Nome da Story}

> Como {persona}, eu quero {acao}, para que {beneficio}.

**Tasks:**

- [ ] **T-1.1.1:** {Titulo}
  - Criterio: {Condicao binaria}
  - Duracao: {estimativa}

- [ ] **T-1.1.2:** {Titulo}
  - Criterio: {Condicao binaria}
  - Duracao: {estimativa}
  - Depende de: T-1.1.1

{Repetir para cada story e task}

### 4.3 Checkpoints

| CP | Apos | Validacao | Acao se Falhar |
|----|------|-----------|----------------|
| CP-1 | T-X.Y.Z | {O que verificar} | {O que fazer} |

---

## 5. TAXONOMY CONFIG

### 5.1 Estrutura de Outputs

```
{projeto}/
+-- {pasta}/
|   +-- {arquivo}.{ext}
|   +-- {arquivo}.{ext}
+-- STATE.yaml
```

### 5.2 Convencoes

| Tipo | Padrao | Exemplo |
|------|--------|---------|
| Arquivos | {padrao} | {exemplo} |
| Pastas | {padrao} | {exemplo} |
| IDs | {padrao} | {exemplo} |

---

## 6. GUIA DE EXECUCAO

### 6.1 Pre-requisitos

Antes de iniciar, garantir que:

- [ ] {Pre-requisito 1}
- [ ] {Pre-requisito 2}

### 6.2 Primeiro Passo

```
{Comando ou acao inicial}
```

### 6.3 Fluxo de Execucao

1. {Passo 1}
2. {Passo 2}
3. {Passo 3}

### 6.4 Pontos de Atencao

**{Ponto 1}:** {Descricao do cuidado necessario}

**{Ponto 2}:** {Descricao do cuidado necessario}

---

## 7. CRITERIOS DE SUCESSO FINAL

A execucao esta completa quando TODOS os criterios abaixo forem atendidos:

- [ ] {Criterio 1}
- [ ] {Criterio 2}
- [ ] {Criterio 3}
- [ ] STATE.yaml atualizado com status COMPLETED

---

## ANEXOS

### A. Referencias

- {Referencia 1}
- {Referencia 2}

### B. Glossario

- **{Termo}:** {Definicao}

---

*Blueprint gerado por ATHENA OS v1.0*
*Timestamp: {ISO-8601}*
