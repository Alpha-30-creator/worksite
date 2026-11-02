#!/usr/bin/env bash
# Check every checkable claim in README.md against a tree. Usage:
#
#     bash scripts/check-readme-claims.sh <tree-dir>
#
# Exits non-zero if any claim fails, so it can gate a tag. Written for p7.2, whose single
# acceptance criterion was "the README's claims all verified against the tagged tree", and kept
# here rather than in that task's scratch so the next tag does not re-derive it by hand.
#
# THIS IS NOT THE PROJECT'S `verify`. That is `scripts/check.sh` and there is deliberately only
# one (AGENTS.md). This script is evidence tooling for one criterion; nothing runs it
# automatically, which is a gap, and p7.3 is filed to fold it into check.sh as a section so that
# a stale README claim fails the same gate everything else does.
#
# DIRECTION, which the first draft got wrong. Every quantity is read **out of README.md** and
# compared to the tree. The first version hard-coded the numbers in this file and only checked the
# tree, so renaming "thirteen skills" to "twelve" passed — the check could not see the claim it
# was supposed to be checking. A review found that by mutating a copy; nine claims passed a README
# that was false. If you add a check here, read the claim from the README.
#
# What it does NOT check, so the silence is not read as coverage:
#   * judgement — whether overview.md's argument persuades, whether a paraphrase is fair (those
#     are reported, and a cell sharing no content word with its skill's own sentence FAILS);
#   * the bodies of the linked documents, beyond their existence and the few facts named below;
#   * external URLs: they are listed and skipped, never fetched;
#   * whether a claim is true on a stranger's machine rather than this tree. p7.1 measured that
#     gap at 44 guess-points.
set -u
R="${1:?usage: bash scripts/check-readme-claims.sh <tree-dir>}"
cd "$R" || exit 1
[ -f README.md ] || { echo "no README.md in $R"; exit 1; }
fail=0
# README.md with newlines folded and runs of whitespace squeezed: a claim that wraps across two
# lines is invisible to a line-based grep, and three checks silently found "no claim" because of it.
FLAT=$(tr '\n' ' ' < README.md | tr -s ' ')
ok()  { printf '  ok     %s\n' "$*"; }
bad() { printf '  FAIL   %s\n' "$*"; fail=1; }
note(){ printf '  note   %s\n' "$*"; }
hdr() { printf '\n== %s ==\n' "$*"; }

# word2num: the README spells quantities as words. Return -1 for anything unrecognised so a
# missing claim is a failure rather than a silent 0.
w2n() { case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
  zero) echo 0;; one) echo 1;; two) echo 2;; three) echo 3;; four) echo 4;; five) echo 5;;
  six) echo 6;; seven) echo 7;; eight) echo 8;; nine) echo 9;; ten) echo 10;;
  eleven) echo 11;; twelve) echo 12;; thirteen) echo 13;; fourteen) echo 14;; fifteen) echo 15;;
  [0-9]*) echo "$1";; *) echo -1;; esac; }

# claim <label> <value-read-from-README> <measured> — the one comparison every check funnels through
claim() {
  local what="$1" said="$2" got="$3"
  if [ "$said" = "-1" ] || [ -z "$said" ]; then bad "$what: no claim found in README.md to check"
  elif [ "$said" = "$got" ]; then ok "$what: README says $said, tree has $got"
  else bad "$what: README says $said, tree has $got"; fi
}

hdr "1. every local link target in README.md resolves"
n=0; miss=0; ext=0
while IFS= read -r l; do
  [ -n "$l" ] || continue
  case "$l" in http*) ext=$((ext+1)); continue;; esac
  n=$((n+1)); [ -e "$l" ] || { bad "link target missing: $l"; miss=$((miss+1)); }
done <<EOF
$(grep -oE '\]\([^)#][^)]*\)' README.md | sed 's/^](//;s/)$//' | sort -u)
EOF
[ "$miss" -eq 0 ] && ok "$n local link targets resolve ($ext external, listed and not fetched)"

hdr "2. the skill counts, as the README states them"
claim "skills/ directory count" \
  "$(w2n "$(printf '%s' "$FLAT" | grep -oE 'holds ([a-z]+) directories' | awk '{print $2}')")" \
  "$(ls -d skills/*/ | wc -l | tr -d ' ')"
claim "invocable skill count (prose)" \
  "$(w2n "$(printf '%s' "$FLAT" | grep -oE '([A-Za-z]+) skills and one shared reference' | awk '{print $1}')")" \
  "$(( $(ls -d skills/*/ | wc -l | tr -d ' ') - $(grep -l 'disable-model-invocation: true' skills/*/SKILL.md | wc -l | tr -d ' ') ))"
claim "invocable skill count (heading)" \
  "$(w2n "$(grep -oE '^## The ([a-z]+) skills' README.md | awk '{print $3}')")" \
  "$(grep -cE '^\| \[`ws-[a-z]+`\]' README.md)"
