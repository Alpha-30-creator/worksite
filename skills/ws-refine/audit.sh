#!/usr/bin/env bash
# The ws-refine graph audit. Run it, do not read it out of a skill and paste it:
#
#     bash "$HOME/.agent-sync/store/skills/ws-refine/audit.sh"
#
# WHY THIS IS A FILE AND NOT A FENCED BLOCK IN ws-refine/SKILL.md, where it lived until
# 2026-11-03: a skill's body has the caller's argument string substituted into its positional
# parameters on the way to the agent. The awk programs below use $0 as a field reference, so
# invoked as `/ws-refine <anything>` the delivered copy arrived with `if($0!="---")` rewritten to
# `if(<a word from the argument>!="---")`, which awk cannot parse. Part 3 then produced a
# spurious finding for every skill — noisy, survivable — and **part 3b reported no findings at
# all while its scanner had never run**, with its own denominator intact, because the count was
# incremented before the scan. A clean verdict over a scan that did not happen: the exact shape
# part 3b was added to catch. Nothing substitutes into a file read or run by path, which is the
# single property this file buys (p8.37).
#
# It is run with `bash <path>`, never executed directly, so no execute bit has to survive a copy,
# a publish or a filesystem that does not carry one.
#
# ONE SCRIPT, ONE SHELL, run whole — the later parts read counts the earlier parts established.
# Parts 1 and 2 are GATES: they decide whether a verdict is available at all. Parts 3 to 7 are the
# checks. Part 8 is the verdict, and it names its own counts.
#
# NOT `set -e`, and this is worth saying because it is the first thing anyone will reach for: a
# CLEAN part ends on `[ -n "$x" ] && printf ...`, which returns NON-ZERO precisely when there are
# no findings. Under set -e this script would abort exactly when the audit is clean.
set -uo pipefail

# ---- part 1: is what you are about to audit actually deployed? ----
# The state of a ws-* artifact is operations[].reason, filtered to refs starting "skill/ws-".
# Three fields are NOT read, each verified against real output rather than assumed:
#   "ok"       — true while artifacts are drifted. It means "the command ran".
#   "exitCode" — counts only "ask" operations. It is non-zero when unrelated artifacts have
#                drifted, so a gate keyed on it aborts every ws-* audit for reasons that have
#                nothing to do with ws-*; and it is 0 while an "outdated" ws-* write is pending,
#                which is exactly the state between an edit and the save. Unusable both ways.
#   "targets[]"— its rows carry no state field at all, so a state read from there is empty on
#                every row and reads as "nothing wrong".
# Do not "simplify" this back to any of the three.
st=$(agent-sync status --json 2>/dev/null)   # exit code deliberately not read — see above
[ -n "$st" ] \
  || { echo "AUDIT ABORTED: agent-sync status --json produced no output"; exit 1; }
printf '%s' "$st" | python3 -c '
import json,sys
try: d=json.load(sys.stdin)
except Exception as e:
    print("AUDIT ABORTED: could not parse agent-sync status --json (%s)" % e); raise SystemExit(1)
refs={str(t.get("ref","")) for t in d.get("targets",[]) if str(t.get("ref","")).startswith("skill/ws-")}
if not refs:
    print("AUDIT ABORTED: agent-sync reports no skill/ws-* targets at all"); raise SystemExit(1)
bad=False
for o in d.get("operations",[]):
    if not str(o.get("ref","")).startswith("skill/ws-"): continue
    r=o.get("reason") or "unknown"
    print("AUDIT ABORTED: %s is %s under %s%s" % (o.get("ref"), r, o.get("agent"),
          "" if r=="conflicted" else " (pending)")); bad=True
if bad: raise SystemExit(1)
print("agent-sync: %d ws-* artifacts, 0 pending" % len(refs))
' || exit 1

