# ACTIVATION PROMPT
# {TITULO DO PROJETO}

---

## CONTEXTO

Este prompt ativa a execucao de um Blueprint gerado pelo ATHENA OS.

| Campo | Valor |
|-------|-------|
| **Operador** | {nome} |
| **Projeto** | {nome do projeto} |
| **Blueprint ID** | {BP-YYYY-MM-DD-NNN} |
| **Gerado em** | {timestamp} |

---

## BLUEPRINT

O Blueprint completo esta localizado em:

```
{caminho/completo/para/BLUEPRINT.md}
```

### Acao Obrigatoria

**LEIA O BLUEPRINT COMPLETO** antes de executar qualquer coisa.

Secoes criticas:
1. Sumario Executivo (entender o objetivo)
2. Checkpoint Map (entender as tasks)
3. Guia de Execucao (entender o fluxo)

---

## INSTRUCOES DE EXECUCAO

### Passo 1: Preparacao

```bash
# Verificar estado atual
cat STATE.yaml

# Verificar pre-requisitos (secao 6.1 do Blueprint)
```

### Passo 2: Iniciar Execucao

```
# Primeiro comando sugerido:
{comando inicial}
```

### Passo 3: Durante Execucao

- Seguir a sequencia de tasks do Checkpoint Map
- Marcar cada task como DONE ao completar
- Atualizar STATE.yaml em cada checkpoint

### Passo 4: Finalizacao

- Verificar todos os criterios de sucesso (secao 7)
- Atualizar STATE.yaml com status COMPLETED
- Reportar conclusao

---

## REGRAS INVIOLAVEIS

1. **NAO** pular etapas
2. **NAO** ignorar checkpoints
3. **NAO** alterar outputs sem atualizar STATE
4. **SEMPRE** atualizar STATE apos cada task
5. **SEMPRE** parar e reportar se encontrar bloqueio

---

## PRIMEIRO COMANDO

Execute isto para iniciar:

```
{comando detalhado para iniciar a execucao}
```

---

## EM CASO DE BLOQUEIO

1. Documentar o bloqueio no STATE.yaml
2. Identificar a causa raiz
3. Consultar o Blueprint secao relevante
4. Se nao resolver: reportar para ATHENA OS

---

## REFERENCIAS RAPIDAS

| Documento | Localizacao |
|-----------|-------------|
| Blueprint | `{path}` |
| STATE | `{path}` |
| Checkpoint Map | Secao 4 do Blueprint |
| Criterios de Sucesso | Secao 7 do Blueprint |

---

*Activation Prompt gerado por ATHENA OS v1.0*
