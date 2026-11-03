#!/usr/bin/env bash
# worksite verify: the checks this repo has instead of a test suite.
#
#   scripts/check.sh            check the working tree
#   scripts/check.sh --staged   check only what is staged (used by the pre-commit hook)
#
# Exit 0 = clean. Exit 1 = something to fix, printed with file and line.
set -uo pipefail

cd "$(dirname "$0")/.."
MODE=""
SKIP_OBJECT_STORE=0
for arg in "$@"; do
  case "$arg" in
    --staged) MODE="--staged" ;;
    # Only the publish path passes this, and only for the throwaway clone it assembles. A local
    # `git clone` copies the whole object store but NOT the reflogs, and `git fsck` treats reflog
    # entries as roots — so every object the source's reflog was holding arrives in the clone with
    # nothing reaching it. Measured 2026-11-03: this repo reports 29 unreachable blobs and 0
    # undeclared, while a clone of it reports 46 blobs, 105 trees and 51 commits unreachable, one
    # of them a pre-p2.2 skill version that is REACHABLE in main's history and therefore correctly
    # ignored here. Section 6 is about one machine's local hygiene; inside a candidate clone it
    # measures the source's reflog history and gates the publish on it (p8.38).
    --no-object-store) SKIP_OBJECT_STORE=1 ;;
    "") ;;
    *) printf '%s\n' "unknown argument: $arg" >&2; exit 2 ;;
  esac
