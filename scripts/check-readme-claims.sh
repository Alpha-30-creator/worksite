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
# What it does NOT check: anything that is a judgement rather than a fact — whether the argument
# in overview.md is convincing, whether a paraphrase in the skill table is fair (it reports those
# as `note`, not `FAIL`), or whether a claim is true of a stranger's machine rather than this
# tree. p7.1 measured that last gap at 44 guess-points.
set -u
R="${1:?usage: claims.sh <tree-dir>}"
cd "$R" || exit 1
fail=0
ok()   { printf '  ok     %s\n' "$*"; }
bad()  { printf '  FAIL   %s\n' "$*"; fail=1; }
hdr()  { printf '\n== %s ==\n' "$*"; }

hdr "1. every link target in README.md resolves"
n=0; miss=0
while IFS= read -r l; do
  case "$l" in http*) continue;; esac
  n=$((n+1)); [ -e "$l" ] || { bad "link target missing: $l"; miss=$((miss+1)); }
done <<EOF
$(grep -oE '\]\([^)#][^)]*\)' README.md | sed 's/^](//;s/)$//' | sort -u)
EOF
[ "$miss" -eq 0 ] && ok "$n local link targets, all resolve"

hdr "2. the skill counts"
d=$(ls -d skills/*/ | wc -l | tr -d ' ')
[ "$d" = 14 ] && ok "skills/ holds 14 directories" || bad "skills/ holds $d, README says fourteen"
ni=$(grep -l 'disable-model-invocation: true' skills/*/SKILL.md | wc -l | tr -d ' ')
nw=$(grep -l 'disable-model-invocation: true' skills/*/SKILL.md | sed 's|skills/||;s|/SKILL.md||')
{ [ "$ni" = 1 ] && [ "$nw" = ws-shared ]; } \
  && ok "ws-shared alone carries disable-model-invocation: true" \
  || bad "expected ws-shared alone to be non-invocable; got $ni ($nw)"
rows=$(grep -cE '^\| \[`ws-[a-z]+`\]' README.md)
[ "$rows" = 13 ] && ok "the skill table has 13 rows" || bad "the skill table has $rows rows, README says thirteen"
diff <(grep -oE '^\| \[`ws-[a-z]+`\]' README.md | tr -d '|[`] ' | sort) \
     <(ls -d skills/*/ | sed 's|skills/||;s|/||' | grep -v '^ws-shared$' | sort) >/dev/null \
  && ok "the 13 table rows are exactly the 13 invocable skills" \
  || bad "the table and the directories disagree"

hdr "3. each table row's 'Ends with' is faithful to that skill's own description"
python3 - <<'PY'
import io, re, sys
md = io.open("README.md", encoding="utf-8").read()
rows = re.findall(r"^\| \[`(ws-[a-z]+)`\]\([^)]*\) \| ([^|]+) \|", md, re.M)
bad = 0
for name, ends in rows:
    fm = io.open(f"skills/{name}/SKILL.md", encoding="utf-8").read().split("---")[1]
    d = " ".join(re.search(r"description: (.*?)(?:\n[a-z-]+:|\Z)", fm, re.S).group(1).split())
    m = re.search(r"Ends with ([^.]*)\.", d)
    if not m:
        print(f"  FAIL   {name}: its description has no 'Ends with' sentence"); bad = 1; continue
    # every content word of the README cell must appear in the skill's own sentence
    stop = {"a","an","the","and","or","never","with","it","you","can","act","on","one"}
    cell = {w.strip('`",;—-').lower() for w in ends.split()} - stop
    own  = m.group(1).lower()
    missing = [w for w in cell if w and w not in own]
    if missing:
        print(f"  note   {name}: paraphrased — README words absent from the skill's own sentence: {sorted(missing)}")
    else:
        print(f"  ok     {name}")
sys.exit(bad)
PY
[ "$?" -eq 0 ] || fail=1

hdr "4. the four opinions, each with its objection"
nop=$(awk '/^### Gates that stop/,/^## Four design moves/' docs/product/overview.md | grep -c '^### ')
nobj=$(awk '/^### Gates that stop/,/^## Four design moves/' docs/product/overview.md | grep -c 'The objection is')
{ [ "$nop" = 4 ] && [ "$nobj" = 4 ]; } \
  && ok "4 opinions, 4 'The objection is'" || bad "opinions=$nop objections=$nobj, README says four of each"

hdr "5. the tracker adapters"
na=$(ls skills/ws-shared/trackers/*.md | grep -cv 'README.md$')
[ "$na" = 4 ] && ok "4 adapter files" || bad "$na adapter files, README says four"
grep -q '`none`' docs/integration/cartridge-schema.md \
  && ok "kind: none is in the schema's tracker.kind enum" || bad "kind: none is not documented"

hdr "6. ws-env is invoked from exactly the two OTHER skills the README names"
# ws-env/SKILL.md documents its own `pull` mode, so it is excluded: the claim is about the skills
# that CALL it. An earlier version of this check did not exclude it and failed for that reason.
sites=$(grep -ln 'ws-env pull' skills/*/SKILL.md | sed 's|skills/||;s|/SKILL.md||' \
        | grep -v '^ws-env$' | sort | paste -sd' ' -)
