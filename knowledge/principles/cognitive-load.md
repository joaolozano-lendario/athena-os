# Principio: Cognitive Load Management

> Minimizar a carga cognitiva do executor para maximizar eficacia

**Versao:** 1.0.0
**Principio ATHENA:** P1 (Contexto e Rei)

---

## Conceito Central

**Cognitive Load** e a quantidade de esforco mental necessario para processar informacao e tomar decisoes. Um Blueprint bem projetado minimiza essa carga, permitindo que o executor foque na execucao, nao na interpretacao.

---

## Tipos de Carga Cognitiva

### 1. Carga Intrinseca (Inevitavel)

A complexidade inerente a tarefa em si.

**Estrategia:** Fragmentar em unidades menores (P2 - Fragmentacao Obsessiva)

```
Tarefa complexa -> Epicos -> Stories -> Tasks atomicas
```

### 2. Carga Extrinseca (Evitavel)

Complexidade adicionada por documentacao ruim.

**Estrategia:** Estrutura clara, referencias precisas, zero ambiguidade

```
Ruim: "Fazer a coisa do sistema"
Bom:  "Executar T-1.2.3: Criar schema do banco (ver BLUEPRINT.md secao 3.2)"
```

### 3. Carga Germane (Desejavel)

Esforco para construir entendimento duradouro.

**Estrategia:** Contexto suficiente, conexoes explicitas, padroes reconheciveis

```
"Esta fase usa o padrao Preparar-Executar-Validar (ver knowledge/patterns/)"
```

---

## Tecnicas de Reducao

### 1. Chunking (Fragmentacao)

Agrupar informacoes relacionadas em "chunks" gerenciaveis.

**Aplicacao em ATHENA:**
- Limite de 7 +/- 2 items por lista
- Stories agrupam tasks relacionadas
- Epicos agrupam stories de uma fase

### 2. Progressive Disclosure

Revelar informacao conforme necessidade.

**Aplicacao em ATHENA:**
- Piramide invertida (sumario -> detalhes)
- Links para aprofundamento
- Niveis de leitura (scan -> read -> deep dive)

### 3. Consistent Patterns

Usar estruturas repetitivas e previsiveis.

**Aplicacao em ATHENA:**
- Todos os templates seguem mesmo formato
- IDs com padrao previsivel
- Gates sempre tem mesma estrutura

### 4. External Memory

Descarregar memoria para documentos.

**Aplicacao em ATHENA:**
- STATE.yaml como memoria persistente
- Checkpoint Map como trilha de progresso
- Referencias cruzadas para contexto

---

## Metricas de Carga Cognitiva

### Sinais de Carga Alta

- Executor pergunta "o que isso significa?"
- Executor precisa reler varias vezes
- Executor pula secoes e volta
- Executor comete erros por confusao
- Executor paralisa (decision fatigue)

### Sinais de Carga Otimizada

- Executor entende na primeira leitura
- Executor sabe exatamente o proximo passo
- Executor encontra informacao rapidamente
- Executor executa sem re-perguntar

---

## Regras de Ouro

### 1. Uma Coisa Por Vez

```
Cada task = uma acao
Cada secao = um topico
Cada gate = uma pergunta
```

### 2. Contexto Antes de Conteudo

```
"Esta fase analisa os dados coletados na fase anterior."
[Conteudo da fase]
```

### 3. Explicito Supera Implicito

```
Ruim: "Seguir o processo normal"
Bom:  "Executar steps 1-5 conforme BLUEPRINT secao 6.3"
```

### 4. Visual Primeiro

```
Diagrama -> Tabela -> Lista -> Paragrafo
(ordem de preferencia para clareza)
```

### 5. Exemplos Concretos

```
Para cada conceito abstrato, incluir:
- Exemplo BOM
- Exemplo RUIM
```

---

## Aplicacao Pratica

### Ao Escrever Blueprint

1. Perguntar: "Alguem sem contexto entenderia?"
2. Testar: Ler como se fosse a primeira vez
3. Simplificar: Cortar o desnecessario
4. Estruturar: Usar headers, listas, tabelas
5. Referenciar: Conectar partes relacionadas

### Ao Definir Tasks

1. Uma acao por task
2. Criterio binario (sim/nao)
3. Duracao < 2 horas
4. Dependencias explicitas
5. Resultado verificavel

### Ao Criar Gates

1. Uma pergunta clara
2. Criterios objetivos
3. Acao definida se falhar
4. Sem ambiguidade

---

## Anti-Patterns de Carga Cognitiva

| Anti-Pattern | Problema | Solucao |
|--------------|----------|---------|
| Wall of Text | Dificil de processar | Estruturar com headers/listas |
| Acronimo Hell | "Execute o PRD via API do CRM" | Definir termos no primeiro uso |
| Hidden Dependencies | Task falha por falta de contexto | Explicitar pre-requisitos |
| Decision Overload | Muitas opcoes sem guia | Recomendar default, ordenar por frequencia |
| Context Switching | Pular entre documentos | Incluir informacao inline quando possivel |

---

## Conclusao

Um Blueprint que minimiza carga cognitiva:

- **Acelera** a execucao
- **Reduz** erros por confusao
- **Aumenta** satisfacao do executor
- **Garante** transferibilidade

> "A complexidade da tarefa e inevitavel. A complexidade da documentacao e escolha."

---

*"Se voce nao consegue explicar de forma simples, voce nao entendeu bem o suficiente." - Einstein*
*"E se voce entendeu, documente de forma simples." - ATHENA*
