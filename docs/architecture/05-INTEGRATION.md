# ATHENA OS — GUIA DE INTEGRAÇÃO COM PROJETOS

> Como Conectar ATHENA OS aos Seus Sistemas Claude Code Native

**Versão:** 1.0.0
**Dependências:** Todos os documentos anteriores

---

## Visão Geral da Integração

ATHENA OS opera como uma **camada 0** — ela não executa dentro dos projetos, ela gera os artefatos que guiam a execução.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ATHENA OS                                   │
│                    (Projeto Standalone)                             │
│                                                                     │
│   ┌───────────┐    ┌───────────┐    ┌───────────┐                 │
│   │  DECODE   │───►│ ARCHITECT │───►│CRYSTALLIZE│                 │
│   └───────────┘    └───────────┘    └─────┬─────┘                 │
│                                           │                        │
│                                           ▼                        │
│                                    ┌─────────────┐                 │
│                                    │  BLUEPRINT  │                 │
│                                    │  ACTIVATION │                 │
│                                    └──────┬──────┘                 │
│                                           │                        │
└───────────────────────────────────────────┼────────────────────────┘
                                            │
                    ┌───────────────────────┼───────────────────────┐
                    │                       │                       │
                    ▼                       ▼                       ▼
         ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
         │   AD ANATOMY     │   │     FUNNEL       │   │     GENESIS      │
         │     ENGINE       │   │    ARCHITECT     │   │                  │
         │                  │   │                  │   │                  │
         │  ┌────────────┐  │   │  ┌────────────┐  │   │  ┌────────────┐  │
         │  │.athena/    │  │   │  │.athena/    │  │   │  │.athena/    │  │
         │  │blueprints/ │  │   │  │blueprints/ │  │   │  │blueprints/ │  │
         │  └────────────┘  │   │  └────────────┘  │   │  └────────────┘  │
         │                  │   │                  │   │                  │
         └──────────────────┘   └──────────────────┘   └──────────────────┘
```

---

## Métodos de Integração

### Método 1: Exportação Manual (Recomendado para Início)

**Fluxo:**
1. Gerar Blueprint no ATHENA OS
2. Copiar arquivos para projeto-alvo
3. Colar Activation Prompt
4. Executar

**Quando usar:** Projetos ocasionais, aprendizado do sistema

### Método 2: Exportação Automatizada

**Fluxo:**
1. Gerar Blueprint
2. Executar `/ATHENA:tasks:export-to-project {path}`
3. Arquivos copiados automaticamente
4. Abrir projeto-alvo e executar

**Quando usar:** Projetos frequentes, fluxo estabelecido

### Método 3: Integração Nativa (Avançado)

**Fluxo:**
1. Configurar integração em `integrations/{projeto}.yaml`
2. ATHENA gera e exporta automaticamente
3. Projeto-alvo detecta novos Blueprints
4. Execução pode iniciar automaticamente

**Quando usar:** Sistemas maduros, alta frequência

---

## Configuração de Projeto-Alvo

### Passo 1: Criar Estrutura .athena

No projeto-alvo, criar:

```
{projeto}/
├── .athena/
│   ├── config.yaml           # Configuração de integração
│   ├── blueprints/           # Blueprints ativos
│   │   └── .gitkeep
│   └── history/              # Blueprints concluídos
│       └── .gitkeep
└── ... (resto do projeto)
```

### Passo 2: Criar config.yaml

```yaml
# .athena/config.yaml
# Configuração de integração ATHENA OS

# ─────────────────────────────────────────────────────────────────────
# IDENTIFICAÇÃO
# ─────────────────────────────────────────────────────────────────────
project:
  name: "Nome do Projeto"
  slug: "slug-do-projeto"
  type: "ANALYSIS | CREATION | ORCHESTRATION"
  
# ─────────────────────────────────────────────────────────────────────
# ATHENA OS CONNECTION
# ─────────────────────────────────────────────────────────────────────
athena:
  # Path para instalação do ATHENA OS
  path: "D:/athena-os"
  
  # Auto-detectar novos blueprints?
  auto_detect: false
  
  # Notificar quando blueprint chegar?
  notifications: true