done
FAIL=0
SKIPPED=""
UNCHECKED_CLAIMS=""
# Coverage is defined entirely by scripts/leak-patterns.txt: `#` comments, `!` allowlist
# entries, and one extended regex per remaining line. Nothing is forgiven by a literal in this
# script — before p8.31 one string was, and auditing coverage meant reading both files.
PATTERNS="$(grep -vE '^[[:space:]]*(#|!|$)' scripts/leak-patterns.txt | paste -sd'|' -)"
ALLOW="$(sed -n 's/^!//p' scripts/leak-patterns.txt)"
[ -n "$PATTERNS" ] || { printf '%s\n' "UNKNOWN: scripts/leak-patterns.txt yielded no patterns. The scan would pass everything." >&2; exit 1; }
# A pattern file that yields patterns grep cannot COMPILE is as silent as one that yields none,
# and far likelier: one unbalanced bracket in any line makes grep exit 2 on every file, and the
# `|| true` on each call swallows that status, so both §1 and §6 report ok on a real leak at
# exit 0. Measured with a single plausible typo (`trust[ -?loop`). Since p8.31 routes ALL
# coverage through this one file, a typo in it now silences the entire guard — so the regex is
# compiled once, here, against empty input. Exit 1 means "compiled, no match"; 2 means "did not
# compile", and only that is fatal.
printf '' | grep -qE "$PATTERNS" 2>/dev/null
[ "$?" -le 1 ] || { printf '%s\n' "UNKNOWN: grep cannot compile the patterns in scripts/leak-patterns.txt, so every scan below would pass everything. Fix the regex:" >&2; printf '' | grep -qE "$PATTERNS"; exit 1; }

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
#
# The list arrives through the ENVIRONMENT, not through `awk -v`, and both halves of that matter:
#   * BSD awk REFUSES a literal newline in a -v assignment ("awk: newline in string"). With -v,
#     the filter died the moment a SECOND `!` line was added to the pattern file — emitting
#     nothing, so `grep` downstream saw empty input and §1 reported ok on a real leak. A
#     fail-OPEN silent pass, in the guard, triggered by using the pattern file as documented.
#   * `awk -v` also expands escape sequences, so an allowlist entry containing a literal
#     backslash-t would have matched a tab instead of itself. ENVIRON does neither.
#
# NUL bytes are removed first. awk truncates a line at a NUL, so `logo\0<private name>` reached
# the patterns as `logo` — and BSD grep then skips binary input anyway, so both halves of the
# pipeline missed it. Pre-existing, and it matters more now: §6 points this scan at arbitrary
# object-store blobs, where a staged PNG or a minified bundle from a refused commit is exactly
# the residue §6 exists for. The greps that consume this pass -a for the same reason.
strip_allowlisted() {
  tr -d '\000' | {
  [ -n "$ALLOW" ] || { cat; return; }
  ALLOW="$ALLOW" awk '
    BEGIN { n = split(ENVIRON["ALLOW"], A, "\n"); for (i = 1; i <= n; i++) L[i] = tolower(A[i]) }
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
  hits=$(content "$f" 2>/dev/null | strip_allowlisted | grep -anEi "$PATTERNS" || true)
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
    # An unmatched glob stays literal in sh, so without this guard an EMPTY skills/ counts one
    # directory named "skills/*/" and the "holds no skill directory" branch below is dead code.
    [ -d "$d" ] || continue
    d="${d%/}"; n="$(basename "$d")"; f="$d/SKILL.md"
    SKILLS=$((SKILLS + 1))
    [ -f "$f" ] || { say "  $n: no SKILL.md"; BAD=$((BAD + 1)); continue; }
    head -1 "$f" | grep -qx -- '---' || { say "  $n: no frontmatter"; BAD=$((BAD + 1)); continue; }
    name=$(sed -n 's/^name: *//p' "$f" | head -1)
    [ "$name" = "$n" ] || { say "  $n: frontmatter name is '$name'"; BAD=$((BAD + 1)); }
    sed -n 's/^description: *//p' "$f" | head -1 | grep -q . || { say "  $n: no description"; BAD=$((BAD + 1)); }
    # Collected rather than tested inline: the claim is about the SET, not about one skill.
    # Scoped to the frontmatter block, so a skill that DOCUMENTS the key at the start of a line
    # in its body is not mistaken for one that sets it. (`ws-refine` discusses the key today,
    # mid-line, so nothing fires yet — which is exactly when to scope it.)
    awk 'NR==1 && /^---$/ { infm = 1; next } infm && /^---$/ { exit } infm' "$f" \
      | sed -n 's/^disable-model-invocation:[[:space:]]*//p' | head -1 \
      | sed 's/[[:space:]]*$//' | grep -qix 'true' \
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
  SD="$(sed -n 's/^state_dir:[[:space:]]*//p' "$CART" | head -1)"
  SDRAW="$SD"
  SD="${SD%%#*}"                                            # a trailing YAML comment
  SD="$(printf '%s' "$SD" | sed 's/[[:space:]]*$//')"       # and the space before it
  case "$SD" in
    \"*\") SD="$(printf '%s' "$SD" | sed 's/^"\(.*\)"$/\1/')" ;;
    \'*\') SD="$(printf '%s' "$SD" | sed "s/^'\(.*\)'$/\1/")" ;;
  esac
  if [ -z "$SD" ]; then
    say "  FAIL — read $CART and it declares no state_dir. UNKNOWN, not a pass."
    FAIL=1
  elif printf '%s' "$SD" | grep -q '[[:space:]]'; then
    # Said as a parse failure, not as "not ignored". A quoted value, a trailing comment or a
    # path with a space all used to reach the branch below and print "restore the .gitignore
    # line" while the .gitignore line was present and correct — a true FAIL with a false reason,
    # which sends the reader to fix the wrong file.
    if [ "$SDRAW" = "$SD" ]; then
      say "  FAIL — state_dir in $CART is not a usable path: [$SD]. UNKNOWN, not a pass."
    else
      say "  FAIL — could not parse state_dir from $CART: read [$SDRAW], reduced to [$SD]. UNKNOWN."
    fi
    FAIL=1
  elif git check-ignore -q "${SD%/}/" || git check-ignore -q "${SD%/}"; then
    say "  ok — read $CART; '$SD' is matched by an ignore rule"
  else
    say "  FAIL — state_dir '$SD', parsed from $CART, is NOT matched by any git ignore rule."
    say "         The track files and the journal live there and this repo is public."
    say "         Restore the .gitignore line — or, if '$SD' is not the path you expected,"
    say "         the cartridge's state_dir is wrong rather than the ignore file."
    FAIL=1
  fi
fi

# --------------------------------------------- 6. the object store (unreachable objects)
# `git add` writes a blob before any hook can refuse the commit, so a REFUSED commit still
# leaves its content in .git/objects. Every other section reads the working tree or the index and
# none of them has ever read the object store. Measured on 2026-11-02: this workspace already held unreachable
# blobs carrying private names, predating the task that found them.
#
# Nothing has escaped — unreachable objects are never pushed — so this is a local-hygiene gate,
# and the known residue is DECLARED in scripts/object-store-baseline.txt rather than suppressed.
# A fresh clone has no unreachable objects at all and must say that it looked, per ADR 0004.
say "== 6. object store (unreachable objects) =="
BASE="scripts/object-store-baseline.txt"
if [ "$SKIP_OBJECT_STORE" -eq 1 ]; then
  # Said here AND in the closing summary. A section that quietly does not run is the defect this
  # repo keeps fixing, so opting out is louder than running.
  say "  SKIPPED by --no-object-store — this is a throwaway clone, whose unreachable objects are"
  say "  an artifact of cloning (reflogs are not copied), not of the content under test."
  say "  Sections 1-5 above, and section 7 below, DO run on this content. The object store of the"
  say "  real repo is checked by its own run of this script, by the pre-commit hook and by CI."
  SKIPPED="section 6 (object store)"
elif ! git rev-parse --git-dir >/dev/null 2>&1; then
  say "  skipped — not a git repo, so there is no object store to read"
else
  # The baseline is read before anything is scanned, and "absent" and "unreadable" are told
  # apart: an unreadable baseline makes every declared hit look undeclared, which would FAIL
  # loudly rather than quietly — but it would blame the hashes instead of the file, so it says so.
  BL=""; BLSTATE="absent"
  if [ -e "$BASE" ]; then
    if [ -r "$BASE" ]; then
      # A whole-field match, so a 64-hex sha256 row cannot have its first 40 characters taken
      # as a sha1 and declare the wrong object.
      BL="$(awk '/^[0-9a-f]{40}([[:space:]]|$)/ { print $1 }' "$BASE")"; BLSTATE="read"
    else
      say "  FAIL — $BASE exists and is not readable, so nothing below is declared. UNKNOWN."
      FAIL=1; BLSTATE="unreadable"
    fi
  fi

  FSCK="$(git fsck --unreachable --no-progress 2>/dev/null)"; FRC=$?
  # `git fsck` exits 0 when it merely finds unreachable objects — measured. So ANY non-zero exit
  # means it stopped early or found a real error, and the list in hand may be partial. A partial
  # list read as complete is the whole defect class this section belongs to, so it refuses.
  if [ "$FRC" -ne 0 ]; then
    say "  FAIL — git fsck exited $FRC, so its object list may be partial. UNKNOWN, not a pass."
    FAIL=1
  else
    BLOBS="$(printf '%s\n' "$FSCK" | awk '$1 == "unreachable" && $2 == "blob"  { print $3 }')"
    TREES="$(printf '%s\n' "$FSCK" | awk '$1 == "unreachable" && $2 == "tree"  { print $3 }')"
    NCOMMIT="$(printf '%s\n' "$FSCK" | awk '$1 == "unreachable" && $2 == "commit"' | grep -c . || true)"
    NBLOB="$(printf '%s\n' "$BLOBS" | grep -c '^[0-9a-f]\{40\}$' || true)"
    NTREE="$(printf '%s\n' "$TREES" | grep -c '^[0-9a-f]\{40\}$' || true)"

    SCANNED=0; KNOWN=0; NEW=0; UNREAD=0
    render_object() { # $1 = sha, $2 = kind. A tree is rendered as its ENTRY NAMES.
      case "$2" in
        blob) git cat-file blob "$1" ;;
        # core.quotePath=false, or a non-ASCII name arrives C-quoted: a directory
        # `café-<name>` prints as "caf\303\251-<name>", so a pattern containing a non-ASCII
        # character, or one whose match spans an escaped byte, would be invisible. Measured.
        tree) git -c core.quotePath=false ls-tree --name-only "$1" ;;
      esac
    }
    scan_object() {   # $1 = sha, $2 = kind
      # NOT `grep -q`. grep -q exits on the first match and closes the pipe; awk upstream then
      # dies of SIGPIPE, and under `set -o pipefail` the pipeline status is 141 — so a `|| continue`
      # keyed on it SKIPS the hit. Measured: a large object with its match on line 1 was silently
      # passed over while the section still counted it as scanned. `grep -c` reads to the end.
      #
      # `cat-file -e` proves the object EXISTS, not that it is intact; a present-but-corrupt
      # object would stream partially and read as clean. The fsck exit check above is what
      # covers that, since fsck would have errored on it first.
      git cat-file -e "$1" 2>/dev/null || { UNREAD=$((UNREAD + 1)); return 2; }
      hits="$(render_object "$1" "$2" 2>/dev/null | strip_allowlisted | grep -acEi "$PATTERNS" || true)"
      [ "${hits:-0}" -gt 0 ]
    }
    classify() {      # $1 = sha, $2 = kind, for the message
      if printf '%s\n' "$BL" | grep -qx "$1"; then
        KNOWN=$((KNOWN + 1))
      else
        say "  FAIL — unreachable $2 $1 carries a private name and is not declared in $BASE"
        NEW=$((NEW + 1))
      fi
    }

    while IFS= read -r o; do
      case "$o" in '' | *[!0-9a-f]* ) continue ;; esac
      SCANNED=$((SCANNED + 1))
      scan_object "$o" blob && classify "$o" blob
    done <<UNREACHABLE_BLOBS
