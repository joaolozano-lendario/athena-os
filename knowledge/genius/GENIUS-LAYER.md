# GENIUS LAYER — ATHENA OS 2.0

> **"Não basta ter ferramentas certas. É preciso ter as perspectivas certas."**

---

## VISÃO

A Genius Layer é a camada de inteligência contextual que permeia todo o ATHENA OS 2.0. Ela garante que cada projeto seja abordado com:

- **Lentes específicas** que revelam o invisível no domínio
- **Dream team** de perspectivas complementares
- **Anti-patterns** específicos do domínio a evitar
- **Padrões de excelência** do campo a aplicar

---

## CONCEITO CENTRAL

### Nature → Kit → Team → Lenses

```
┌─────────────────────────────────────────────────────────────────┐
│                      INTENT DO OPERADOR                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     NATURE DETECTION                            │
│  "De que natureza é este projeto?"                              │
│  COPY | ARCH | META | DATA | PROD | BRAND | LEARN | CODE        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     COGNITIVE KIT                               │
│  Kit específico do domínio detectado                            │
│  - Dream Team (personas)                                        │
│  - Domain Lenses                                                │
│  - Anti-patterns                                                │
│  - Quality Gates                                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     DREAM TEAM ASSEMBLY                         │
│  Personas ativadas para esta execução                           │
│  Cada persona traz lentes e questionamentos únicos              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     LENS APPLICATION                            │
│  Lentes universais + lentes de domínio                          │
│  Aplicadas em cada fase do pipeline                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## NATURE CODES

| Code | Domínio | Indicadores |
|------|---------|-------------|
| **COPY** | Copywriting, persuasão, vendas | Headlines, CTAs, landing pages, emails |
| **ARCH** | Arquitetura de sistemas | APIs, microservices, databases, infra |
| **META** | Meta-sistemas, frameworks | Sistemas que geram sistemas, abstrações |
| **DATA** | Análise, insights, pesquisa | Dashboards, relatórios, data science |
| **PROD** | Produtividade, workflows | Automação, processos, ferramentas |
| **BRAND** | Branding, posicionamento | Identidade, messaging, diferenciação |
| **LEARN** | Educação, cursos | Conteúdo educacional, treinamentos |
| **CODE** | Desenvolvimento | Features, bugs, refactoring |

---

## COGNITIVE KITS

Cada nature code tem um **Cognitive Kit** associado:

```yaml
cognitive_kit:
  nature: "{CODE}"

  dream_team:
    # Personas que compõem o time ideal
    - role: "{papel}"
      persona: "{nome}"
      focus: "{foco}"

  domain_lenses:
    # Lentes específicas do domínio
    - name: "{nome}"
      question: "{pergunta poderosa}"

  anti_patterns:
    # O que evitar neste domínio
    - pattern: "{nome}"
      description: "{o que é}"
      detection: "{como detectar}"

  quality_gates:
    # Critérios específicos de qualidade
    - gate: "{nome}"
      criterion: "{o que validar}"
```

---

## DREAM TEAM

O Dream Team é o conjunto de personas ativadas para um projeto específico. Funciona como um **conselho consultivo cognitivo**.

### Como Funciona

1. **Detection:** Nature é identificada
2. **Assembly:** Kit carrega team default
3. **Customization:** Operador pode ajustar
4. **Activation:** Personas ficam "ativas" durante execução

### Modos de Uso

#### Modo Consulta
Invocar uma persona específica para perspectiva:

```
"Como {PERSONA} veria isso?"
"O que {PERSONA} diria sobre esta abordagem?"
```

#### Modo Tribunal
Múltiplas personas avaliam sequencialmente:

```
1. {PERSONA_1} avalia → feedback
2. {PERSONA_2} avalia → feedback
3. {PERSONA_3} avalia → feedback
4. Síntese dos feedbacks
```

#### Modo Debate
Personas com perspectivas opostas dialogam:

```
{PERSONA_A}: Argumento a favor
{PERSONA_B}: Contra-argumento
{PERSONA_A}: Resposta
...
Síntese: O que aprendemos do debate
```

---

## LENSES

### Lentes Universais

Aplicáveis a qualquer domínio:

| Lente | Pergunta Central |
|-------|------------------|
| **First Principles** | "Quais são as verdades fundamentais aqui?" |
| **Inversion** | "O que acontece se penso ao contrário?" |
| **80/20** | "Quais 20% geram 80% do valor?" |
| **Second Order** | "Quais os efeitos de segunda ordem?" |

### Lentes de Domínio

Específicas para cada nature code. Ver arquivos em `lenses/domain-specific/`.

---

## INTEGRAÇÃO COM PIPELINE

### P0: REFLECT
- Nature Detection executada
- Cognitive Kit carregado
- Dream Team assembled
- Lentes relevantes identificadas

### P1: DECODE
- Dream Team valida interpretação de intenção
- Lentes aplicadas para descobrir requisitos ocultos

### P2: ARCHITECT
- Personas técnicas dominam
- Lentes arquiteturais aplicadas

### P3: FRAGMENT
- Validação de completude por múltiplas perspectivas

### P4: CRYSTALLIZE
- Tribunal final antes de entregar
- Quality gates de domínio verificados

### P5: LEARN
- Capturar lentes que funcionaram
- Documentar anti-patterns encontrados

---

## ANTI-PATTERNS DA GENIUS LAYER

### 1. Persona Stuffing
**O que é:** Ativar todas as personas disponíveis
**Problema:** Noise > signal, perspectivas conflitantes demais
**Solução:** 3-5 personas máximo por execução

### 2. Lens Paralysis
**O que é:** Aplicar lentes demais, análise infinita
**Problema:** Paralisia por análise
**Solução:** 2-3 lentes principais por fase

### 3. Domain Blindness
**O que é:** Ignorar nature detection, usar kit genérico
**Problema:** Perspectivas inadequadas, oportunidades perdidas
**Solução:** Sempre detectar nature, carregar kit específico

### 4. Tribunal Theater
**O que é:** Fazer tribunal para impressionar, não para melhorar
**Problema:** Tempo gasto sem valor agregado
**Solução:** Tribunal só quando qualidade é crítica

---

## ATIVAÇÃO

### Automática (via P0)

```yaml
# No início de forge-blueprint
1. Analisar intent do operador
2. Detectar nature code
3. Carregar cognitive kit
4. Montar dream team
5. Prosseguir com camada ativa
```

### Manual (operador decide)

```yaml
# Operador especifica
genius:
  nature: "COPY"
  override_team: ["schwartz", "halbert"]
  extra_lenses: ["awareness-levels"]
```

---

## ESTRUTURA DE ARQUIVOS

```
knowledge/genius/
├── GENIUS-LAYER.md          # Este documento
├── NATURE-DETECTION.md      # Como detectar natureza
├── kits/                    # Cognitive kits
│   ├── COPY.yaml
│   ├── ARCH.yaml
│   ├── META.yaml
│   ├── DATA.yaml
│   ├── PROD.yaml
│   ├── BRAND.yaml
│   ├── LEARN.yaml
│   └── CODE.yaml
├── personas/                # Definições de personas
│   ├── copywriting/
│   ├── architecture/
│   └── meta/
└── lenses/                  # Lentes cognitivas
    ├── universal/
    └── domain-specific/
```

---

*ATHENA OS 2.0 — Genius Layer*
*"Perspectivas certas revelam verdades ocultas."*
