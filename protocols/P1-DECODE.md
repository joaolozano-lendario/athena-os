# P1: PROTOCOLO DE DECODIFICACAO

> Extrair a intencao real por tras das palavras do operador

**Versao:** 1.0.0
**Gate de Saida:** G1 - A intencao esta inequivocamente clara?
**Referencia:** docs/architecture/02-PROTOCOLS.md

---

## Objetivo

Transformar uma intencao bruta (texto livre, ideia vaga, pedido confuso) em uma **Intent Specification** estruturada que elimina toda ambiguidade sobre o que deve ser feito.

---

## Entrada

- Descricao livre do operador
- Contexto do projeto (se houver)
- Referencias a trabalhos anteriores (se houver)

---

## Saida

- `intent-spec.yaml` completo e validado
- Gate G1 PASSED

---

## Processo de Execucao

### Passo 1.1: Captura Bruta

Receber a intencao do operador exatamente como ela vier:

```
SOLICITAR:
"Descreva o que voce quer fazer. Pode ser uma ideia vaga,
um problema, uma necessidade - eu vou extrair a estrutura."
```

**Regra:** Nao interpretar ainda. Apenas capturar.

### Passo 1.2: Extracao de Dimensoes

Extrair sistematicamente as seguintes dimensoes:

```yaml
dimensions:
  WHAT:
    explicit: "O que foi pedido literalmente"
    implicit: "O que provavelmente e necessario mas nao foi dito"
    out_of_scope: "O que definitivamente NAO esta incluido"

  WHY:
    surface: "A razao aparente"
    deep: "A motivacao real por tras (5 Porques)"
    impact_if_not_done: "O que acontece se NAO for feito"

  WHO:
    operator: "Quem vai executar (humano, Claude, sistema)"
    beneficiary: "Quem se beneficia do resultado"
    stakeholders: "Quem mais e afetado"

  WHERE:
    target_project: "Em qual projeto/sistema isso sera executado"
    target_path: "Onde especificamente no projeto"

  WHEN:
    urgency: "LOW | MEDIUM | HIGH | CRITICAL"
    deadline: "Se houver"
    dependencies: "O que precisa estar pronto antes"

  HOW:
    constraints: "Limitacoes tecnicas, de tempo, de recursos"
    preferences: "Preferencias do operador (formato, estilo, etc.)"
    anti_patterns: "O que definitivamente NAO fazer"
```

### Passo 1.3: Identificacao do JTBD (Job To Be Done)

Formular o "trabalho a ser feito" no formato:

```
"Quando [SITUACAO], eu quero [MOTIVACAO], para que [RESULTADO ESPERADO]."
```

**Exemplo:**
```
"Quando recebo dados brutos de pesquisas do Tally, eu quero um framework
que orquestre a analise completa, para que eu extraia insights acionaveis
sem ter que reexplicar o contexto a cada sessao."
```

### Passo 1.4: Definicao de Sucesso

Estabelecer criterios binarios de sucesso:

```yaml
success_criteria:
  must_have:
    - criterion: "Criterio 1 que DEVE ser atendido"
      measurement: "Como medir (binario)"
  should_have:
    - criterion: "Criterio desejavel mas nao obrigatorio"
      measurement: ""
  must_not:
    - "Isso NAO pode acontecer"
```

### Passo 1.5: Compilacao da Intent Specification

Consolidar tudo usando o template: `templates/blueprints/INTENT-SPEC.yaml`

---

## Gate G1: Validacao de Intent

**Pergunta Central:** A intencao esta inequivocamente clara?

### Checklist de Validacao

| Criterio | Peso | Verificacao |
|----------|------|-------------|
| JTBD esta formulado? | CRITICO | O Job To Be Done esta claro e especifico? |
| Sucesso e mensuravel? | CRITICO | Os criterios de sucesso sao binarios (sim/nao)? |
| Escopo esta fechado? | ALTO | Esta claro o que esta FORA do escopo? |
| Projeto-alvo definido? | ALTO | Sabemos onde isso sera executado? |
| Anti-patterns listados? | MEDIO | Sabemos o que NAO fazer? |

### Regra de Passagem

- Todos os criterios CRITICO devem ser atendidos
- Todos os criterios ALTO devem ser atendidos
- Criterios MEDIO sao desejaveis

### Se Falhar

1. Identificar quais criterios falharam
2. Formular perguntas especificas para o operador
3. Coletar respostas
4. Atualizar Intent Specification
5. Re-executar Gate G1

---

## Tecnicas de Elicitacao

### 5 Porques

Para chegar a motivacao real:

```
1. Por que voce quer isso?
   -> Resposta 1

2. Por que isso e importante?
   -> Resposta 2

3. Por que [Resposta 2]?
   -> Resposta 3

4. Por que [Resposta 3]?
   -> Resposta 4

5. Por que [Resposta 4]?
   -> MOTIVACAO RAIZ
```

### Perguntas de Clarificacao

```
- "O que acontece se isso NAO for feito?"
- "Quem mais seria afetado por isso?"
- "Ja tentou fazer isso antes? O que aconteceu?"
- "Qual e o minimo viavel que resolveria o problema?"
- "O que definitivamente NAO deve acontecer?"
```

### Deteccao de Ambiguidade

Sinais de que precisa clarificar:

- Palavras vagas: "melhorar", "otimizar", "bom"
- Escopo infinito: "tudo", "sempre", "todos"
- Referencias incompletas: "aquilo", "o sistema", "a coisa"
- Criterios subjetivos: "bonito", "rapido", "facil"

---

## Output Template

Ver: `templates/blueprints/INTENT-SPEC.yaml`

---

## Erros Comuns

| Erro | Consequencia | Prevencao |
|------|--------------|-----------|
| Aceitar ambiguidade | P2 vai falhar | Perguntar ate clarificar |
| Pular JTBD | Escopo vai estourar | Sempre formular JTBD |
| Criterios vagos | Nunca vai "terminar" | Forcar criterios binarios |
| Ignorar anti-patterns | Retrabalho | Sempre perguntar o que NAO fazer |

---

## Checklist Final

Antes de passar para P2:

- [ ] Intent Specification esta completa
- [ ] JTBD formulado no formato padrao
- [ ] Criterios de sucesso sao binarios
- [ ] Escopo esta fechado (inclui OUT_OF_SCOPE)
- [ ] Projeto-alvo esta definido
- [ ] Gate G1 PASSED
- [ ] STATE.yaml atualizado

---

*"Uma intencao bem decodificada e metade do trabalho feito." - ATHENA*
