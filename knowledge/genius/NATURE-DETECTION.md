# NATURE DETECTION — ATHENA OS 2.0

> **"Identificar a natureza corretamente é metade da batalha."**

---

## PROPÓSITO

Nature Detection é o processo de identificar a natureza fundamental de um projeto ou task para ativar o Cognitive Kit apropriado.

---

## PROCESSO DE DETECÇÃO

### 1. Análise de Keywords

| Keywords | Nature Indicada |
|----------|-----------------|
| headline, copy, hook, persuasão, conversão, CTA, landing page | **COPY** |
| API, microservices, database, infra, scalability, patterns | **ARCH** |
| framework, meta, sistema de sistemas, abstração, templates | **META** |
| análise, dados, dashboard, insights, métricas, relatório | **DATA** |
| workflow, automação, produtividade, processo, eficiência | **PROD** |
| marca, brand, posicionamento, identidade, messaging | **BRAND** |
| curso, educação, treinamento, aprendizado, tutorial | **LEARN** |
| feature, bug, código, refactor, implementação | **CODE** |

### 2. Análise de Objetivo

Perguntar: "O que o operador quer ALCANÇAR?"

| Objetivo | Nature |
|----------|--------|
| Convencer alguém a agir | COPY |
| Construir sistema técnico | ARCH |
| Criar sistema que cria sistemas | META |
| Entender dados e extrair insights | DATA |
| Otimizar como trabalho é feito | PROD |
| Construir/fortalecer marca | BRAND |
| Ensinar algo a alguém | LEARN |
| Fazer código funcionar | CODE |

### 3. Análise de Artefatos

Que tipo de output será gerado?

| Artefato Principal | Nature |
|--------------------|--------|
| Texto persuasivo, emails, páginas | COPY |
| Código, configs, diagramas técnicos | ARCH |
| Frameworks, templates, protocolos | META |
| Dashboards, relatórios, visualizações | DATA |
| Processos, SOPs, automações | PROD |
| Guidelines, assets, messaging docs | BRAND |
| Conteúdo educacional, currículos | LEARN |
| Features, fixes, refactors | CODE |

---

## DECISION TREE

```
                    INTENT DO OPERADOR
                           │
           ┌───────────────┴───────────────┐
           │                               │
     É SOBRE CRIAR               É SOBRE ANALISAR
     ALGO NOVO?                  /OTIMIZAR ALGO?
           │                               │
     ┌─────┴─────┐               ┌─────────┴─────────┐
     │           │               │                   │
  SISTEMA?   CONTEÚDO?       DADOS?             PROCESSO?
     │           │               │                   │
     ▼           ▼               ▼                   ▼
┌─────────┐ ┌─────────┐    ┌─────────┐         ┌─────────┐
│ Meta?   │ │Persuade?│    │  DATA   │         │  PROD   │
└────┬────┘ └────┬────┘    └─────────┘         └─────────┘
     │           │
   ┌─┴─┐       ┌─┴─┐
   │   │       │   │
  SIM NÃO    SIM  NÃO
   │   │       │   │
   ▼   ▼       ▼   ▼
 META ARCH   COPY LEARN/BRAND/CODE
```

---

## NATURE PRIMÁRIA vs SECUNDÁRIA

Alguns projetos têm natureza mista. Nestes casos:

### Nature Primária
A natureza dominante que define o kit principal.

### Nature Secundária
Naturezas complementares que adicionam lentes extras.

**Exemplo:**
- Projeto: "Criar landing page para SaaS"
- Primária: COPY (objetivo é persuadir)
- Secundária: BRAND (precisa de consistência de marca)

**Ação:** Carregar kit COPY + adicionar lentes de BRAND

---

## EXEMPLOS PRÁTICOS

### Exemplo 1: "Quero melhorar minhas headlines"

**Análise:**
- Keywords: headlines ✓
- Objetivo: convencer ✓
- Artefato: texto persuasivo ✓

**Nature:** COPY (alta confiança)

---

### Exemplo 2: "Preciso arquitetar um sistema de notificações"

**Análise:**
- Keywords: arquitetar, sistema ✓
- Objetivo: construir sistema técnico ✓
- Artefato: código, diagramas ✓

**Nature:** ARCH (alta confiança)

---

### Exemplo 3: "Quero criar um framework para gerar Blueprints"

**Análise:**
- Keywords: framework, gerar ✓
- Objetivo: criar sistema que cria sistemas ✓
- Artefato: templates, protocolos ✓

**Nature:** META (alta confiança)

---

### Exemplo 4: "Criar curso sobre copywriting"

**Análise:**
- Keywords: curso ✓, copywriting
- Objetivo: ensinar ✓
- Artefato: conteúdo educacional ✓

**Nature:** LEARN (primária) + COPY (secundária)

---

## QUANDO NATURE É INCERTA

Se a detecção não for clara:

### Opção 1: Perguntar ao Operador

```
Detectei elementos de {NATURE_A} e {NATURE_B}.
Qual é o foco principal deste projeto?
- [ ] {descrição A}
- [ ] {descrição B}
```

### Opção 2: Começar Genérico

Usar lentes universais até clarificar:
- First Principles
- Inversion
- 80/20
- Second Order

### Opção 3: Multi-Kit

Se genuinamente misto, carregar kits múltiplos com prioridade:
1. Kit primário (full)
2. Kit secundário (lentes apenas)

---

## INTEGRAÇÃO COM P0: REFLECT

Durante P0, Nature Detection executa automaticamente:

```yaml
P0_REFLECT:
  step_1: "Analisar intent do operador"
  step_2: "Executar Nature Detection"
  step_3: "Carregar Cognitive Kit"
  step_4: "Montar Dream Team"
  step_5: "Identificar lentes relevantes"
  step_6: "Documentar no STATE"

  output:
    nature_detected: "{CODE}"
    confidence: 0.0-1.0
    kit_loaded: "{kit_name}"
    team_assembled: ["{persona_1}", "{persona_2}", ...]
    lenses_active: ["{lens_1}", "{lens_2}", ...]
```

---

## ATUALIZANDO DETECÇÃO

A nature pode ser reatualizada se:
- Novas informações emergem
- Operador clarifica intenção
- Scope muda significativamente

**Processo:**
1. Re-executar detecção
2. SE mudou: atualizar kit e team
3. Documentar mudança no STATE

---

*ATHENA OS 2.0 — Nature Detection*
*"Compreender a natureza é o primeiro passo para maestria."*
