#!/usr/bin/env bash
# Check every checkable claim in README.md against a tree. Usage:
#
#     bash scripts/check-readme-claims.sh <tree-dir>
#
# Exits non-zero if any claim fails, so it can gate a tag. Written for p7.2, whose single
# acceptance criterion was "the README's claims all verified against the tagged tree", and kept
# here rather than in that task's scratch so the next tag does not re-derive it by hand.
#
# THIS IS NOT A SECOND `verify`. There is one gate, `scripts/check.sh` (AGENTS.md), and since
# p7.3 this script IS one of its sections — section 7 calls it, indents its output and fails the
# gate on a non-zero exit. It stays a separate file because this much claim-reading inside
# check.sh would make the gate unreadable, not because it is optional. Run it directly against
# any tree (`bash scripts/check-readme-claims.sh <dir>`) to check a tag or a candidate clone.
#
# THREE DISPOSITIONS, and the difference between the last two is the whole point:
#   ok         the claim was read out of README.md and holds against the tree;
#   FAIL       it was read and does not hold — OR no claim matching the pattern was found at all,
#              which means the README moved out from under the check and is never forgiven;
#   UNCHECKED  a TOOL this check needs is absent here, so it did not look. Counted, named in the
#              result line, and not a failure — otherwise CI, where `agent-sync` is not installed,
#              goes red on a README that is perfectly true (p7.3).
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
# Every disposition is COUNTED by the function that reports it, and the totals are printed as
# one machine-readable line at the end. check.sh reads that line and refuses its absence.
#
# It used to re-derive those totals by grepping this script's output, and a review broke that in
# one line: reverting hdr()'s `--` to `==` made check.sh report "0 claim group(s)" and call it ok,
# because its `grep -c '^-- [0-9]'` matched nothing. A count derived from another program's
# formatting is a count that goes to zero when the formatting moves, and zero read as a pass is
# the defect class this whole script belongs to. Counting here, where the formatting lives, is the
# only version that cannot drift apart.
ngroup=0; nok=0; nnote=0; unchecked=0; UNCHECKED_NAMES=""
ok()  { printf '  ok     %s\n' "$*"; nok=$((nok+1)); }
bad() { printf '  FAIL   %s\n' "$*"; fail=1; }
note(){ printf '  note   %s\n' "$*"; nnote=$((nnote+1)); }
hdr() { printf '\n-- %s --\n' "$*"; ngroup=$((ngroup+1)); }
# A claim this environment cannot check. NOT a failure, and NOT silent: see the header. $2 is how
# many individual claims went unread, defaulting to one — group 3 stands for all thirteen
# skill-table rows at once, and reporting that as "1 not checked" understated it by twelve.
unknown(){ printf '  UNCHECKED  %s\n' "$1"; unchecked=$((unchecked+${2:-1}))
           UNCHECKED_NAMES="$UNCHECKED_NAMES
  - $1"; }
# The tools the checks below need. A missing tool makes a claim UNCHECKED, never ok — and never a
# FAILURE either, which is the contract stated above and the reason section 7 does not turn CI red.
#
# python3 is probed by RUNNING it, not by `command -v`. `command -v python3` succeeds for a python3
# that cannot run, which is the ordinary macOS state with no Command Line Tools: it prints
# "xcrun: error: invalid active developer path" and exits 1. Measured, that shape took the HAVE_PY=1
# branch, produced no output, and was reported as "a README claim does not hold" — a tool failure
# diagnosed as a false README, which is the contract inverted. It is `python3 -c pass`, not
# `--version`, because a stub that answers --version and runs nothing would still pass.
#
# mktemp is needed by that same block and is probed the same way, for the same reason: its absence
# used to reach the same hard FAIL.
HAVE_PY=0;     command -v python3 >/dev/null 2>&1 && python3 -c 'pass' >/dev/null 2>&1 && HAVE_PY=1
# mktemp is probed by MAKING A FILE with the exact template group 3 uses, not by `command -v`,
# which is the same lesson as python3 one line up and was learned the same way twice. `mktemp -t
# wsclaims` works on BSD mktemp and GNU mktemp refuses it ("too few X's in template"), so the
# first version was macOS-only; CI caught it, which is the only environment here that is not
# macOS. Presence was never the question — whether it does the job is.
HAVE_MKTEMP=0
if _mkt=$(mktemp "${TMPDIR:-/tmp}/wsclaims.XXXXXX" 2>/dev/null) && [ -f "$_mkt" ]; then
  HAVE_MKTEMP=1; rm -f "$_mkt"
fi
# Kept apart rather than folded into one flag: the first version set a single HAVE_PY from both,
# so with mktemp missing it reported "no working python3 here" about a python3 that works fine.
# A message that names the wrong missing tool sends the reader to install the wrong thing.
_whynopy() {
  # "no WORKING x" throughout: both probes run the tool, so neither can distinguish absent from
  # present-and-unable, and both were reached by a tool that was present (see above).
  if [ "$HAVE_PY" -eq 0 ] && [ "$HAVE_MKTEMP" -eq 0 ]; then echo "no working python3 and no working mktemp here"
  elif [ "$HAVE_PY" -eq 0 ]; then echo "no working python3 here"
  else echo "no working mktemp here"; fi
}

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
if [ "$HAVE_PY" -eq 0 ] || [ "$HAVE_MKTEMP" -eq 0 ]; then
  # Counted from the README, not written here: this script's own header forbids holding a
  # quantity it is supposed to be reading, and an UNCHECKED message is no exception.
  nrows=$(grep -cE '^\| \[`ws-[a-z]+`\]' README.md)
  unknown "the skill-table paraphrases: $(_whynopy), so all $nrows rows went unread" "$nrows"
else
# The python block writes to a temp file rather than into $( ), which keeps python's exit status
# and its output separable with no pipeline in between.
#
# An earlier draft of this block DID use `$( )` and `bash -n` refused it, pointing at an unrelated
# `case` eighty lines further down. The first version of this comment blamed heredocs inside
# command substitution on bash 3.2; a reviewer could not reproduce that across five shapes and
# neither could I across two more, and `0f0e791`'s own checker parses clean on 3.2. **So the cause
# is not established**, and no mechanism is claimed here rather than teaching a false one. Keep
# the temp file; if you move this back into `$( )`, run `bash -n` under /bin/bash before trusting
# it, and do not trust the line number it gives you.
# NOT `mktemp -t wsclaims`: BSD mktemp accepts a bare prefix and GNU mktemp refuses it with
# "too few X's in template", so that form works on macOS and fails on every Linux. Shipped, and
# caught by CI — the one environment this is not developed in — which is the cross-platform trap
# this pack documents, committed by the author who documented it. A full template with six X's is
# accepted by both.
PY3OUT_F="$(mktemp "${TMPDIR:-/tmp}/wsclaims.XXXXXX")"
trap 'rm -f "$PY3OUT_F"' EXIT INT TERM    # it is removed below too; this covers an interrupt
python3 - > "$PY3OUT_F" <<'PY'
import io, re, sys
md = io.open("README.md", encoding="utf-8").read()
rows = re.findall(r"^\| \[`(ws-[a-z]+)`\]\([^)]*\) \| ([^|]+) \|", md, re.M)
bad = 0; nok = 0; nnote = 0
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
        nnote += 1
    else:
        print(f"  ok     {name}")
        nok += 1
# Counted here, by the code that prints, for the same reason the shell counts its own: a total
# re-derived from someone else's output formatting goes to zero when the formatting moves.
print(f"__counts__ ok={nok} note={nnote}")
sys.exit(bad)
PY
PY3RC=$?
  grep -v '^__counts__ ' "$PY3OUT_F"
  PY3COUNTS="$(sed -n 's/^__counts__ //p' "$PY3OUT_F" | tail -1)"
  rm -f "$PY3OUT_F"
  [ "$PY3RC" -eq 0 ] || fail=1
  if [ -z "$PY3COUNTS" ]; then
    bad "the skill-table paraphrase check printed no count line, so how many of its rows it read is UNKNOWN"
  else
    nok=$((nok  + $(printf '%s' "$PY3COUNTS" | sed -n 's/.*ok=\([0-9]*\).*/\1/p')))
    nnote=$((nnote + $(printf '%s' "$PY3COUNTS" | sed -n 's/.*note=\([0-9]*\).*/\1/p')))
  fi
fi

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
note "call sites: $(printf '%s' "$sites" | paste -sd' ' -)"

hdr "7. degrade-never-fail covers the four cases the README lists"
grep -q 'no cartridge' skills/ws-start/SKILL.md && ok "a missing cartridge" || bad "a missing cartridge has no degrade"
grep -q 'agent key MISSING' skills/ws-env/SKILL.md && ok "a missing key" || bad "a missing key has no degrade"
grep -q 'Unknown kind' skills/ws-start/SKILL.md && ok "an unknown tracker" || bad "an unknown tracker has no degrade"
grep -q 'A tag with no pack is fine' skills/ws-shared/reference.md && ok "a stack with no pack" || bad "a stack with no pack has no degrade"

# THE OPEN SET, defined once and read by BOTH groups 8 and 9, so the two cannot drift apart. The
# project's six markers are defined in `skills/ws-shared/trackers/roadmap-files.md`,
# `docs/roadmap/README.md` and `docs/integration/cartridge-schema.md`: `[ ]` open, `[~]` claimed,
# `[r]` PR open, `[x]` done, `[-]` dropped, `[?]` blocked on a decision. The first FOUR of those
# — `[?]` included — are still an open gap to a reader, which is who the gap table is for.
#
# Until p7.3 only `[ ]` counted, so merely CLAIMING a task failed both groups; measured, with
# `[~]` on p7.3 for group 9 and on the gap-table row p8.30 for group 8. The first fix then listed
# five markers and asserted "only [x] and [-] are closed", which a review disproved from the
# definition: `[?]` was missing, so marking any task blocked refused every commit. Both halves of
# that are recorded because the second is the more instructive — the set was enumerated from
# memory when the repo defines it three times over.
# A review then found that the first version of this "defined once" was a lie: group 8 enumerated
# its own four arms and never read OPEN_RE, so editing the one definition changed group 9 alone —
# demonstrated by narrowing it to '[ ~r]' and watching group 8 keep calling a `[?]` row open while
# group 9 started failing. Group 8 now tests membership against OPEN_RE and uses its own `case`
# only for the WORDING, which cannot drift into disagreement because a marker that is not in
# OPEN_RE never reaches it.
OPEN_RE='[ ~r?]'
hdr "8. the gap table: every id open, and every row describing its own task"
tbl=$(awk '/^The gaps a reader would still hit/{f=1} f&&/^\| /{print} f&&/^$/&&NR>1{if(seen)exit} f&&/^\| /{seen=1}' README.md)
ids=$(printf '%s\n' "$tbl" | grep -oE '\| p[0-9]+\.[0-9]+ \|' | tr -d '| ' | sort -u)
[ -n "$ids" ] || bad "no task ids found in the gap table"
for id in $ids; do
  st=$(grep -hoE "^## \[.\] ${id} —" docs/roadmap/*.md | head -1 | sed 's/^## \[\(.\)\].*/\1/')
  if [ -z "$st" ]; then
    bad "$id is in the gap table but not on the roadmap"
  elif printf '%s' "$st" | grep -qE "^$OPEN_RE$"; then
    # In the open set, so the only question left is how to say it. These arms carry wording only;
    # a marker absent from OPEN_RE cannot reach them.
    case "$st" in
      " ") ok "$id is open" ;;
      "~") ok "$id is open (claimed, [~])" ;;
      "r") ok "$id is open (PR open, [r])" ;;
      "?") ok "$id is open (blocked on a decision, [?])" ;;
      *)   ok "$id is open (marker [$st], in the open set)" ;;
    esac
  else
    case "$st" in
      "x"|"-") bad "$id is marked [$st] on the roadmap, but the README lists it as an open gap" ;;
      # Said as an unrecognised marker rather than as "closed". A marker this script has not been
      # taught is not evidence that the task is done, and reading it as such is how `[?]` came to
      # refuse every commit.
      *) bad "$id carries the marker [$st], which this check does not recognise — see the six in skills/ws-shared/trackers/roadmap-files.md" ;;
    esac
  fi