# ---- part 2: preflight — establish WHAT you are reading, before reading it ----
lib="$HOME/.agent-sync/store/skills"
cd "$lib" 2>/dev/null || { echo "AUDIT ABORTED: cannot enter the library at $lib"; exit 1; }
here=$(pwd -P)
# Identity against the store agent-sync ITSELF reports, not against the string two lines up:
# comparing that string with itself is a tautology that passes wherever the cd landed, which is
# no assertion at all. doctor --json emits "store". It does NOT emit "healthy".
store=$(agent-sync doctor --json 2>/dev/null | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("store") or "")
except Exception: print("")')
[ -n "$store" ] \
  || { echo "AUDIT ABORTED: agent-sync reported no store path to check the cwd against"; exit 1; }
want=$(cd "$store/skills" 2>/dev/null && pwd -P)
[ -n "$want" ] && [ "$here" = "$want" ] \
  || { echo "AUDIT ABORTED: cwd is $here, not the library agent-sync reports at $store/skills"; exit 1; }
# The marker and the floor catch a different failure from the identity check above: the RIGHT
# directory holding the WRONG contents — a gutted or half-deleted store, which identity passes.
[ -r ws-shared/SKILL.md ] \
  || { echo "AUDIT ABORTED: no readable ws-shared/SKILL.md under $here — this is not the pack"; exit 1; }
# -f AND -r, and both halves earn their place. -r because a mode-000 SKILL.md is a skill this
# audit cannot read, so it must not be counted. -f because a DIRECTORY named SKILL.md is readable,
# and awk over a directory exits 0 having read no records — so without it the scan of that skill
# finds nothing, reports nothing, and still increments every count, which is a clean verdict over
# a file never read. Measured on BSD awk 20200816 (p8.37).
# But it must not be dropped SILENTLY either: nd counts the ws-* directories that exist and n the
# ones that are readable, and the difference is reported. Noticing a missing skill by knowing
# today's count by heart is exactly the bookkeeping the floor below refuses to be.
nd=0; n=0; unread=""
for d in ws-*/; do [ -d "$d" ] || continue
  nd=$((nd+1))
  if [ -f "${d}SKILL.md" ] && [ -r "${d}SKILL.md" ]; then n=$((n+1))
  else unread="${unread}UNREADABLE SKILL: ${d%/} has no readable SKILL.md — it is NOT in any count below
"
  fi
done
[ -n "$unread" ] && printf '%s' "$unread"
# The floor is "the pack, not a fragment". Never today's exact count — that would fail the audit
# on any deliberate addition or removal, which is bookkeeping, and bookkeeping rots.
[ "$n" -ge 10 ] \
  || { echo "AUDIT ABORTED: $n readable ws-*/SKILL.md under $here — expected the whole pack"; exit 1; }
echo "auditing $n of $nd ws-* directories under $here"

# ---- part 3: frontmatter, and whether it CLOSED ----
# nfm is carried to the verdict so "0 frontmatter findings" cannot be confused with "I parsed
# nothing". An unclosed frontmatter block is a finding in its own right and belongs here: every
# later check that tracks the "---" delimiter reads such a file as EMPTY, which is how a file
# gets counted as checked with nothing in it.
fm=""; nfm=0
for d in ws-*/; do d=${d%/}; f="$d/SKILL.md"; { [ -f "$f" ] && [ -r "$f" ]; } || continue
  nfm=$((nfm+1))
  nm=$(sed -n 's/^name: *//p' "$f" | head -1)
  len=$(sed -n 's/^description: *//p' "$f" | head -1 | wc -c | tr -d ' ')
  [ "$nm" = "$d" ] || fm="${fm}NAME MISMATCH: $d -> $nm
"
  { [ "$len" -gt 1 ] && [ "$len" -lt 1024 ]; } \
    || fm="${fm}DESCRIPTION PROBLEM: $d ($len)
