#!/usr/bin/env bash
# FORMICA v4.1 — Hook Unit Tests
# Tests extractors, validators, and coherence map parsing
set -uo pipefail
# Note: NOT set -e — validators return exit 2 which we need to capture

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$SCRIPT_DIR/hooks"
PASS=0
FAIL=0
TOTAL=0

pass() { PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  FAIL: $1"; }

# Create temp dir for test artifacts
# Use D:/athena-os/.orchestrator/tests/tmp/ for python3 Windows compatibility
TMPDIR="$SCRIPT_DIR/tests/tmp-hooks-$$"
mkdir -p "$TMPDIR"
trap "rm -rf '$TMPDIR'" EXIT

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  HOOKS UNIT TESTS — Extractors & Validators              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ── T1: HTML Extractor ──
echo "── T1: HTML Extractor ──"

cat > "$TMPDIR/test.html" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>Test</title></head>
<body>
  <div id="app" class="container main-wrapper">
    <header class="hero-section" id="hero">
      <h1 class="hero-title">Title</h1>
    </header>
    <section class="features" data-section="features">
      <div class="feature-card">Card 1</div>
      <div class="feature-card active">Card 2</div>
    </section>
  </div>
</body>
</html>
HTMLEOF

CONTRACT=$(bash "$HOOKS_DIR/extractors/extract-html.sh" "$TMPDIR/test.html" 2>/dev/null)

if echo "$CONTRACT" | python3 -c "import sys,json; c=json.load(sys.stdin); assert 'container' in c['exports']['classes']" 2>/dev/null; then
  pass "HTML extractor: found 'container' class"
else
  fail "HTML extractor: missing 'container' class"
fi

if echo "$CONTRACT" | python3 -c "import sys,json; c=json.load(sys.stdin); assert 'hero' in c['exports']['ids']" 2>/dev/null; then
  pass "HTML extractor: found 'hero' ID"
else
  fail "HTML extractor: missing 'hero' ID"
fi

if echo "$CONTRACT" | python3 -c "import sys,json; c=json.load(sys.stdin); assert 'data-section' in c['exports']['data_attributes']" 2>/dev/null; then
  pass "HTML extractor: found 'data-section' attribute"
else
  fail "HTML extractor: missing 'data-section' attribute"
fi

CLASS_COUNT=$(echo "$CONTRACT" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['exports']['classes']))" 2>/dev/null)
if [[ "$CLASS_COUNT" -ge 5 ]]; then
  pass "HTML extractor: found $CLASS_COUNT classes (≥5)"
else
  fail "HTML extractor: only $CLASS_COUNT classes (expected ≥5)"
fi

echo ""

# ── T2: CSS Extractor ──
echo "── T2: CSS Extractor ──"

