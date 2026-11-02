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
# Coverage is defined entirely by scripts/leak-patterns.txt: `#` comments, `!` allowlist
# entries, and one extended regex per remaining line. Nothing is forgiven by a literal in this
# script — before p8.31 one string was, and auditing coverage meant reading both files.
PATTERNS="$(grep -vE '^[[:space:]]*(#|!|$)' scripts/leak-patterns.txt | paste -sd'|' -)"
ALLOW="$(sed -n 's/^!//p' scripts/leak-patterns.txt)"
[ -n "$PATTERNS" ] || { printf '%s\n' "UNKNOWN: scripts/leak-patterns.txt yielded no patterns. The scan would pass everything." >&2; exit 1; }

# Blank each allowlisted substring in place, case-insensitively, and emit ONE line per input
# line so `grep -n` downstream still reports the file's own line numbers.
#
# It replaces rather than drops. Until p8.31 §1 piped its hit list through `grep -vi <string>`,
# which discarded the whole LINE: a private name sharing a line with the allowlisted npm scope
# passed silently. Narrowing the string would have shrunk that hole without closing it.
#
# awk, not `sed .../I`: BSD sed has no case-insensitive flag, and this repo is read on macOS.
# It consumes left to right rather than rescanning, so an allowlist entry that appears in the
# replacement token cannot loop.
strip_allowlisted() {
  [ -n "$ALLOW" ] || { cat; return; }
  awk -v allow="$ALLOW" '
    BEGIN { n = split(allow, A, "\n"); for (i = 1; i <= n; i++) L[i] = tolower(A[i]) }
    { line = $0
      for (i = 1; i <= n; i++) {
        if (L[i] == "") continue
        out = ""
        while ((p = index(tolower(line), L[i])) > 0) {
          out  = out substr(line, 1, p - 1) "ALLOWLISTED"
          line = substr(line, p + length(L[i]))
        }
        line = out line
      }
      print line }'
}

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
  hits=$(content "$f" 2>/dev/null | strip_allowlisted | grep -nEi "$PATTERNS" || true)
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
  SKILLS=0; NOINVOKE=""
  for d in skills/*/; do
    d="${d%/}"; n="$(basename "$d")"; f="$d/SKILL.md"
    SKILLS=$((SKILLS + 1))
    [ -f "$f" ] || { say "  $n: no SKILL.md"; BAD=$((BAD + 1)); continue; }
    head -1 "$f" | grep -qx -- '---' || { say "  $n: no frontmatter"; BAD=$((BAD + 1)); continue; }
    name=$(sed -n 's/^name: *//p' "$f" | head -1)
    [ "$name" = "$n" ] || { say "  $n: frontmatter name is '$name'"; BAD=$((BAD + 1)); }
    sed -n 's/^description: *//p' "$f" | head -1 | grep -q . || { say "  $n: no description"; BAD=$((BAD + 1)); }
    # Collected rather than tested inline: the claim is about the SET, not about one skill.
    sed -n 's/^disable-model-invocation: *//p' "$f" | head -1 | grep -qx 'true' \
      && NOINVOKE="$NOINVOKE $n"
  done

  # The pack is described as "thirteen workflow skills plus ws-shared" in the README, the
  # concepts page and the cartridge. That arithmetic rests entirely on ws-shared carrying
  # disable-model-invocation: true (p8.1) and nothing else carrying it. If the flag is lost or
  # spreads, three documents become wrong in the same moment and nothing notices — so the set
  # is asserted here, by name, rather than the count being re-counted by hand.
  NOINVOKE="${NOINVOKE# }"
  if [ "$SKILLS" -eq 0 ]; then
    say "  FAIL — skills/ exists and holds no skill directory. UNKNOWN, not ok."
    BAD=$((BAD + 1))
  elif [ "$NOINVOKE" != "ws-shared" ]; then
    say "  FAIL — exactly ws-shared must carry disable-model-invocation: true; carried by: ${NOINVOKE:-none}"
    say "         The 'thirteen skills plus ws-shared' count in README.md, docs/product/overview.md"
    say "         and docs/agent/reference.md depends on this set, and all three go wrong together."
    BAD=$((BAD + 1))
  else
    say "  read $SKILLS skill dir(s); ws-shared alone is non-invocable, so $((SKILLS - 1)) are invocable"
  fi

  [ "$BAD" -gt 0 ] && FAIL=1 || say "  ok ($SKILLS skills)"
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

