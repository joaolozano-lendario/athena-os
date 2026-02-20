#!/usr/bin/env bash
# Gate 0B — Smart PreToolUse blocker
# Reads tool_input from stdin JSON
# Blocks if CSS content contains .card-header (wrong class)
# Provides corrective feedback

INPUT=$(cat)
CONTENT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('content',''))" 2>/dev/null)

if echo "$CONTENT" | grep -q '\.card-header'; then
  echo "BLOQUEADO: O seletor .card-header NAO existe no HTML do projeto." >&2
  echo "Classes corretas disponiveis: .feature-card__title, .feature-card__text, .hero-title" >&2
  echo "Substitua .card-header por .feature-card__title e tente novamente." >&2
  exit 2
fi

exit 0