"
  # NOT named "st": that holds part 1's agent-sync JSON, which part 7 still needs. Reusing it
  # here emptied part 7's input, and part 7's own completion sentinel is what caught it.
  fmst=$(awk 'NR==1{if($0!="---"){r="no-open"; exit}; next} $0=="---"{r="ok"; exit}
              END{if(r=="")r="no-close"; print r}' "$f")
  [ "$fmst" = "ok" ] \
    || fm="${fm}FRONTMATTER $fmst: $d — every check that tracks the delimiter reads this file as empty
"
done
[ -n "$fm" ] && printf '%s' "$fm"

# ---- part 3b: no positional parameter in a skill body ----
# A positional parameter inside a SKILL.md is replaced by the caller's argument before the agent
# ever sees it: invoke the skill with arguments and the snippet arrives corrupted, while the file
# on disk stays perfect. ws-env and ws-sync both lost their ws_root() helper to this and reported
# every project "not linked on this device" while writing nothing. Found 2026-11-02 by p7.1's
# stranger run, because reading the file never finds it. This audit then lost its own awk
# programs to it (p8.37), which is why it is a file now. npos is carried to the verdict so a
# clean result cannot be confused with a scan that read nothing.
#
# The program is defined ONCE and compile-checked before the loop. Until 2026-11-03 it was
# inline, and when this audit lived in the skill body the substitution broke it — after which
# `hits` was empty for every file, `pos` stayed empty, and this part reported NO FINDINGS while
# `npos` had already been incremented. Its floor and its cross-check in part 8 both passed. So:
# compile it first, read the scanner's status, and count only a scan that actually ran.
#
# `$0` is now scanned too. It used to be excluded because this very audit used it as an awk field
# reference inside a fenced block — a correct exclusion that made the blind spot structural. With
# the audit in a file, nothing legitimate needs a positional parameter in a delivered body, so
# the exclusion is gone and the next instance is caught rather than this one being patched.
# It scans the WHOLE file — prose, comments, frontmatter, fenced blocks alike. It used to track
# fences and skip comments, on the reasoning that prose about the hazard is not the hazard. That
# reasoning is wrong: the substitution does not read Markdown, so EVERY occurrence in a delivered
# body is rewritten, and the counterexample was this skill's own sentence defining the rule, which
# wrote a positional parameter out as its example and was delivered with the caller's argument in
# its place. Scanning only fences could not see it (p8.37). Simpler code and a stronger rule: a
# delivered body contains no positional parameter anywhere, for any reason.
posprog='/\$[0-9]|\$\{[0-9]/{printf "%d:%s\n", NR, $0}'
awk "$posprog" /dev/null >/dev/null 2>&1 \
  || { echo "AUDIT ABORTED: part 3b's scanner does not compile, so it would find nothing"; exit 1; }
pos=""; npos=0; posfail=""
for d in ws-*/; do d=${d%/}; f="$d/SKILL.md"; { [ -f "$f" ] && [ -r "$f" ]; } || continue
  # Reports the FIRST hit per file, so fix and re-run rather than expecting a full list.
  if ! hits=$(awk "$posprog" "$f" 2>/dev/null); then
    posfail="${posfail}SCAN FAILED: $f was never scanned by part 3b
"
    continue
  fi
  npos=$((npos+1))
  [ -z "$hits" ] || pos="${pos}POSITIONAL PARAMETER: $d — $(printf '%s' "$hits" | head -1)
"
done
[ -n "$pos" ] && printf '%s' "$pos"
[ -n "$posfail" ] && { printf '%s' "$posfail"
  echo "AUDIT ABORTED: part 3b could not scan every SKILL.md, so a clean result is UNKNOWN"
  exit 1; }
# A reference page an agent opens with a file tool is NOT at risk — nothing substitutes into a
# plain read — so a shell function taking an argument is correct inside ws-shared/tracks.md, and
# so is every line of THIS file. This part scans SKILL.md only, and that is the whole rule:
# executable text that gets delivered must contain no positional parameter; executable text that
# gets run by path may contain whatever it needs.

# ---- part 4: forward coverage — every skill NAMED ANYWHERE IN THE PACK exists ----
# Deliberately not scoped to What next? sections: this greps whole SKILL.md files, so a skill
# named in passing is checked too. Wider than the heading suggests, which is the safe direction.
# nnames is carried to the verdict: grep writing "Permission denied" to stderr while the verdict
# said "0 missing skill" is exactly the defect this block exists to find.
names=$(grep -hoE '`ws-[a-z]+`' ws-*/SKILL.md 2>/dev/null | tr -d '`' | sort -u)
nnames=$(printf '%s\n' "$names" | grep -c . )
fwd=""
for s in $names; do
  [ -d "$s" ] || fwd="${fwd}MISSING SKILL: $s is referenced but does not exist
"
done
[ -n "$fwd" ] && printf '%s' "$fwd"

# ---- part 5: every link resolves, from its OWN file ----
# All pack Markdown, not only SKILL.md, and each link resolved against the directory of the file
# that holds it. Resolving against "any ws-*/ directory" passes a link from the one file where it
# is wrong. "_" and "A-Z" are both in the character class deliberately: without them a
# new_device.md- or README.md-shaped target is invisible to this check rather than reported by
# it, which is a silent pass inside a check whose job is to find silent passes.
nmd=0; nlinks=0; lnk=""; seen=""
while IFS= read -r f; do
  { [ -f "$f" ] && [ -r "$f" ]; } || continue
  nmd=$((nmd+1)); dir=$(dirname "$f")
  for rel in $(grep -oE '\]\((\.\./)?[A-Za-z0-9._/-]+\.md\)' "$f" | tr -d '](){}' | sort -u); do
    case " $seen " in *" $rel "*) ;; *) seen="$seen $rel"; nlinks=$((nlinks+1)) ;; esac
    [ -f "$dir/$rel" ] || lnk="${lnk}BROKEN LINK: $rel (from $f)
