#!/usr/bin/env bash
# worksite verify: the checks this repo has instead of a test suite.
#
#   scripts/check.sh            check the working tree
#   scripts/check.sh --staged   check only what is staged (used by the pre-commit hook)
#
# Exit 0 = clean. Exit 1 = something to fix, printed with file and line.
set -uo pipefail

cd "$(dirname "$0")/.."
MODE="${1:-}"
FAIL=0
PATTERNS="$(grep -vE '^\s*(#|$)' scripts/leak-patterns.txt | paste -sd'|' -)"

# Files that may legitimately contain a pattern.
excluded() {
  case "$1" in
    LICENSE|scripts/check.sh|scripts/leak-patterns.txt|.githooks/*) return 0 ;;
    *) return 1 ;;
  esac
}

files() {
  if [ "$MODE" = "--staged" ]; then
    git diff --cached --name-only --diff-filter=ACM
  else
    # --others --exclude-standard so a NEW, not-yet-staged file is checked too. Without it
    # a manual run reports ok on a file nobody has added yet, which is a false pass.
    git ls-files --cached --others --exclude-standard 2>/dev/null \
      || find . -type f -not -path './.git/*' | sed 's|^\./||'
  fi
}

content() {
  if [ "$MODE" = "--staged" ]; then git show ":$1"; else cat "$1"; fi
}

say() { printf '%s\n' "$*"; }

# ---------------------------------------------------------------- 1. name leaks
say "== 1. private names =="
LEAKS=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  excluded "$f" && continue
  hits=$(content "$f" 2>/dev/null | grep -nEi "$PATTERNS" | grep -vi 'abdur-codes' || true)
  if [ -n "$hits" ]; then
    printf '%s\n' "$hits" | sed "s|^|  $f:|"
    LEAKS=$((LEAKS + 1))
  fi
done < <(files)
if [ "$LEAKS" -gt 0 ]; then
  say "  FAIL — $LEAKS file(s) hold a private name. The pack must be generic."
  FAIL=1
else
  say "  ok"
fi

# ------------------------------------------------------- 2. skill frontmatter
say "== 2. skill frontmatter =="
BAD=0
if [ -d skills ]; then
  for d in skills/*/; do
    d="${d%/}"; n="$(basename "$d")"; f="$d/SKILL.md"
    [ -f "$f" ] || { say "  $n: no SKILL.md"; BAD=$((BAD + 1)); continue; }
    head -1 "$f" | grep -qx -- '---' || { say "  $n: no frontmatter"; BAD=$((BAD + 1)); continue; }
    name=$(sed -n 's/^name: *//p' "$f" | head -1)
    [ "$name" = "$n" ] || { say "  $n: frontmatter name is '$name'"; BAD=$((BAD + 1)); }
    sed -n 's/^description: *//p' "$f" | head -1 | grep -q . || { say "  $n: no description"; BAD=$((BAD + 1)); }
  done
  [ "$BAD" -gt 0 ] && FAIL=1 || say "  ok ($(ls -d skills/*/ 2>/dev/null | wc -l | tr -d ' ') skills)"
else
  say "  skipped — no skills/ yet"
fi

# ------------------------------------------------------- 3. relative links
say "== 3. relative links =="
BROKEN=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in *.md) ;; *) continue ;; esac
  dir="$(dirname "$f")"
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    case "$target" in http*|mailto:*|\#*) continue ;; esac
    # A target containing <placeholder> is a template, not a path. ws-setup/templates/ is
    # full of them by design, and resolving one is meaningless.
    case "$target" in *'<'*|*'>'*) continue ;; esac
    t="${target%%#*}"
    [ -n "$t" ] || continue
    [ -e "$dir/$t" ] || { say "  $f -> $target"; BROKEN=$((BROKEN + 1)); }
  done < <(grep -oE '\]\([^)]+\)' "$f" | sed 's/^](//; s/)$//')
done < <(files)
[ "$BROKEN" -gt 0 ] && { say "  FAIL — $BROKEN broken link(s)"; FAIL=1; } || say "  ok"

# ------------------------------------------------- 4. library parity (informational)
# ADR 0001 says the agent-sync library is the working copy and this repo is a published
# artifact, so publishing must be a plain COPY. That only holds if the two are identical, and
# nothing was checking it: a skill edited in the library and not re-copied here diverges
# silently, which is exactly what happened on p8.10.
#
# Informational, never a failure. "Library ahead of repo, pending review" is a legitimate
# state — it is where every change sits between being built and being published. The hard
# gate belongs in the publish step (p6.1), not in a commit hook.
say "== 4. library parity (informational) =="
LIB="$HOME/.agent-sync/store/skills"
if [ ! -d "$LIB" ]; then
  say "  skipped — no local library on this machine, which is the normal case for a reader"
elif [ ! -d skills ]; then
  say "  skipped — no skills/ in the repo yet"
else
  DRIFT=0
  for d in skills/ws-*/; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"
    if [ ! -d "$LIB/$n" ]; then
      say "  $n: in the repo, absent from the library"; DRIFT=$((DRIFT + 1)); continue
    fi
    diff -rq "$LIB/$n" "$d" >/dev/null 2>&1 || { say "  $n: differs from the library"; DRIFT=$((DRIFT + 1)); }
  done
  for d in "$LIB"/ws-*/; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"
    [ -d "skills/$n" ] || { say "  $n: in the library, not yet published here"; DRIFT=$((DRIFT + 1)); }
  done
  if [ "$DRIFT" -gt 0 ]; then
    say "  $DRIFT difference(s) — fine mid-change, but publishing must be a plain copy (ADR 0001)"
  else
    say "  ok — identical"
  fi
fi

say ""
[ "$FAIL" -eq 0 ] && say "all checks passed" || say "checks FAILED"
exit "$FAIL"