$BLOBS
UNREACHABLE_BLOBS

    # Trees carry FILENAMES, and a filename is as much a private name as a line of content —
    # a path like src/<private-project>/ leaks exactly the same string. The criterion says "no
    # unreachable OBJECT", so blobs alone did not meet it.
    TSCANNED=0
    while IFS= read -r o; do
      case "$o" in '' | *[!0-9a-f]* ) continue ;; esac
      TSCANNED=$((TSCANNED + 1))
      scan_object "$o" tree && classify "$o" tree
    done <<UNREACHABLE_TREES
$TREES
UNREACHABLE_TREES

    # Not an independent count — both come from $FSCK — so this does NOT prove the list was
    # complete; that is what the fsck exit check above is for. What it catches is the gap between
    # counting and scanning: a `case` filter that rejects more than intended, or a loop that
    # exits early, which would otherwise print a verdict over a subset. Said plainly, because an
    # earlier draft of this comment claimed independence and was simply false.
    if [ "$SCANNED" -ne "$NBLOB" ] || [ "$TSCANNED" -ne "$NTREE" ]; then
      say "  FAIL — counted $NBLOB blob(s)/$NTREE tree(s) but scanned $SCANNED/$TSCANNED. UNKNOWN."
      FAIL=1
    fi
    if [ "$UNREAD" -gt 0 ]; then
      say "  FAIL — $UNREAD object(s) could not be read, so they were never scanned. UNKNOWN."
      FAIL=1
    fi
    say "  read $NBLOB unreachable blob(s) and $NTREE tree(s) (baseline $BLSTATE): $KNOWN declared, $NEW undeclared"
    # Commit objects are deliberately NOT scanned: every commit header carries the committer's
    # name and email, so a pattern list that includes the author's name matches all of them and
    # no check can tell that from a leak. Recorded as a blind spot in docs/engineering/layout.md
    # rather than papered over with a baseline the size of the history.
    [ "$NCOMMIT" -gt 0 ] && say "  ($NCOMMIT unreachable commit(s) not scanned — see layout.md)"
    if [ "$NEW" -gt 0 ]; then
      say "  Do NOT run 'git gc --prune=now' to clear these: this object store is shared with"
      say "  live worktrees whose unreachable objects are wanted. See docs/runbooks/purge-a-leak-from-history.md."
      FAIL=1
    fi
  fi