nw=$(grep -l 'disable-model-invocation: true' skills/*/SKILL.md | sed 's|skills/||;s|/SKILL.md||' | paste -sd' ' -)
[ "$nw" = "ws-shared" ] && ok "ws-shared alone is non-invocable" \
  || bad "README says the fourteenth is ws-shared; non-invocable dirs are: $nw"
diff <(grep -oE '^\| \[`ws-[a-z]+`\]' README.md | tr -d '|[`] ' | sort) \
     <(ls -d skills/*/ | sed 's|skills/||;s|/||' | grep -v '^ws-shared$' | sort) >/dev/null \
  && ok "the table's rows are exactly the invocable skills" \
  || bad "the table and the skill directories disagree"

hdr "3. each table row's 'Ends with' against that skill's own description"
python3 - <<'PY' || fail=1
import io, re, sys
md = io.open("README.md", encoding="utf-8").read()
rows = re.findall(r"^\| \[`(ws-[a-z]+)`\]\([^)]*\) \| ([^|]+) \|", md, re.M)
bad = 0
STOP = {"a","an","the","and","or","never","with","it","you","can","act","on","one","is","to","that","of","in"}
for name, ends in rows:
    fm = io.open(f"skills/{name}/SKILL.md", encoding="utf-8").read().split("---")[1]
    d = " ".join(re.search(r"description: (.*?)(?:\n[a-z-]+:|\Z)", fm, re.S).group(1).split())
    m = re.search(r"Ends with ([^.]*)\.", d)
    if not m:
        print(f"  FAIL   {name}: its own description has no 'Ends with' sentence"); bad = 1; continue
    own = m.group(1).lower()
    cell = [w.strip('`",;:—-()').lower() for w in ends.split()]
    cell = [w for w in cell if w and w not in STOP]
    hit = [w for w in cell if w in own]
    missing = [w for w in cell if w not in own]
    if not hit:
        # shares no content word at all: this is not a paraphrase, it is a different claim
        print(f"  FAIL   {name}: the README cell shares no content word with the skill's own "
              f"sentence. README: {ends.strip()!r}"); bad = 1
    elif missing:
        print(f"  note   {name}: paraphrased — {sorted(missing)} absent from the skill's own sentence")
    else:
        print(f"  ok     {name}")
sys.exit(bad)
PY

hdr "4. the opinions, as the README counts them"
said=$(w2n "$(printf '%s' "$FLAT" | grep -oE 'opinionated in ([a-z]+) ways' | awk '{print $3}')")
sec=$(awk '/^## The opinions/,/^## [^T]/' docs/product/overview.md | grep -c '^### ')
obj=$(awk '/^## The opinions/,/^## [^T]/' docs/product/overview.md | grep -c 'The objection is')
claim "opinion sections in overview.md" "$said" "$sec"
claim "'The objection is' paragraphs"   "$said" "$obj"

hdr "5. the tracker adapters, as the README counts them"
claim "adapter files in ws-shared/trackers/" \
  "$(w2n "$(printf '%s' "$FLAT" | grep -oE 'the ([a-z]+) tracker adapters' | head -1 | awk '{print $2}')")" \
  "$(ls skills/ws-shared/trackers/*.md | grep -cv 'README.md$')"
grep -q '`none`' docs/integration/cartridge-schema.md \
  && ok "kind: none is documented in the cartridge schema" || bad "README claims kind: none; the schema does not document it"

hdr "6. ws-env: the README names how many skills visibly do less without it"
said=$(w2n "$(printf '%s' "$FLAT" | grep -oE '([A-Za-z]+) of them visibly do less' | awk '{print $1}')")
# ws-env/SKILL.md documents its own `pull` mode, so it is excluded: the claim is about callers.
sites=$(grep -ln 'ws-env pull' skills/*/SKILL.md | sed 's|skills/||;s|/SKILL.md||' | grep -v '^ws-env$' | sort)
claim "skills that call ws-env pull" "$said" "$(printf '%s\n' "$sites" | grep -c .)"
for s in $sites; do grep -q "\`$s\`" README.md || bad "$s calls ws-env pull and the README does not name it"; done
printf '  note   call sites: %s\n' "$(printf '%s' "$sites" | paste -sd' ' -)"

hdr "7. degrade-never-fail covers the four cases the README lists"
grep -q 'no cartridge' skills/ws-start/SKILL.md && ok "a missing cartridge" || bad "a missing cartridge has no degrade"
grep -q 'agent key MISSING' skills/ws-env/SKILL.md && ok "a missing key" || bad "a missing key has no degrade"
grep -q 'Unknown kind' skills/ws-start/SKILL.md && ok "an unknown tracker" || bad "an unknown tracker has no degrade"
grep -q 'A tag with no pack is fine' skills/ws-shared/reference.md && ok "a stack with no pack" || bad "a stack with no pack has no degrade"

hdr "8. the gap table: every id open, and every row describing its own task"
tbl=$(awk '/^The gaps a reader would still hit/{f=1} f&&/^\| /{print} f&&/^$/&&NR>1{if(seen)exit} f&&/^\| /{seen=1}' README.md)
ids=$(printf '%s\n' "$tbl" | grep -oE '\| p[0-9]+\.[0-9]+ \|' | tr -d '| ' | sort -u)
[ -n "$ids" ] || bad "no task ids found in the gap table"
for id in $ids; do
  st=$(grep -hoE "^## \[.\] ${id} —" docs/roadmap/*.md | head -1 | sed 's/^## \[\(.\)\].*/\1/')
  case "$st" in
    " ") ok "$id is open" ;;
    "")  bad "$id is in the gap table but not on the roadmap" ;;
    *)   bad "$id is marked [$st] on the roadmap, but the README lists it as an open gap" ;;
  esac