done

hdr "9. the 'N more open tasks' count against the board minus the gap table"
said=$(w2n "$(printf '%s' "$FLAT" | grep -oE '([A-Za-z]+) more open tasks' | awk '{print $1}')")
# $OPEN_RE, so this and group 8 share one definition of "open" (see the block above group 8).
# awk rather than `bc`: bc is an undeclared dependency, and where it is absent the sum comes back
# EMPTY, which reaches `claim` as a measurement rather than as "I could not count".
n_open=$(grep -hcE "^## \\[$OPEN_RE\\] p[0-9]+\\.[0-9]+" docs/roadmap/*.md | awk '{t += $1} END {print t + 0}')
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
as_bin=""
if [ "$HAVE_PY" -eq 1 ] && as_bin=$(command -v agent-sync 2>/dev/null); then
  # `command -v python3` succeeds for a python3 that cannot RUN — the ordinary macOS state with
  # no Command Line Tools installed, where it prints "xcrun: error: invalid active developer
  # path" and exits 1. The realpath then comes back empty, `dirname ""` is `.`, `dirname "."` is
  # `.`, and the walk below never reaches `/`: an unbounded loop with no output and no timeout.
  # It predates p7.3 and was harmless while nothing ran this script. Section 7 runs it in
  # `verify`, in the pre-commit hook and at all three publish sites, so it would now HANG every
  # one of them. Measured; the loop was watched not reaching `/` over six iterations.
  d=$(python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$as_bin" 2>/dev/null)
  case "$d" in /*) d=$(dirname "$d") ;; *) d="" ;; esac   # anything not absolute: do not walk it
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    [ -f "$d/package.json" ] && { as_pkg="$d/package.json"; break; }
    _parent=$(dirname "$d")
    [ "$_parent" = "$d" ] && break      # a belt-and-braces floor: dirname is a fixed point here
    d="$_parent"
  done
fi
# The README's Node floor is checked against agent-sync's OWN `engines` field, so this claim is
# only checkable where agent-sync is installed. It is UNCHECKED elsewhere, not false: it was a
# hard failure until p7.3, and section 7 of check.sh would then have turned CI — which has no
# agent-sync — red on a README that holds. The tool's absence is reported by name instead.
if [ -z "$said" ]; then
  bad "Node floor: no 'Node N+' claim found in README.md to check"
elif [ "$HAVE_PY" -eq 0 ]; then
  unknown "Node floor: no working python3 here, so agent-sync's engines field went unread"
elif [ -n "$as_pkg" ]; then
  claim "Node floor" "$said" "$(python3 -c 'import json,io,sys,re;e=(json.load(io.open(sys.argv[1])).get("engines") or {}).get("node","");print(re.sub(r"[^0-9]","",e) or -1)' "$as_pkg")"
elif [ -z "${as_bin:-}" ]; then
  unknown "Node floor: agent-sync is not on PATH, so the README's 'Node ${said}+' went unread"
else
  # On PATH but with no package.json above it — an installed binary, a shim, a symlink out of a
  # tree that was moved. Said as what it is: the first draft reported this as "not on PATH",
  # which sends the reader to install something they already have.
  unknown "Node floor: agent-sync is at ${as_bin} but no package.json was found above it, so its engines field went unread"
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

# The machine-readable self-report check.sh reads. Counted by the reporting functions above, so
# it cannot disagree with what was printed, and its ABSENCE is a refusal on the other side.
printf '\n-- counts -- groups=%s ok=%s note=%s unchecked=%s fail=%s\n' \
  "$ngroup" "$nok" "$nnote" "$unchecked" "$fail"
printf '\n-- result --\n'
# ADR 0004: certify only what was stated as read. The unchecked set is printed on both paths —
# on the failing path too, because "one claim failed" over a partially-read README is a different
# statement from "one claim failed" over a fully-read one.
if [ "$unchecked" -gt 0 ]; then
  echo "  $unchecked claim(s) NOT checked here, for want of a tool:$UNCHECKED_NAMES"
fi
if [ "$fail" -eq 0 ]; then
  if [ "$unchecked" -gt 0 ]; then
    echo "  every OTHER checkable README claim holds against $R"
  else
    echo "  every checkable README claim holds against $R"
  fi
  exit 0
else echo "  AT LEAST ONE CLAIM FAILED against $R"; exit 1; fi
