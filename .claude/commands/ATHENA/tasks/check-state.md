# /ATHENA:tasks:check-state

> Verificar estado atual do sistema ATHENA OS

---

## Instruções para ATHENA

1. **Read STATE.yaml** (~36 lines — lean index)

2. **Show system pulse:**
   - Version, status, last_updated
   - Current phase (IDLE / FORGING / EXECUTING)
   - Last completed blueprint
   - AURUM connection status

3. **IF active_work.status != IDLE:**
   - Read the referenced project-memory file
   - Show active blueprint, phase, progress

4. **IF user asks for details, read on-demand:**
   - `observability/blueprints-archive.yaml` for blueprint history
   - `observability/execution_log.yaml` for execution history
   - `observability/integration-registry.yaml` for registered projects
   - `observability/project-memory/{slug}.yaml` for project details

5. **Show modular file map:**
   ```
   STATE.yaml (pulse)
    ├── observability/blueprints-archive.yaml (12 blueprints)
    ├── observability/execution_log.yaml (3 executions)
    ├── observability/integration-registry.yaml (6 projects)
    ├── observability/pattern_library.yaml (4 anti-patterns)
    └── observability/project-memory/ (per-project state)
   ```

6. **Suggest next action** based on state

---

## Output Format

```
ATHENA OS v{version} — {status}
Last updated: {date}

Session: {IDLE | FORGING BP-xxx | EXECUTING BP-xxx}
Last completed: {BP-ID}
AURUM: {CONNECTED | OFFLINE}

Blueprints: {total} generated | Archive: observability/blueprints-archive.yaml
Executions: {total} logged | Log: observability/execution_log.yaml
Projects: {total} registered | Registry: observability/integration-registry.yaml

Next: {suggested action}
```

---

*Comando do ATHENA OS v3.1.0*