done

hdr "9. the 'N more open tasks' count against the board minus the gap table"
said=$(w2n "$(printf '%s' "$FLAT" | grep -oE '([A-Za-z]+) more open tasks' | awk '{print $1}')")
n_open=$(grep -hcE '^## \[ \] p[0-9]+\.[0-9]+' docs/roadmap/*.md | paste -sd+ - | bc)
n_gap=$(printf '%s\n' "$ids" | grep -c .)
claim "open tasks not in the gap table" "$said" "$((n_open - n_gap))"

hdr "10. other quantities and facts the README states"
# The README does not count the shell files — SECURITY.md and CONTRIBUTING.md do, and they are
# not this script's subject. Checked there instead, by hand, and both were wrong: see the worklog.
claim "rejected alternatives in ADR 0001" \
  "$(w2n "$(printf '%s' "$FLAT" | grep -oE 'the ([a-z]+) rejected alternatives' | awk '{print $2}')")" \
  "$(awk '/^## Rejected/,0' docs/decisions/0001-library-is-the-source-of-truth.md | grep -c '^\*\*')"
# The disposition of those 44, as the README states it, against p7.1's own acceptance criteria.
# Added because I got this sentence wrong twice: the two tasks the stranger run filed were p8.35
# and p8.36 (both since shipped), not the two newest rows in the gap table.
P7FLAT=$(tr '\n' ' ' < docs/roadmap/P7-release.md | tr -s ' ')
disp() { # disp <label> <README noun phrase> <roadmap noun phrase>
  local said got
  said=$(printf '%s' "$FLAT"   | grep -oE "(one|two|three|four|five|six|seven|eight|nine|ten) $2" | head -1 | awk '{print $1}')
  got=$(printf  '%s' "$P7FLAT" | grep -oE "[0-9]+ $3" | head -1 | awk '{print $1}')
  claim "stranger-run disposition: $1" "$(w2n "${said:-}")" "${got:--1}"
}
disp "INSTALL.md fixes" '`INSTALL\.md` fixes' '`INSTALL\.md` fixes'
disp "limitations"      'limitations'          'limitations'
disp "tasks filed"      'tasks'                'tasks'

claim "guess-points, README vs the record it cites" \
  "$(printf '%s' "$FLAT" | grep -oE '([0-9]+) points where they had to guess' | awk '{print $1}')" \
  "$(grep -oE '\*\*[0-9]+ distinct guess-points\*\*' docs/records/2026-11-02-stranger-install-dry-run.md | head -1 | grep -oE '[0-9]+')"
# the Node floor the README states, against agent-sync's own engines field
said=$(printf '%s' "$FLAT" | grep -oE 'Node ([0-9]+)\+' | head -1 | grep -oE '[0-9]+')
as_pkg=""
if as_bin=$(command -v agent-sync 2>/dev/null); then
  d=$(dirname "$(python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$as_bin")")
  while [ "$d" != "/" ]; do [ -f "$d/package.json" ] && { as_pkg="$d/package.json"; break; }; d=$(dirname "$d"); done
fi
if [ -n "$as_pkg" ]; then
  claim "Node floor" "$said" "$(python3 -c 'import json,io,sys,re;e=(json.load(io.open(sys.argv[1])).get("engines") or {}).get("node","");print(re.sub(r"[^0-9]","",e) or -1)' "$as_pkg")"
else
  bad "Node floor: agent-sync is not on PATH, so the README's 'Node ${said}+' could not be checked"
fi
# the licence the README names, against LICENSE itself
said=$(printf '%s' "$FLAT" | grep -oE '(MIT|Apache-2\.0|BSD-[0-9]-Clause|GPL-[0-9.]+) — see \[LICENSE\]' | awk '{print $1}')
got=$(head -1 LICENSE | sed 's/ License$//')
[ -n "$said" ] && [ "$said" = "$got" ] && ok "licence: README says $said, LICENSE says $got" \
  || bad "licence: README says '${said:-nothing}', LICENSE says '$got'"
# publish.sh and ws-refine, as the README describes them
grep -q 'die()' scripts/publish.sh && ok "publish.sh has a refusal path" || bad "README says publish.sh refuses; it has no die()"
grep -qi 'publish' skills/ws-refine/SKILL.md && ok "ws-refine has a publish step" || bad "README says ws-refine runs the publish as a step"
grep -qi 'answer only the user can give' INSTALL.md && ok "INSTALL.md stops for what only the user can answer" \
  || bad "README says INSTALL.md stops; no such stop found"

printf '\n== result ==\n'
if [ "$fail" -eq 0 ]; then echo "  every checkable README claim holds against $R"; exit 0
else echo "  AT LEAST ONE CLAIM FAILED against $R"; exit 1; fi
