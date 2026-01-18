# /ATHENA:tasks:validate-blueprint

> Validar um Blueprint existente contra os critérios de qualidade

---

## Descrição

Executa validação completa de um Blueprint existente, verificando:
- Completude de todas as seções
- Consistência entre artefatos
- Conformidade com taxonomia
- Transferibilidade

---

## Uso

```bash
/ATHENA:tasks:validate-blueprint {path-do-blueprint}
```

Ou sem argumento para validar o último Blueprint gerado.

---

## Checklist de Validação

### 1. Completude (35%)

| Item | Verificação |
|------|-------------|
| ✓ | BLUEPRINT.md existe e tem todas as 7 seções |
| ✓ | ACTIVATION.md existe e tem instruções |
| ✓ | intent-spec.yaml completo |
| ✓ | exec-arch.yaml completo |
| ✓ | checkpoint-map.yaml com tasks |
| ✓ | taxonomy-config.yaml definido |
| ✓ | _metadata.yaml presente |

### 2. Consistência (35%)

| Item | Verificação |
|------|-------------|
| ✓ | IDs seguem padrão correto |
| ✓ | Referências entre arquivos resolvem |
| ✓ | Fases → Épicos mapeados corretamente |
| ✓ | Todas as tasks têm critério binário |
| ✓ | Checkpoints referenciam tasks existentes |

### 3. Transferibilidade (30%)

| Item | Verificação |
|------|-------------|
| ✓ | JTBD está claro e específico |
| ✓ | Critérios de sucesso são binários |
| ✓ | Sem jargão inexplicado |
| ✓ | Primeiro passo é acionável |
| ✓ | **Teste:** Lendo apenas o Blueprint, dá para executar? |

---

## Output

```yaml
# validation-report.yaml
validation:
  blueprint_id: "BP-..."
  validated_at: "{timestamp}"
  
  scores:
    completeness: 0.95
    consistency: 1.00
    transferability: 0.90
    overall: 0.95
    
  status: "PASSED | FAILED"
  
  issues:
    - severity: "ERROR | WARNING | INFO"
      location: "arquivo ou seção"
      message: "descrição do problema"
      suggestion: "como corrigir"
      
  summary:
    total_checks: 20
    passed: 19
    failed: 1
    warnings: 2
```

---

## Instruções para ATHENA

1. Localizar Blueprint (argumento ou último gerado)
2. Carregar todos os arquivos do diretório
3. Executar cada verificação do checklist
4. Calcular scores
5. Gerar relatório
6. Apresentar resultado ao operador
7. Se FAILED, listar issues e sugerir correções

---

## Thresholds

| Métrica | Mínimo para PASS |
|---------|------------------|
| Completeness | 95% |
| Consistency | 100% |
| Transferability | 85% |
| **Overall** | **90%** |

---

*Comando do ATHENA OS v1.0.0*