"
  done
done < <(find ws-* -name '*.md' | sort)
[ -n "$lnk" ] && printf '%s' "$lnk"

# ---- part 6: reverse coverage — an exit the prose OFFERS must be listed in What next? ----
# Anchored twice: on a backticked skill name AND on an offer verb. Unanchored this produces
# roughly two dozen findings, nearly all of them references that are not exits, and it invents a
# skill out of the word "Windows-safe". Every finding is READ AND JUDGED, never auto-fixed, and
# it does not fail the audit: a comparison ("as `ws-review` does") looks exactly like an offer and
# only a reader can tell them apart. No precision figure is stated here: listing the real findings
# changes it, so a ratio in a shipped comment rots. The project's own dated record holds it. Its
# RECALL is the weaker half and much lower, so this check narrows the pack and never certifies it.
#
# rvb is the count that makes "rvc checked" mean something. The two awks below are independent:
# $wn decides whether the file is checked, $body is what gets scanned. An empty $body is
# indistinguishable from "this file offers no exits", so without rvb a file whose frontmatter
# never closed is silently counted as CHECKED while contributing nothing — an actively false
# claim rather than a mere silence.
rvc=0; rvs=0; rvb=0; rev=""; noprose=""
for f in ws-*/SKILL.md; do d=${f%/SKILL.md}; { [ -f "$f" ] && [ -r "$f" ]; } || continue
  # fenced code is skipped: this check is about what the PROSE offers, and a comment inside a
  # shell block is not an offer. Measured, the scan tripped on a comment in this very file.
  # The cost is real and one-directional: an exit offered only inside a fenced example is missed
  # — and it is also why an empty $body is reachable for a legitimate, file-shaped reason.
  body=$(awk 'NR==1&&/^---$/{infm=1;next} infm&&/^---$/{infm=0;next} infm{next}
              /^## What next\?/{exit}
              /^```/{inf=!inf; next} inf{next} {print}' "$f")
  wn=$(awk '/^## What next\?/{p=1} p' "$f")
  [ -n "$wn" ] || { rvs=$((rvs+1)); continue; }   # a reference pack has none, and must not grow one
  rvc=$((rvc+1))
  if [ -z "$(printf '%s' "$body" | tr -d '[:space:]')" ]; then
    noprose="${noprose}NO PROSE EXTRACTED: $f was counted as checked but yielded nothing to scan
"
    continue
  fi
  rvb=$((rvb+1))
  hit=$(printf '%s\n' "$body" \
    | grep -E 'offer|ask for|asks for|go through|goes through|hand off|switch to|instead|→' \
    | grep -oE '`ws-[a-z]+`' | tr -d '`' | sort -u \
    | grep -vx "$d" | grep -vx ws-shared \
    | while IFS= read -r s; do
        printf '%s\n' "$wn" | grep -qF -- "$s" \
          || echo "UNLISTED EXIT: $d's prose offers $s, which its What next? does not list"
      done)
  [ -n "$hit" ] && rev="$rev$hit
