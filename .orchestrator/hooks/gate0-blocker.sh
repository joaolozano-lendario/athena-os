#!/usr/bin/env bash
# Gate 0 test hook — BLOCKS all writes, returns descriptive error
# Exit 2 = block with user-facing message (Claude Code hook protocol)
echo "BLOQUEADO: Este hook de teste impede todas as escritas. Use a classe .hero-title em vez de .title-main." >&2
exit 2