# ------------------------------------------------ 5. the state dir is ignored
# The workspace root is normally not a git repo, so <state_dir> is uncommittable by accident of
# layout. Here the root IS the repo, so the only thing between the journal — whose entry header
# carries a device identifier — and a public commit is one line in .gitignore. The cartridge
# said "Do not remove that line" in bold, which is a reminder rather than a check (p8.31/p8.16).
#
# `git check-ignore` matches a PATHNAME against the ignore rules and does not require the path to
# exist, so this asserts the rule itself and is meaningful on a fresh clone and in CI, where the
# state dir has never existed.
#
# The query is asked with a TRAILING SLASH, and that is not cosmetic. The rule is written
# `.worksite/`, which matches directories only, and git can only tell a bare `.worksite` is a
# directory by looking at the filesystem. So `git check-ignore -q .worksite` answers "ignored" on
# a checkout where the directory happens to exist and "NOT ignored" everywhere else — it would
# have passed on the author's machine and failed in CI and in every fresh clone. Measured both
# ways on 2026-11-02. The bare form is tried as a fallback so a state_dir declared without a
# directory rule is still recognised.
say "== 5. state dir is ignored =="
CART="docs/agent/reference.md"
if [ ! -r "$CART" ]; then
  say "  FAIL — no readable $CART, so state_dir is UNKNOWN. Not a pass."
  FAIL=1
elif ! git rev-parse --git-dir >/dev/null 2>&1; then
  say "  skipped — read $CART, but this is not a git repo, so nothing can be committed from here"
else
  SD="$(sed -n 's/^state_dir: *//p' "$CART" | head -1)"
  if [ -z "$SD" ]; then
    say "  FAIL — read $CART and it declares no state_dir. UNKNOWN, not a pass."
    FAIL=1
  elif git check-ignore -q "${SD%/}/" || git check-ignore -q "${SD%/}"; then
    say "  ok — read $CART; '$SD' is matched by an ignore rule"
  else
    say "  FAIL — '$SD' is NOT ignored by git. The journal's entry header carries a device"
    say "         identifier and this repo is public; restore the .gitignore line."
    FAIL=1
  fi
fi

# --------------------------------------------- 6. the object store (unreachable objects)
# `git add` writes a blob before any hook can refuse the commit, so a REFUSED commit still
# leaves its content in .git/objects. Sections 1-5 read the working tree or the index and have
# never read the object store. Measured on 2026-11-02: this workspace already held unreachable
# blobs carrying private names, predating the task that found them.
#
# Nothing has escaped — unreachable objects are never pushed — so this is a local-hygiene gate,
# and the known residue is DECLARED in scripts/object-store-baseline.txt rather than suppressed.
# A fresh clone has no unreachable objects at all and must say that it looked, per ADR 0004.
say "== 6. object store (unreachable objects) =="
BASE="scripts/object-store-baseline.txt"
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  say "  skipped — not a git repo, so there is no object store to read"
else
  BL=""
  if [ -r "$BASE" ]; then
    BL="$(grep -oE '^[0-9a-f]{40}' "$BASE" || true)"
  fi
  FSCK="$(git fsck --unreachable --no-progress 2>/dev/null)"; FRC=$?
  if [ "$FRC" -ne 0 ] && [ -z "$FSCK" ]; then
    say "  FAIL — git fsck failed and printed nothing, so the object store was NOT read. UNKNOWN."
    FAIL=1
  else
    BLOBS="$(printf '%s\n' "$FSCK" | awk '$1 == "unreachable" && $2 == "blob" { print $3 }')"
    NBLOB="$(printf '%s\n' "$BLOBS" | grep -c '^[0-9a-f]\{40\}$' || true)"
    SCANNED=0; KNOWN=0; NEW=0
    while IFS= read -r o; do
      case "$o" in '' | *[!0-9a-f]* ) continue ;; esac
      SCANNED=$((SCANNED + 1))
      git cat-file blob "$o" 2>/dev/null | strip_allowlisted | grep -qEi "$PATTERNS" || continue
      if printf '%s\n' "$BL" | grep -qx "$o"; then
        KNOWN=$((KNOWN + 1))
      else
        say "  FAIL — unreachable object $o carries a private name and is not declared in $BASE"
        NEW=$((NEW + 1))
      fi
    done <<UNREACHABLE
$BLOBS
UNREACHABLE
    # Two independent counts of the same set. A section that counts with one method and scans
    # with another must not be allowed to agree with itself (ADR 0004) — the whole class of
    # defect p8.24 was about is a part that reports on work it never did.
    if [ "$SCANNED" -ne "$NBLOB" ]; then
      say "  FAIL — counted $NBLOB unreachable blob(s) but scanned $SCANNED. The scan is UNKNOWN."
      FAIL=1
    fi
    say "  read $NBLOB unreachable blob(s): $KNOWN declared in $BASE, $NEW undeclared"
    if [ "$NEW" -gt 0 ]; then
      say "  Do NOT run 'git gc --prune=now' to clear these: this object store is shared with"
      say "  live worktrees whose unreachable objects are wanted. See docs/runbooks/purge-a-leak-from-history.md."
      FAIL=1
    fi
  fi
fi

say ""
[ "$FAIL" -eq 0 ] && say "all checks passed" || say "checks FAILED"
exit "$FAIL"