"
done
[ -n "$rev" ] && printf '%s' "$rev"
[ -n "$noprose" ] && { printf '%s' "$noprose"
  echo "AUDIT ABORTED: $((rvc-rvb)) of $rvc files were counted as checked with no prose to scan"
  exit 1; }

# ---- part 7: the DEPLOYED copies, per agent ----
# A file can reach two agents of three, and a union answer hides exactly that — so one line per
# agent, printed even when clean, because a clean per-agent check that prints nothing is the
# defect this block is fixing. Roots come from targets[].serves, a JSON array, because one copy
# can serve more than one agent; read from targets[].agent instead and the first placement change
# reports a false MISSING. Unreadable library files are COUNTED, not skipped silently: they
# shrink the denominator every per-agent ratio is measured against.
dep=$(printf '%s' "$st" | python3 -c '
import json,os,re,sys,collections
d=json.load(sys.stdin)
roots=collections.defaultdict(set)
for t in d.get("targets",[]):
    if not str(t.get("ref","")).startswith("skill/ws-"): continue
    p=t.get("path") or ""
    if not p: continue
    for a in (t.get("serves") or [t.get("agent")]):
        if a: roots[a].add(os.path.dirname(p))
if not roots:
    print("DEPLOYED CHECK ABORTED: agent-sync reports no ws-* target paths"); raise SystemExit(1)
refs=set(); skills=set(); unread=[]
for dirpath,dirnames,filenames in os.walk("."):
    if not dirpath.startswith("./ws-"): continue
    skills.add(dirpath.split(os.sep)[1])
    for fn in filenames:
        if not fn.endswith(".md"): continue
        f=os.path.join(dirpath,fn)
        refs.add(os.path.normpath(os.path.relpath(f,".")))
        try: txt=open(f,encoding="utf-8",errors="replace").read()
        except OSError: unread.append(os.path.normpath(os.path.relpath(f,"."))); continue
        for m in re.findall(r"\]\(((?:\.\./)?[A-Za-z0-9._/-]+\.md)\)", txt):
            refs.add(os.path.normpath(os.path.join(os.path.relpath(dirpath,"."), m)))
refs={r for r in refs if not r.startswith("..")}
for r in sorted(unread):
    print("UNREADABLE IN LIBRARY: %s — its own links were never extracted" % r)
lines=[]; missing=[]
for a in sorted(roots):
    present={r for r in refs if any(os.path.exists(os.path.join(x,r)) for x in roots[a])}
    lines.append("%s %d/%d" % (a, len(present), len(refs)))
    for r in sorted(refs-present): missing.append((r,a))
by=collections.defaultdict(list)
for r,a in missing: by[r].append(a)
for r in sorted(by):
    have=sorted(set(roots)-set(by[r]))
    print("MISSING UNDER %s: %s  (present under %s)" % (", ".join(by[r]), r,
          ", ".join(have) if have else "no agent"))
# the summary and the sentinel print LAST, so a failure while formatting the rows above cannot
# leave a passing sentinel behind with the findings missing.
print("deployed check: " + " · ".join(lines) +
      "  (%d skills, %d agents, %d referenced files, %d unreadable)"
      % (len(skills), len(roots), len(refs), len(unread)))
print("deployed check complete")
')
printf '%s\n' "$dep"
# $dep is a command substitution, so a SystemExit inside the python above ends the PYTHON and
# not this block. Without the assertion below, a deployed check that died would leave $dep with
# no "MISSING UNDER" lines and the verdict would print "0 missing under an agent" at exit 0 — a
# zero produced by a check that did not run, which is the exact defect this block exists to kill.
printf '%s\n' "$dep" | grep -q '^deployed check complete$' \
  || { echo "AUDIT ABORTED: the deployed check did not run to completion — UNKNOWN, not zero"; exit 1; }

# ---- part 8: every count must be EARNED before the verdict may print it ----
# Parts 3 to 6 each do their work in a plain loop and end without an exit, so a part that read
# nothing leaves its findings variable empty — which is the same text as "no findings". The only
# defence is a positive denominator per part, asserted here.
#
# NOT "set -e", and this is worth saying because it is the first thing anyone will reach for: a
# CLEAN part ends on `[ -n "$x" ] && printf ...`, which returns NON-ZERO precisely when there are
# no findings. Under set -e the block would abort exactly when the audit is clean.
earned=1
[ "$nfm"    -gt 0 ] || { echo "AUDIT ABORTED: part 3 parsed 0 SKILL.md"; earned=0; }
[ "$nnames" -gt 0 ] || { echo "AUDIT ABORTED: part 4 extracted 0 skill names"; earned=0; }
[ "$nmd"    -gt 0 ] || { echo "AUDIT ABORTED: part 5 read 0 pack files"; earned=0; }
[ "$nlinks" -gt 0 ] || { echo "AUDIT ABORTED: part 5 found 0 links — the pack has some"; earned=0; }
[ "$rvc"    -gt 0 ] || { echo "AUDIT ABORTED: part 6 checked 0 skills"; earned=0; }
[ "$rvb"    -eq "$rvc" ] || { echo "AUDIT ABORTED: part 6 scanned $rvb of $rvc"; earned=0; }
[ "$npos"   -gt 0 ] || { echo "AUDIT ABORTED: part 3b scanned 0 SKILL.md"; earned=0; }
[ "$npos"   -eq "$nfm" ] || { echo "AUDIT ABORTED: part 3 parsed $nfm, part 3b scanned $npos"; earned=0; }
[ "$nfm"    -eq "$n" ] || { echo "AUDIT ABORTED: part 2 counted $n readable skills, part 3 parsed $nfm"; earned=0; }
[ "$earned" -eq 1 ] || { echo "AUDIT ABORTED: a verdict was not earned — see above"; exit 1; }

echo "VERDICT: library $here · $nd ws-* dirs, $n readable · part 3 parsed $nfm · part 4 resolved" \
     "$nnames names · part 5 read $nmd files, $nlinks links · part 3b scanned $npos ·" \
     "part 6 checked $rvc, scanned $rvb, skipped $rvs for having no What next?"
echo "         findings: $(printf '%s' "$fm" | grep -c .) frontmatter," \
     "$(printf '%s' "$fwd" | grep -c .) missing skill," \
     "$(printf '%s' "$lnk" | grep -c .) broken link," \
     "$(printf '%s' "$rev" | grep -c .) unlisted exit," \
     "$(printf '%s\n' "$dep" | grep -c '^MISSING UNDER') missing under an agent," \
     "$(printf '%s\n' "$dep" | grep -c '^UNREADABLE IN LIBRARY') unreadable in the library," \
     "$(printf '%s' "$pos" | grep -c .) positional parameter," \
     "$((nd-n)) ws-* dirs with no readable SKILL.md"
