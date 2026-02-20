#!/usr/bin/env bash
# Gate 0B test hook — BLOCKS only if file contains ".card-header"
# Reads the file that's about to be written from CLAUDE_FILE_PATH
# If it contains .card-header → block with corrective message
# If it doesn't → allow

FILE_PATH="${CLAUDE_FILE_PATH:-$1}"

if [[ -z "$FILE_PATH" ]]; then
  exit 0  # No file path, allow
fi

# Check if the file exists (it was just written by the tool)
if [[ -f "$FILE_PATH" ]] && grep -q '\.card-header' "$FILE_PATH" 2>/dev/null; then
  echo "BLOQUEADO: O seletor .card-header NÃO existe no HTML." >&2
  echo "Classes disponíveis: .feature-card__title, .feature-card__text, .hero-title" >&2
  echo "Corrija o CSS substituindo .card-header pela classe correta e tente novamente." >&2
  exit 2
fi

exit 0