# ─────────────────────────────────────────────────────────────────────
# TAXONOMIA LOCAL
# ─────────────────────────────────────────────────────────────────────
taxonomy:
  # Onde blueprints ativos ficam
  blueprints_path: ".athena/blueprints"
  
  # Onde blueprints concluídos vão
  history_path: ".athena/history"
  
  # Estrutura de outputs do projeto
  outputs:
    primary: "outputs/"
    temp: "temp/"
    logs: "logs/"

# ─────────────────────────────────────────────────────────────────────
# STATE INTEGRATION
# ─────────────────────────────────────────────────────────────────────
state:
  # Este projeto tem STATE.yaml próprio?
  has_local_state: true
  
  # Sincronizar com ATHENA OS?
  sync_with_athena: false
  
  # Path do STATE local
  state_file: "STATE.yaml"

# ─────────────────────────────────────────────────────────────────────
# HOOKS (Avançado)
# ─────────────────────────────────────────────────────────────────────
hooks:
  on_blueprint_received: null
  on_execution_start: null
  on_checkpoint: null
  on_completion: null
```

### Passo 3: Registrar no ATHENA OS

```yaml
# athena-os/integrations/{projeto}.yaml

integration:
  project_name: "Nome do Projeto"
  project_path: "D:/{path-do-projeto}"
  project_slug: "slug-do-projeto"
  
  # Status da integração
  status: "ACTIVE | INACTIVE | DEPRECATED"
  
  # Última sincronização
  last_sync: null
  
  # Blueprints enviados
  blueprints_sent:
    - id: "BP-2025-01-16-001"
      sent_at: "2025-01-16T14:30:00-03:00"
      status: "PENDING | EXECUTING | COMPLETED"
```

---

## Fluxo de Exportação Detalhado

### Usando o Comando de Exportação

```
/ATHENA:tasks:export-to-project {path-do-projeto}
```

**O que acontece:**

1. **Validação**
   - Verifica se Blueprint está completo (Gate G4 PASS)
   - Verifica se projeto-alvo existe
   - Verifica se `.athena/` existe no alvo

2. **Cópia de Arquivos**
   ```
   athena-os/outputs/blueprints/{date}/{slug}/
     └── * (todos os arquivos)
           │
           ▼
   {projeto}/.athena/blueprints/{slug}/
     └── * (arquivos copiados)
   ```

3. **Atualização de States**
   - Atualiza ATHENA OS STATE (blueprint exportado)
   - Cria/atualiza metadata no projeto-alvo

4. **Geração de Activation Prompt Ajustado**
   - Paths ajustados para o projeto-alvo
   - Referências corrigidas

---

## Recebendo um Blueprint no Projeto-Alvo

### Passo 1: Verificar Chegada

```bash
# No projeto-alvo
ls .athena/blueprints/
```

### Passo 2: Ler o Activation Prompt

```bash
cat .athena/blueprints/{slug}/ACTIVATION.md
```

### Passo 3: Executar

O Activation Prompt contém:
- Contexto completo
- Referência ao Blueprint
- Primeiro comando
- Regras de execução

**Basta colar o conteúdo do ACTIVATION.md no Claude Code.**

---

## Integração com Sistemas Específicos

### AD Anatomy Engine

```yaml
# integrations/ad-anatomy-engine.yaml

integration:
  project_name: "AD Anatomy Engine"
  project_path: "D:/ad-anatomy-engine"
  project_slug: "ad-anatomy"
  
  # Tipos de Blueprint relevantes
  relevant_blueprint_types:
    - "ANALYSIS"      # Análises de ads
    - "CREATION"      # Novos frameworks de análise
    - "ORCHESTRATION" # Orquestração de agents
    
  # Mapeamento de outputs
  output_mapping:
    analysis_results: "library/by-niche/"
    new_agents: "agents/"
    new_workflows: "workflows/"
    
  # Integração com STATE.yaml do AD Anatomy
  state_mapping:
    athena_checkpoint: "external.athena.last_checkpoint"
    athena_blueprint: "external.athena.active_blueprint"
