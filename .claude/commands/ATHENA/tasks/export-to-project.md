# /ATHENA:tasks:export-to-project

> Exportar Blueprint para um projeto-alvo

---

## Descrição

Copia um Blueprint completo para o projeto-alvo, criando a estrutura `.athena/` necessária e ajustando os paths no Activation Prompt.

---

## Uso

```bash
/ATHENA:tasks:export-to-project {path-do-projeto}
```

Ou:
```bash
/ATHENA:tasks:export-to-project {path-do-projeto} --blueprint={blueprint-id}
```

---

## Fluxo

```
INPUT: Path do projeto + Blueprint ID (opcional)
   │
   ▼
VALIDAÇÃO
   ├── Projeto existe?
   ├── Blueprint está completo (G4 PASS)?
   └── Permissões de escrita?
   │
   ▼
PREPARAÇÃO DO DESTINO
   ├── Criar .athena/ se não existe
   ├── Criar .athena/blueprints/
   └── Criar .athena/config.yaml se não existe
   │
   ▼
CÓPIA DE ARQUIVOS
   └── outputs/blueprints/{date}/{slug}/*
       ──► {projeto}/.athena/blueprints/{slug}/*
   │
   ▼
AJUSTE DE PATHS
   └── ACTIVATION.md: paths ajustados para projeto-alvo
   │
   ▼
ATUALIZAÇÃO DE STATES
   ├── ATHENA OS: marcar como exportado
   └── Projeto: criar/atualizar state-log.yaml
   │
   ▼
OUTPUT: Confirmação + próximos passos
```

---

## Estrutura Criada no Projeto-Alvo

```
{projeto}/
├── .athena/
│   ├── config.yaml              # Criado se não existe
│   ├── blueprints/
│   │   └── {slug}/
│   │       ├── BLUEPRINT.md     # Copiado
│   │       ├── ACTIVATION.md    # Copiado + paths ajustados
│   │       └── *.yaml           # Todos os artefatos
│   └── state-log.yaml           # Criado/atualizado
└── ...
```

---

## Instruções para ATHENA

1. **Validar argumentos**
   - Path do projeto existe?
   - Blueprint especificado ou usar último?

2. **Validar Blueprint**
   - Carregar _metadata.yaml
   - Verificar Gate G4 = PASSED
   - Se não passou, sugerir `/ATHENA:tasks:validate-blueprint`

3. **Preparar destino**
   ```bash
   mkdir -p {projeto}/.athena/blueprints/{slug}
   ```
   
4. **Criar config.yaml se necessário**
   ```yaml
   # .athena/config.yaml
   project:
     name: "{nome do projeto}"
     slug: "{slug}"
   athena:
     path: "D:/athena-os"
   ```

5. **Copiar arquivos**
   - Copiar todos os arquivos do Blueprint
   - Ajustar ACTIVATION.md com paths corretos

6. **Atualizar states**
   
   ATHENA OS STATE.yaml:
   ```yaml
   blueprints:
     recent:
       - id: "BP-..."
         status: "EXPORTED"
         exported_at: "{timestamp}"
         exported_to: "{path}"
   ```
   
   Projeto state-log.yaml:
   ```yaml
   blueprints_received:
     - id: "BP-..."
       received_at: "{timestamp}"
       status: "PENDING"
   ```

7. **Mostrar resultado**
   ```
   ✓ Blueprint exportado com sucesso!
   
   Localização: {projeto}/.athena/blueprints/{slug}/
   
   Próximos passos:
   1. Abrir o projeto: cd {projeto}
   2. Ler o Activation Prompt: cat .athena/blueprints/{slug}/ACTIVATION.md
   3. Colar o conteúdo no Claude Code
   4. Executar!
   ```

---

## Erros Comuns

| Erro | Causa | Solução |
|------|-------|---------|
| "Projeto não encontrado" | Path inválido | Verificar path |
| "Blueprint não passou G4" | Validação falhou | Executar validate-blueprint |
| "Sem permissão de escrita" | Permissões do SO | Verificar permissões |
| "Blueprint já exportado" | Duplicata | Usar --force ou outro slug |

---

*Comando do ATHENA OS v1.0.0*
