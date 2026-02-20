# CONTEXT OPTIMIZATION — ATHENA OS 2.0

> **"Contexto é a moeda mais valiosa em trabalho com LLMs. Gaste com sabedoria."**

---

## O PROBLEMA

Sessões Claude Code têm contexto limitado. Cada:
- Arquivo lido
- Output gerado
- Decisão tomada
- Erro tratado

...consome esse recurso finito.

Gestão pobre de contexto = degradação de qualidade ou sessão truncada.

---

## PRINCÍPIOS DE GESTÃO

### 1. Just-in-Time Loading

**Não faça:** Carregar "tudo que pode precisar" no início
**Faça:** Carregar apenas quando necessário, no momento de uso

```
RUIM:
1. Ler 10 arquivos de config
2. Ler toda documentação
3. Começar a trabalhar (contexto já comprometido)

BOM:
1. Ler STATE.yaml (mínimo necessário)
2. Identificar primeira task
3. Carregar contexto específico da task
4. Completar task
5. Carregar próximo contexto quando precisar
```

---

### 2. Compactação Agressiva

Antes de prosseguir para próxima fase, compactar:
- Resumir decisões tomadas
- Descartar contexto não mais necessário
- Manter apenas essências

---

### 3. Delegação para Preservação

Spawnar agents preserva contexto principal:
- Agent tem seu próprio contexto
- Main session mantém capacidade
- Resultado volta compactado

---

### 4. Estrutura sobre Prosa

Informação estruturada é mais eficiente:

```
RUIM (verboso):
"O sistema usa PostgreSQL como banco de dados principal,
que está configurado no docker-compose.yaml..."

BOM (estruturado):
DB: PostgreSQL
Config: docker-compose.yaml
```

---

## ESTRATÉGIAS DE COMPACTAÇÃO

### Decisões Tomadas

**De:**
```
Analisei várias opções para o schema. Considerei MongoDB
por sua flexibilidade, PostgreSQL por sua robustez, e
SQLite por sua simplicidade. Após pesar prós e contras,
decidi usar PostgreSQL porque...
```

**Para:**
```
Decisão: PostgreSQL
Razão: Robustez + suporte a JSON
Alternativas consideradas: MongoDB, SQLite
```

---

### Análise de Arquivos

**De:** Arquivo completo de 500 linhas na memória

**Para:**
```
Arquivo: /path/to/file.ts
Resumo: Service de autenticação
Funções-chave: login(), logout(), refresh()
Dependências: jwt, bcrypt
Patterns: Repository pattern
```

---

### Erros e Troubleshooting

**De:** Stack trace completo + múltiplas tentativas documentadas

**Para:**
```
Erro: Connection timeout
Causa: Config incorreta de host
Fix: Ajustar DATABASE_HOST
```

---

## HIERARQUIA DE PRIORIDADE

Quando contexto está apertado, priorizar:

```
1. CRÍTICO - Manter sempre
   └── STATE.yaml atual
   └── Objetivo da sessão
   └── Decisões estruturais tomadas

2. IMPORTANTE - Manter se possível
   └── Context de tasks em progresso
   └── Referências de templates
   └── Constraints conhecidos

3. ÚTIL - Carregar quando necessário
   └── Exemplos
   └── Documentação detalhada
   └── Histórico de tentativas

4. DISPENSÁVEL - Descartar após uso
   └── Outputs intermediários
   └── Explorações abandonadas
   └── Contexto de tasks completadas
```

---

## HANDOFF PROTOCOL

Ao transferir para agent ou próxima sessão:

### Incluir (essencial):

```markdown
## CONTEXTO ESSENCIAL
- Objetivo: {uma frase}
- Estado atual: {onde estamos}
- Próximo passo: {o que fazer}

## DECISÕES TOMADAS
| Decisão | Razão |
|---------|-------|
| X       | Y     |

## CONSTRAINTS
- Não fazer: {lista}
- Manter: {lista}

## REFERÊNCIAS
- {arquivo}: {por que relevante}
```

### Não incluir:

- Histórico completo de exploração
- Tentativas falhas detalhadas
- Contexto de phases já completadas
- Documentação que pode ser relida

---

## SINAIS DE CONTEXTO COMPROMETIDO

### Observe se:

1. **Repetição** — Fazendo perguntas já respondidas
2. **Inconsistência** — Decisões contraditórias
3. **Perda de foco** — Tangenciando do objetivo
4. **Simplificação excessiva** — Outputs perdendo nuance

### Ações corretivas:

1. **Parar e resumir** — Consolidar estado atual
2. **Checkpoint** — Salvar progresso estruturado
3. **Handoff** — Transferir para nova sessão se necessário
4. **Priorizar** — Focar no mais importante

---

## TEMPLATE: CONTEXT SNAPSHOT

```markdown
# CONTEXT SNAPSHOT — {timestamp}

## OBJETIVO DA SESSÃO
{Uma frase clara}

## ESTADO ATUAL
- Phase: {P1/P2/P3/P4}
- Progresso: {X de Y tasks}
- Blockers: {lista ou "nenhum"}

## DECISÕES ESTRUTURAIS
1. {Decisão}: {Razão}
2. {Decisão}: {Razão}

## PRÓXIMAS AÇÕES
1. [ ] {ação}
2. [ ] {ação}

## CONTEXTO ATIVO
- {arquivo/conceito}: {por que relevante}

## DESCARTADO
- {o que não é mais necessário}
```

---

## MÉTRICAS DE SAÚDE

### Monitorar:

| Métrica | Saudável | Atenção | Crítico |
|---------|----------|---------|---------|
| Arquivos carregados | < 5 | 5-10 | > 10 |
| Tamanho de outputs | Compacto | Moderado | Verboso |
| Repetições | 0 | 1-2 | > 2 |
| Decisões consistentes | 100% | > 90% | < 90% |

---

*ATHENA OS 2.0 — Context Optimization*
*"Menos contexto carregado = mais qualidade no que importa."*