fi


# ------------------------------------------------- 7. the README's own claims
# p7.2 wrote scripts/check-readme-claims.sh, which reads every quantity OUT of README.md and
# compares it to the tree. Nothing executed it: `verify` is this script and deliberately the only
# gate (AGENTS.md), so the checker was a rule with no path that ran it — on the repo's front page,
# one day after a release whose single criterion was that those claims held. p7.3 is this section.
#
# It CALLS the script rather than inlining it. The claim-reading is long enough that putting it
# here would make the gate unreadable, and the two files have different jobs: this one is the gate,
# that one reads the front page. (No line count is quoted on purpose: the figure would drift, and
# it is load-bearing for nothing.) It is still not a second `verify` — there is one command, and this is a section of it.
#
# WHAT IT READS, per ADR 0004: the WORKING TREE at the repo root, never the index. The script opens
# files with cat and grep, and `--staged` cannot redirect that, so in --staged mode it is reading a
# different tree from the one being committed. That is named below rather than glossed, as section
# 3 already does for link targets.
say "== 7. README claims =="
CLAIMS="scripts/check-readme-claims.sh"
if [ ! -r "$CLAIMS" ]; then
  say "  FAIL — no readable $CLAIMS, so the README's claims are UNKNOWN. Not a pass."
  FAIL=1