[ "$sites" = "ws-start ws-sync" ] \
  && ok "ws-env pull is called from ws-start and ws-sync, and nowhere else" \
  || bad "ws-env pull call sites (excluding ws-env itself) are: $sites (README names ws-sync and ws-start)"

hdr "7. degrade-never-fail covers the four cases the README lists"
grep -q 'no cartridge' skills/ws-start/SKILL.md && ok "missing cartridge" || bad "missing cartridge has no degrade"
grep -q 'agent key MISSING' skills/ws-env/SKILL.md && ok "missing key" || bad "missing key has no degrade"
grep -q 'Unknown kind' skills/ws-start/SKILL.md && ok "unknown tracker" || bad "unknown tracker has no degrade"
grep -q 'A tag with no pack is fine' skills/ws-shared/reference.md && ok "a stack with no pack" || bad "no-pack has no degrade"

hdr "8. the gap table names only OPEN tasks"
ids=$(awk '/^The gaps a reader would still hit/,/^Three more open tasks/' README.md \
      | grep -oE 'p[0-9]+\.[0-9]+' | sort -u)
[ -n "$ids" ] || bad "no task ids found in the gap table"
for id in $ids; do
  st=$(grep -hoE "^## \[.\] ${id} —" docs/roadmap/*.md | head -1 | sed 's/^## \[\(.\)\].*/\1/')
  case "$st" in
    " ") ok "$id is open" ;;
    "")  bad "$id is not on the roadmap at all" ;;
    *)   bad "$id is marked [$st] on the roadmap, but the README lists it as an open gap" ;;
  esac
done

hdr "9. the 'N more open tasks' count matches the board minus the gap table"
words='zero one two three four five six seven eight nine ten'
stated=$(grep -oE '^(Zero|One|Two|Three|Four|Five|Six|Seven|Eight|Nine|Ten) more open tasks' README.md \
         | awk '{print tolower($1)}')
if [ -z "$stated" ]; then
  bad "README has no 'N more open tasks' sentence to check"
else
  n_open=$(grep -hcE '^## \[ \] p[0-9]+\.[0-9]+' docs/roadmap/*.md | paste -sd+ - | bc)
  n_gap=$(awk '/^The gaps a reader would still hit/,/more open tasks/' README.md \
          | grep -oE 'p[0-9]+\.[0-9]+' | sort -u | wc -l | tr -d ' ')
  # p7.2 itself is still open while this runs pre-merge; at the tag it is closed, so allow both
  want=$((n_open - n_gap))
  idx=0; num=""
  for w in $words; do [ "$idx" = "$want" ] && num="$w"; idx=$((idx+1)); done
  idx=0; num1=""
  for w in $words; do [ "$idx" = "$((want-1))" ] && num1="$w"; idx=$((idx+1)); done
  if [ "$stated" = "$num" ]; then
    ok "README says '$stated more open tasks'; board has $n_open open, $n_gap in the gap table"
  elif [ "$stated" = "$num1" ]; then
    ok "README says '$stated more open tasks' — matches once the task being shipped closes ($n_open open now)"
  else
    bad "README says '$stated more open tasks', but the board has $n_open open and $n_gap are in the gap table (expected '$num', or '$num1' pre-merge)"
  fi
fi

hdr "10. other spot claims"
as_pkg=""
if as_bin=$(command -v agent-sync 2>/dev/null); then
  as_real=$(python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$as_bin")
  d=$(dirname "$as_real")
  while [ "$d" != "/" ]; do
    [ -f "$d/package.json" ] && { as_pkg="$d/package.json"; break; }
    d=$(dirname "$d")
  done
fi
if [ -n "$as_pkg" ]; then
  python3 - "$as_pkg" <<'EOP'
import json, io, sys
e = (json.load(io.open(sys.argv[1])).get("engines") or {}).get("node", "")
print(f"  ok     agent-sync engines node {e}" if e == ">=20"
      else f"  FAIL   agent-sync engines node is {e!r}, README says 20+")
sys.exit(0 if e == ">=20" else 1)
EOP
  [ "$?" -eq 0 ] || fail=1
else
  printf '  skip   agent-sync is not on PATH here, so its engines field was not read\n'
fi
grep -q '^MIT License' LICENSE && ok "LICENSE is MIT" || bad "LICENSE is not MIT"
grep -q 'stack: \[\]' docs/agent/reference.md && ok "this repo's cartridge has stack: []" || bad "stack: [] not found"
np=$(awk '/^## Rejected/,0' docs/decisions/0001-library-is-the-source-of-truth.md | grep -c '^\*\*')
[ "$np" = 2 ] && ok "ADR 0001 has exactly 2 rejected alternatives" || bad "ADR 0001 has $np rejected alternatives, README says two"
grep -qi 'answer only the user can give' INSTALL.md && ok "INSTALL.md stops for what only the user can answer" || bad "INSTALL.md has no such stop"

printf '\n== result ==\n'
[ "$fail" -eq 0 ] && { echo "  every checkable README claim holds against $R"; exit 0; } \
                  || { echo "  AT LEAST ONE CLAIM FAILED against $R"; exit 1; }