```

### FUNNEL ARCHITECT

```yaml
# integrations/funnel-architect.yaml

integration:
  project_name: "FUNNEL ARCHITECT"
  project_path: "D:/funnel-architect"
  project_slug: "funnel-architect"
  
  relevant_blueprint_types:
    - "CREATION"      # Novos funis
    - "ORCHESTRATION" # Fluxos complexos
    
  output_mapping:
    funnels: "outputs/funnels/"
    sequences: "outputs/sequences/"
```

### GENESIS

```yaml
# integrations/genesis.yaml

integration:
  project_name: "GENESIS"
  project_path: "D:/genesis-meta-system"
  project_slug: "genesis"
  
  # GENESIS é especial - pode receber Blueprints
  # para gerar novos SISTEMAS, não apenas executar tarefas
  special_mode: "meta-generation"
  
  relevant_blueprint_types:
    - "SYSTEM_DESIGN" # Blueprints para criar sistemas
```

---

## Sincronização de Estado

### Estado no ATHENA OS

```yaml
# athena-os/STATE.yaml (trecho)

integrations:
  ad-anatomy:
    last_export: "2025-01-16T14:30:00-03:00"
    last_blueprint: "BP-2025-01-16-001"
    status: "EXPORTED"
    
  funnel-architect:
    last_export: null
    last_blueprint: null
    status: "IDLE"
```

### Estado no Projeto-Alvo

```yaml
# {projeto}/.athena/state-log.yaml

blueprints_received:
  - id: "BP-2025-01-16-001"
    received_at: "2025-01-16T14:35:00-03:00"
    status: "EXECUTING | COMPLETED | FAILED"
    checkpoints_completed: 3
    total_checkpoints: 7
    last_update: "2025-01-16T15:00:00-03:00"
```

---

## Feedback Loop

### Reportando Conclusão para ATHENA OS

Quando um Blueprint é concluído no projeto-alvo:

1. **Atualizar estado local**
   ```yaml
   # .athena/state-log.yaml
   blueprints_received:
     - id: "BP-2025-01-16-001"
       status: "COMPLETED"
       completed_at: "2025-01-16T16:00:00-03:00"
   ```

2. **Mover para histórico**
   ```
   .athena/blueprints/{slug}/ → .athena/history/{YYYY-MM}/{slug}/
   ```

3. **(Opcional) Notificar ATHENA OS**
   - Atualizar métricas
   - Alimentar aprendizado

---

## Troubleshooting

### Blueprint não aparece no projeto-alvo

**Verificar:**
1. Exportação foi executada? (`/ATHENA:tasks:export-to-project`)
2. Path do projeto está correto?
3. Pasta `.athena/blueprints/` existe?
4. Permissões de escrita?

### Activation Prompt tem paths errados

**Causa:** Exportação não ajustou paths

**Solução:** Re-executar exportação ou ajustar manualmente os paths no ACTIVATION.md

### STATE não sincroniza

**Verificar:**
1. `sync_with_athena: true` no config?
2. Ambos os projetos têm STATE.yaml válido?
3. Paths estão corretos?

---

## Boas Práticas

### ✅ Fazer

- Sempre ler o Blueprint COMPLETO antes de executar
- Atualizar STATE a cada checkpoint
- Mover Blueprints concluídos para history
- Manter `.athena/config.yaml` atualizado

### ❌ Evitar

- Executar sem ler o Activation Prompt
- Modificar Blueprints sem documentar
- Acumular Blueprints não executados
- Ignorar a estrutura de pastas

---

## Próximos Passos

Após configurar a integração:

1. **Testar** com um Blueprint simples
2. **Validar** que o fluxo funciona end-to-end
3. **Documentar** customizações específicas do projeto
4. **Iterar** conforme necessário

---

*"Integração é onde a teoria encontra a prática." — ATHENA*