elif [ ! -r README.md ]; then
  say "  FAIL — no readable README.md, so there is nothing whose claims could be checked. UNKNOWN."
  FAIL=1
else
  if [ "$MODE" = "--staged" ]; then
    say "  note — these claims are read from the WORKING TREE, not from the staged tree, because"
    say "  the checker opens files on disk. Where the two differ, what section 7 says below is"
    say "  about the version on disk and not about the version being committed."
    # The question is narrow and it took three tries to ask it: for which paths do the INDEX —
    # which is what is being committed — and the WORKING TREE — which is what the claims are read
    # from — hold different content?
    #
    # `git diff --name-only` alone was the first answer and misses two cases that matter:
    #   * README.md staged for DELETION but still on disk. There is no index entry to diff
    #     against, so `git diff` is silent and §7 certified 39 claims out of a file the commit
    #     removes, announcing that the trees agreed. `ls-files --others` names it, because
    #     removing it from the index is exactly what makes it untracked.
    #   * an UNTRACKED file the checker reads — an extra roadmap file or skill directory changes
    #     what the counts measure, and refuses every commit in the repo until it is dealt with.
    # `git status --porcelain` was the second answer and is too WIDE: it reports a staged,
    # worktree-clean file (`M `) as uncommitted, and that is the one case where the index and the
    # working tree agree exactly. During this task's own commit it listed all seven staged files
    # as differing from the commit they were in. A label that is wrong on the ordinary case is a
    # label nobody reads by the time it is right.
    # So: content differences, then untracked, de-duplicated — `git diff` prints an unmerged path
    # more than once.
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
      # Said, not assumed. Sections 5 and 6 both test this; the first version of this branch
      # asserted "the two trees agree" where there was no index to agree with.
      say "    not a git repo, so there is no index to compare against and nothing below is"
      say "    about a staged tree at all."
    else
      DIFFERS="$( { git diff --name-only; git ls-files --others --exclude-standard; } 2>/dev/null | sort -u )"
      if [ -n "$DIFFERS" ]; then
        say "    the index and the working tree hold different content for these paths, so any one"
        say "    of them the checker reads, it read in its on-disk form and not as committed:"
        printf '%s\n' "$DIFFERS" | sed 's|^|      |'
      else
        say "    the index and the working tree agree on every path, so the tree the claims were"
        say "    read from is the tree being committed."
      fi
    fi
  fi
  # Captured rather than streamed, so the exit status read below is the SCRIPT's and not sed's.
  # `$?` after a pipeline reports the last command, which is the evidence bug this repo keeps
  # re-finding; a pipe here would report sed's 0 on every failing claim.
  CLAIMOUT="$(bash "$CLAIMS" . 2>&1)"; CRC=$?
  # The checker's totals come from the ONE LINE it prints for this purpose, counted inside it by
  # the very functions that print each claim. This script used to re-derive them by grepping the
  # checker's output, and a review killed that in a single line: reverting the checker's group
  # heading from `-- n --` to `== n ==` made this section report "0 claim group(s)" — and call it
  # ok, because only the `ok` count was gated. A count derived from another program's formatting
  # is a count that silently becomes zero when the formatting moves.
  COUNTS="$(printf '%s\n' "$CLAIMOUT" | sed -n 's/^-- counts -- //p' | tail -1)"
  cnt() { printf '%s' "$COUNTS" | sed -n "s/.*$1=\([0-9]*\).*/\1/p"; }
  NGROUP="$(cnt groups)"; NOK="$(cnt ok)"; NNOTE="$(cnt note)"; NUNCHECKED="$(cnt unchecked)"
  # Everything that is not a clean, self-reporting, non-empty pass prints the whole output: which
  # claim, what the README said, what the tree has. Nothing is summarised away at the one moment
  # the summary would matter.
  if [ "$CRC" -ne 0 ] || [ -z "$COUNTS" ] || [ "${NGROUP:-0}" -eq 0 ] || [ "${NOK:-0}" -eq 0 ]; then
    printf '%s\n' "$CLAIMOUT" | sed '/./s|^|  |'
  fi
  if [ -z "$COUNTS" ]; then
    # No self-report at all: the checker died before its last line, or is not the program this
    # section thinks it is. Either way what it read is unknown, and a crash must not be reported
    # as "a claim does not hold" — that sends the reader to the README instead of to the script.
    say "  FAIL — $CLAIMS printed no '-- counts --' line, so what it read is UNKNOWN. Not a pass."
    FAIL=1
  elif [ "${NGROUP:-0}" -eq 0 ] || [ "${NOK:-0}" -eq 0 ]; then
    # A pass is only a pass if it certified something. Zero groups or zero holding claims means it
    # ran and read nothing, and an empty result read as a pass is the defect class this repo keeps
    # fixing — section 6 refuses the same way on a partial `git fsck`.
    say "  FAIL — $CLAIMS reports ${NGROUP:-0} claim group(s) and ${NOK:-0} holding claim(s), so it"
    say "         certified nothing. UNKNOWN, not a pass."
    FAIL=1
  elif [ "$CRC" -ne 0 ]; then
    say "  FAIL — a README claim does not hold against this tree (named above)."
    FAIL=1
  else
    # What was read, per ADR 0004, with the counts that show it was read — and the paraphrase
    # notes said out loud rather than buried, because three of the thirteen skill-table cells are
    # fair paraphrases and a `note` is the honest verdict on them, not a pass and not a failure.
    say "  read README.md and the files it cites: ${NGROUP:-0} claim group(s), ${NOK:-0} claim(s) hold,"
    say "  ${NNOTE:-0} reported as paraphrase or detail, ${NUNCHECKED:-0} not checked here."
    say "  Run 'bash $CLAIMS .' to see each one. ok"
  fi
  if [ "${NUNCHECKED:-0}" -gt 0 ]; then
    UNCHECKED_CLAIMS="$NUNCHECKED README claim(s)"
    # Named on the quiet path only — a claim nothing looked at must not be invisible, but on the
    # loud path the full dump above already carries these lines and printing them again made them
    # appear three times.
    if [ "$CRC" -eq 0 ] && [ "${NOK:-0}" -gt 0 ] && [ "${NGROUP:-0}" -gt 0 ]; then
      printf '%s\n' "$CLAIMOUT" | grep '^  UNCHECKED' | sed 's|^|  |'
    fi
  fi
fi

say ""
if [ -n "$UNCHECKED_CLAIMS" ]; then
  say "NOTE: $UNCHECKED_CLAIMS could not be checked on this machine — section 7 names each and why."
  say "A tool this machine lacks is not a claim that holds, so the pass below is that much narrower."
fi
if [ -n "$SKIPPED" ]; then
  [ "$FAIL" -eq 0 ] && say "all checks passed EXCEPT $SKIPPED, which was skipped by request" \
                    || say "checks FAILED (and $SKIPPED was skipped by request)"
else
  [ "$FAIL" -eq 0 ] && say "all checks passed" || say "checks FAILED"
fi
exit "$FAIL"