cat > "$TMPDIR/test.css" << 'CSSEOF'
/* Main styles */
:root { --primary: #333; --accent: blue; }
.container { max-width: 1200px; }
.hero-section { background: var(--primary); }
.hero-title { font-size: 2rem; }
.feature-card { padding: 20px; }
.feature-card:hover { opacity: 0.8; }
#app { margin: 0 auto; }
CSSEOF

CSS_CONTRACT=$(bash "$HOOKS_DIR/extractors/extract-css.sh" "$TMPDIR/test.css" 2>/dev/null)

if echo "$CSS_CONTRACT" | python3 -c "import sys,json; c=json.load(sys.stdin); assert 'container' in c['exports']['selectors']" 2>/dev/null; then
  pass "CSS extractor: found 'container' selector"
else
  fail "CSS extractor: missing 'container' selector"
fi

if echo "$CSS_CONTRACT" | python3 -c "import sys,json; c=json.load(sys.stdin); assert '--primary' in c['exports']['variables']" 2>/dev/null; then
  pass "CSS extractor: found '--primary' variable"
else
  fail "CSS extractor: missing '--primary' variable"
fi

echo ""

# ── T3: CSS Validator — Valid Input ──
echo "── T3: CSS Validator — Valid Input ──"

# Build validator input: CSS that matches HTML contract
VALIDATOR_INPUT=$(python3 -c "
import json
contract = {
    'exports': {
        'classes': ['container', 'hero-section', 'hero-title', 'feature-card', 'active', 'main-wrapper', 'features'],
        'ids': ['app', 'hero']
    }
}
content = '''
.container { max-width: 1200px; }
.hero-section { background: #333; }
.hero-title { font-size: 2rem; }
.feature-card { padding: 20px; }
'''
data = {'contract': contract, 'content': content, 'file_path': 'test.css'}
print(json.dumps(data))
")

echo "$VALIDATOR_INPUT" | bash "$HOOKS_DIR/validators/validate-html-css.sh" 2>/dev/null
if [[ $? -eq 0 ]]; then
  pass "CSS validator: valid CSS passes (exit 0)"
else
  fail "CSS validator: valid CSS should pass but didn't"
fi

echo ""

# ── T4: CSS Validator — Orphan Selectors ──
echo "── T4: CSS Validator — Orphan Selectors ──"

ORPHAN_INPUT=$(python3 -c "
import json
contract = {
    'exports': {
        'classes': ['container', 'hero-section'],
        'ids': ['app']
    }
}
content = '''
.container { max-width: 1200px; }
.hero-section { background: #333; }
.nonexistent-class { color: red; }
.another-orphan { display: none; }
'''
data = {'contract': contract, 'content': content, 'file_path': 'test.css'}
print(json.dumps(data))
")

STDERR_OUTPUT=$(echo "$ORPHAN_INPUT" | bash "$HOOKS_DIR/validators/validate-html-css.sh" 2>&1 1>/dev/null)
EXIT_CODE=$?

if [[ $EXIT_CODE -eq 2 ]]; then
  pass "CSS validator: orphan selectors blocked (exit 2)"
else
  fail "CSS validator: orphan selectors should be blocked (got exit $EXIT_CODE)"
fi

if echo "$STDERR_OUTPUT" | grep -q "nonexistent-class"; then
  pass "CSS validator: stderr mentions orphan '.nonexistent-class'"
else
  fail "CSS validator: stderr should mention '.nonexistent-class'"
fi

if echo "$STDERR_OUTPUT" | grep -q "another-orphan"; then
  pass "CSS validator: stderr mentions orphan '.another-orphan'"
else
  fail "CSS validator: stderr should mention '.another-orphan'"
fi

echo ""

# ── T5: Keyword Extractor ──
echo "── T5: Keyword Extractor ──"

cat > "$TMPDIR/test-strategy.txt" << 'KWEOF'
Our marketing strategy focuses on conversion optimization and customer retention.
The conversion funnel includes three stages: awareness, consideration, and decision.
We optimize conversion at each stage through targeted messaging and social proof.
Customer retention drives long-term growth through loyalty programs.
KWEOF

KW_CONTRACT=$(bash "$HOOKS_DIR/extractors/extract-keywords.sh" "$TMPDIR/test-strategy.txt" 2>/dev/null)

if echo "$KW_CONTRACT" | python3 -c "import sys,json; c=json.load(sys.stdin); assert 'conversion' in c['exports']['keywords']" 2>/dev/null; then
  pass "Keyword extractor: found 'conversion'"
else
  fail "Keyword extractor: missing 'conversion'"
fi

KW_COUNT=$(echo "$KW_CONTRACT" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['exports']['keywords']))" 2>/dev/null)
if [[ "$KW_COUNT" -ge 3 ]]; then
  pass "Keyword extractor: found $KW_COUNT keywords (≥3)"
else
  fail "Keyword extractor: only $KW_COUNT keywords (expected ≥3)"
fi

echo ""

# ── T6: Keyword Validator — Missing Terms ──
echo "── T6: Keyword Validator — Missing Terms ──"

MISSING_INPUT=$(python3 -c "
import json
contract = {
    'exports': {
        'keywords': ['conversion', 'retention', 'funnel', 'optimization', 'strategy',
                     'awareness', 'consideration', 'decision', 'loyalty', 'growth']
    }
}
content = 'This is a completely unrelated document about cooking recipes and gardening tips.'
data = {'contract': contract, 'content': content, 'file_path': 'test.txt'}
print(json.dumps(data))
")

echo "$MISSING_INPUT" | bash "$HOOKS_DIR/validators/validate-keywords.sh" 2>/dev/null
KW_EXIT=$?
if [[ $KW_EXIT -eq 2 ]]; then
  pass "Keyword validator: >30% missing terms → blocked (exit 2)"
else
  fail "Keyword validator: should block when >30% missing (got exit $KW_EXIT)"
fi

echo ""

# ── T7: Generic Extractor ──
echo "── T7: Generic Extractor ──"

echo "Hello World — this is generic content for testing." > "$TMPDIR/test-generic.txt"

GEN_CONTRACT=$(bash "$HOOKS_DIR/extractors/extract-generic.sh" "$TMPDIR/test-generic.txt" 2>/dev/null)
if echo "$GEN_CONTRACT" | python3 -c "import sys,json; c=json.load(sys.stdin); assert c['type'] == 'generic'" 2>/dev/null; then
  pass "Generic extractor: type=generic"
else
  fail "Generic extractor: wrong type"
fi

if echo "$GEN_CONTRACT" | python3 -c "import sys,json; c=json.load(sys.stdin); assert c['exports']['line_count'] >= 1" 2>/dev/null; then
  pass "Generic extractor: line_count >= 1"
else
  fail "Generic extractor: bad line_count"
fi

echo ""

# ── T8: Coherence Map — Empty Section ──
echo "── T8: Coherence Map — Empty Section ──"

cat > "$TMPDIR/manifest-no-coherence.yaml" << 'YAMLEOF'
id: "test-bp"
config:
  max_budget_usd: 5
tasks: []
YAMLEOF

CMAP=$(yq -o=json '.coherence // {}' "$TMPDIR/manifest-no-coherence.yaml" 2>/dev/null | tr -d '\r')
if [[ "$CMAP" == "{}" ]]; then
  pass "Coherence map: empty section → empty JSON object"
else
  fail "Coherence map: expected {}, got: $CMAP"
fi

echo ""

# ── T9: Coherence Map — Full Section ──
echo "── T9: Coherence Map — Full Section ──"

cat > "$TMPDIR/manifest-coherence.yaml" << 'YAMLEOF'
id: "test-bp"
coherence:
  mode: "strict"
  contracts:
    - producer: "build-html"
      consumer: "build-css"
      validator: "html-css-classes"
    - producer: "define-strategy"
      consumer: "write-copy"
      validator: "keyword-presence"
YAMLEOF

CMAP=$(yq -o=json '.coherence // {}' "$TMPDIR/manifest-coherence.yaml" 2>/dev/null | tr -d '\r')
PRODUCER_COUNT=$(echo "$CMAP" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['contracts']))" 2>/dev/null)
if [[ "$PRODUCER_COUNT" -eq 2 ]]; then
  pass "Coherence map: parsed 2 contract entries"
else
  fail "Coherence map: expected 2 entries, got $PRODUCER_COUNT"
fi

FIRST_PRODUCER=$(echo "$CMAP" | python3 -c "import sys,json; print(json.load(sys.stdin)['contracts'][0]['producer'])" 2>/dev/null)
if [[ "$FIRST_PRODUCER" == "build-html" ]]; then
  pass "Coherence map: first producer = build-html"
else
  fail "Coherence map: first producer should be 'build-html', got '$FIRST_PRODUCER'"
fi

echo ""

# ── T10: JS Validator — Valid Input ──
echo "── T10: JS Validator — Valid Input ──"

JS_VALID_INPUT=$(python3 -c "
import json
contract = {
    'exports': {
        'classes': ['menu-toggle', 'sidebar', 'nav-item'],
        'ids': ['app', 'main-content']
    }
}
content = '''
document.querySelector('.menu-toggle').addEventListener('click', () => {
    document.getElementById('main-content').classList.toggle('active');
});
'''
data = {'contract': contract, 'content': content, 'file_path': 'test.js'}
print(json.dumps(data))
")

echo "$JS_VALID_INPUT" | bash "$HOOKS_DIR/validators/validate-html-js.sh" 2>/dev/null
if [[ $? -eq 0 ]]; then
  pass "JS validator: valid queries pass (exit 0)"
else
  fail "JS validator: valid queries should pass"
fi

echo ""

# ── T11: JS Validator — Orphan Queries ──
echo "── T11: JS Validator — Orphan Queries ──"

JS_ORPHAN_INPUT=$(python3 -c "
import json
contract = {
    'exports': {
        'classes': ['menu-toggle'],
        'ids': ['app']
    }
}
content = '''
document.querySelector('.nonexistent-btn').addEventListener('click', () => {
    document.getElementById('missing-panel').style.display = 'block';
});
'''
data = {'contract': contract, 'content': content, 'file_path': 'test.js'}
print(json.dumps(data))
")

echo "$JS_ORPHAN_INPUT" | bash "$HOOKS_DIR/validators/validate-html-js.sh" 2>/dev/null
JS_EXIT=$?
if [[ $JS_EXIT -eq 2 ]]; then
  pass "JS validator: orphan queries blocked (exit 2)"
else
  fail "JS validator: orphan queries should be blocked (got exit $JS_EXIT)"
fi

echo ""

# ── T12: CSS Validator — Zero False Positives on Pseudo-classes ──
echo "── T12: CSS Validator — Zero False Positives ──"

PSEUDO_INPUT=$(python3 -c "
import json
contract = {
    'exports': {
        'classes': ['btn', 'card'],
        'ids': []
    }
}
content = '''
:root { --color: red; }
.btn { padding: 10px; }
.btn:hover { opacity: 0.8; }
.btn:focus { outline: 2px solid blue; }
.btn::before { content: ''; }
.card { margin: 10px; }
'''
data = {'contract': contract, 'content': content, 'file_path': 'test.css'}
print(json.dumps(data))
")

echo "$PSEUDO_INPUT" | bash "$HOOKS_DIR/validators/validate-html-css.sh" 2>/dev/null
if [[ $? -eq 0 ]]; then
  pass "CSS validator: pseudo-classes/elements don't cause false positives"
else
  fail "CSS validator: pseudo-classes caused false positive"
fi

echo ""

echo "════════════════════════════════════════════════════════════"
echo "  HOOKS UNIT TESTS RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "════════════════════════════════════════════════════════════"

if [[ $FAIL -eq 0 ]]; then
  echo "  STATUS: ✓ ALL TESTS PASSED"
  exit 0
else
  echo "  STATUS: ✗ $FAIL TESTS FAILED"
  exit 1
fi
