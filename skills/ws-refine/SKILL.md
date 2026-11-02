---
name: ws-refine
description: Change the workflow system itself - a generic ws-* skill, a shared review pack, a tracker adapter or a project's cartridge - keeping the What next? graph, the shared reference and the generated workspace instructions consistent, then validate, deploy everywhere and audit. Ends with the system changed and audited, and it always proposes before applying. Use when a workflow step felt wrong or was missing, when a fact in a skill or cartridge is out of date, when a repeatable workflow should become a skill or a pack, or when a review found a risk worth writing down for every project. Not for changing one project's tasks, which is ws-task.
---

# Change the system

The system edits itself through this skill. Nothing else should edit it.

## Before anything

1. Read [../ws-shared/reference.md](../ws-shared/reference.md). Read
   [../ws-shared/tracks.md](../ws-shared/tracks.md) if the change touches the loop.
2. **Edit the library, never a deployed copy.** The library is
   `~/.agent-sync/store/skills/`; everything under `.claude/skills/`, `.codex/skills/` and
   `.cursor/skills/` is written by `agent-sync save` and overwritten on every save. Reading a
   deployed copy to see what an agent currently loads is fine. The public `worksite` repo is a
   **published artifact**, not a place to edit: it receives a plain copy of the generic skills
   after they are saved here. Never edit a skill there, and never fix something there — fix it
   in the library and let the publish carry it. The copy is carried by the **Publish** step at
   the end of this skill, so "let the publish carry it" means that step and nothing manual.
3. **One blast radius to respect:** a generic `ws-*` skill is shared by every project. A bad
   edit breaks all of them at once, which is the cost of the generic design. So: propose, wait,
   then audit.

## What is being changed?

| Intent | Where it goes |
|---|---|
| A workflow step was wrong or missing | the `ws-*` skill |
| A risk class worth catching everywhere, on a stack several projects use | `ws-shared/stacks/<name>.md` |
| An objective security or quality rule | `ws-shared/stacks/security-baseline.md` or `review/tier1-universal.md` |
| A risk specific to one project | that project's `<docs_home>/risks/` — **a docs commit, not a library change** |
| A fact about repos, branches, commands, environments | that project's cartridge |
| A new tracker, or a tracker detail | `ws-shared/trackers/<kind>.md` — **a new file, never a skill edit** |
| A new stack | `ws-shared/stacks/<name>.md` — a new file, plus a row in the tag table |

**Adding a tracker or a stack never edits a skill** (R4). If you find yourself about to branch
on a tracker kind inside a skill, the design is being broken — add an adapter instead.

## Rules for the change itself

- Frontmatter: `name` matching the directory, and a `description` in the third person saying
  **what + when** under 1024 characters. **Workflow skills are model-invocable** — they carry no
  `disable-model-invocation`, so the loop runs when the work calls for it rather than when
  someone remembers the command. That makes the description load-bearing: it must say what the
  skill **ends with**, or it will fire in place of a sibling that ends with something else. A
  **rule** skill likewise omits the flag and ends its description with "Load it automatically …
  before …". **A reference pack keeps the flag** — `ws-shared` is read by path, not invoked, so
  making it invocable only adds a competitor to the trigger space with nothing behind it.
- **A skill with an expensive or outward-facing effect narrows its own trigger** and restates its
  gates as refusals. `ws-ship` only on explicit ship intent, `ws-fanout` only on explicit
  parallel intent, `ws-env` read-only unless asked for by name. Auto-invocation removed the typed
  command that used to serve as the confirmation; the skill has to supply it instead.
- First section **Before anything**, reading `../ws-shared/reference.md`. Last section
  **What next?**, starting "Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in
  Codex."
- **Generic means generic, permanently.** A generic `ws-*` skill, a shared review pack and a
  tracker adapter name no project, repo, person, device or path belonging to anyone real — not as
  an example, not as a "serves X" note, not as a pointer into a private doc. This is not
  tidiness. The library is published to a public repo as a **plain copy**, so a private name
  introduced here breaks publishing rather than merely reading badly. Project-specific knowledge
  goes to that project's `<docs_home>/risks/` and stays there; where a generic skill needs a
  concrete example, use the pack's invented example projects, never a real one.
- Facts several skills need go in `ws-shared/reference.md`, not repeated per skill. Facts about
  one project go in its cartridge. Facts about a product go in that project's docs.
- **Degrade, never fail** (R1): a new field or file must not break a project that lacks it.
  Unknown keys are ignored; a missing one means less capability, never an error.
- **New behaviour arrives as a flag defaulting to today's behaviour** (R5).
- Every command or fact you add must be checked — run it, or read the code. **Mark anything you
  could not check**, rather than implying you did.
- Never propose changing a project's `house_rules` when `owned_by: company`.
- No AI attribution anywhere, including the library commit message.
- Do not rename or delete a skill without an explicit yes.

## Propose — always, before touching anything

A table of the changes and why, the files touched, and **the graph table**, which is included
even when nothing else changes:

```markdown
## Graph and shared files affected

| File | Change? | Proposed edit |
|---|---|---|
| `ws-shared/reference.md` | yes / no | … |
| `ws-shared/tracks.md` | yes / no | … |
| each `ws-*` What next? that should name this | yes / no | … |
| the generated workspace `AGENTS.md` of affected projects | yes / no | … |
```

**Wait for a yes.** Then apply only what was approved.

## Deploy

```bash
agent-sync save        # validate, deploy to every agent, commit and push the library
agent-sync status      # expect no drift
```

**The audit below reads this same `agent-sync status`.** These are not two independent checks
you can satisfy separately: run the audit before this save and its first gate aborts, because
the library has moved and the deployed copies have not.

## Audit afterwards — always

**One block, run whole, under `bash`.** It is one fence because the later parts read counts the
earlier parts established; running half of it produces a verdict that has not been earned. The
loops glob and word-split, and zsh does neither the same way, so `bash` is not a preference.

Eight parts in a deliberate order. Parts 1 and 2 are **gates** — they decide whether a verdict is
available at all. Parts 3 to 7 are the checks. Part 8 is the verdict, and it names its own counts.

**A verdict without the counts is not a verdict.** An audit that printed no
`auditing N skills under <path>` line and no `deployed check:` line **has not run** — whatever else
it printed, including findings, and including nothing at all. This is the half no shell can
enforce, and it is the actual fix. Until 2026-11-02 this block opened with a bare `cd` and had
neither gate, which failed two ways that both read as success:

- with the `cd` failed, the loops ran over an unexpanded glob and printed two meaningless findings
  — `NAME MISMATCH: ws-* ->` and `DESCRIPTION PROBLEM: ws-* (0)` — which read as noise to dismiss
  rather than as "I audited nothing". Two dismissible findings are easier to wave past than one;
- run from a directory holding a **published copy** of the pack, which is where an agent whose
  `cd` just failed plausibly already is, the same block enumerated every skill, resolved every
  link and reported **clean**. A verdict about files no agent loads. A count floor would have
  passed it too, which is why part 2 asserts **identity** and not merely a count.

**Which run certifies what.** Run *before* `agent-sync save`, part 1 **aborts**, because the
library has moved and the deployed copies have not. That abort is correct and is not something to
work around — an audit of a library that was never deployed is the thing part 1 exists to refuse.
The run that certifies a change is the one **after** the save, which is also the only one that can
answer part 7 truthfully. Running it twice is the design, not waste.

```bash
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
# -r, not -f: a mode-000 SKILL.md is a skill this audit cannot read, so it must not be counted.
# But it must not be dropped SILENTLY either: nd counts the ws-* directories that exist and n the
# ones that are readable, and the difference is reported. Noticing a missing skill by knowing
# today's count by heart is exactly the bookkeeping the floor below refuses to be.
nd=0; n=0; unread=""
for d in ws-*/; do [ -d "$d" ] || continue
  nd=$((nd+1))
  if [ -r "${d}SKILL.md" ]; then n=$((n+1))
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
for d in ws-*/; do d=${d%/}; f="$d/SKILL.md"; [ -r "$f" ] || continue
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
  [ -r "$f" ] || continue
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
# only a reader can tell them apart. Measured precision is about 2 in 3; its RECALL is the weaker
# half and much lower, so this check narrows the pack and never certifies it.
#
# rvb is the count that makes "rvc checked" mean something. The two awks below are independent:
# $wn decides whether the file is checked, $body is what gets scanned. An empty $body is
# indistinguishable from "this file offers no exits", so without rvb a file whose frontmatter
# never closed is silently counted as CHECKED while contributing nothing — an actively false
# claim rather than a mere silence.
rvc=0; rvs=0; rvb=0; rev=""; noprose=""
for f in ws-*/SKILL.md; do d=${f%/SKILL.md}; [ -r "$f" ] || continue
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
[ "$nfm"    -eq "$n" ] || { echo "AUDIT ABORTED: part 2 counted $n readable skills, part 3 parsed $nfm"; earned=0; }
[ "$earned" -eq 1 ] || { echo "AUDIT ABORTED: a verdict was not earned — see above"; exit 1; }

echo "VERDICT: library $here · $nd ws-* dirs, $n readable · part 3 parsed $nfm · part 4 resolved" \
     "$nnames names · part 5 read $nmd files, $nlinks links · part 6 checked $rvc, scanned $rvb," \
     "skipped $rvs for having no What next?"
echo "         findings: $(printf '%s' "$fm" | grep -c .) frontmatter," \
     "$(printf '%s' "$fwd" | grep -c .) missing skill," \
     "$(printf '%s' "$lnk" | grep -c .) broken link," \
     "$(printf '%s' "$rev" | grep -c .) unlisted exit," \
     "$(printf '%s\n' "$dep" | grep -c '^MISSING UNDER') missing under an agent," \
     "$(printf '%s\n' "$dep" | grep -c '^UNREADABLE IN LIBRARY') unreadable in the library," \
     "$((nd-n)) ws-* dirs with no readable SKILL.md"
```

Report the result, and report it as the counts plus the findings — not as "clean". A broken link
is silent at runtime, the agent reads nothing and carries on as if the rulebook said nothing, so
an unaudited change is not a finished change. **An `UNLISTED EXIT` is read and judged, not
auto-fixed**: the check narrows the whole pack to a line or two, and whether a sentence offers an
exit or merely compares one is a question for a reader. A finding in a file your change does not
own is **reported, not edited**.

Then summarise in a few bullets: what changed, which shared files moved, and how to invoke
anything new. **Do not run the changed skill unless asked.**

## Publish — a step, not a suggestion

Run this after the deploy and the audit, every time a generic `ws-*` skill changed. Some setups
publish the generic skills as a public artifact; that artifact is a **published copy** and the
publish below is the only way content reaches it. Doing it by hand is how the two drift.

Targets are **configured on the machine, never named in a skill**: a published artifact's path
belongs to one person's setup, and a path written here would be copied into every published
artifact along with it. One absolute workspace path per line, `#` for comments, file absent
means there is nothing to publish — which is the normal case for most setups and must not be an
error.

```bash
targets="$HOME/.agent-sync/publish.targets"
if [ ! -f "$targets" ]; then
  echo "no publish targets configured — nothing to publish"
else
  while IFS= read -r t; do
    case "$t" in ''|\#*) continue ;; esac
    if [ -f "$t/scripts/publish.sh" ]; then
      # </dev/null matters: the child may read stdin, and stdin here IS the target list. Without
      # it, one target can swallow the rest and the next is silently never published.
      bash "$t/scripts/publish.sh" </dev/null \
        || { echo "PUBLISH REFUSED at $t — stop here"; break; }
    else
      echo "no scripts/publish.sh at $t — skipping"
    fi
  done < "$targets"
fi
```

**Each target owns the copying.** Only the target knows its own leak guard, which skills it
accepts, and how it commits — so this skill runs the target's script and respects the answer. It
never copies files itself, and never works around a refusal.

**On a non-zero exit, stop.** Report what the script printed, name the **library** file to fix,
and do not retry, do not continue to another target, and do not offer to publish "just the clean
ones" — a partial publish is a transformation by omission. A target is expected to refuse without
leaving anything behind; if its output says it could **not** put itself back, that is the one case
to report as needing a hand, and still not to work around.

**A green publish means no *known* pattern, not "no private data".** A target's guard bounds the
patterns it has been told about; a private name nobody has added to its pattern file passes it,
and a secret is not a name at all. Read a green publish as the floor, never as a clean bill of
health — in particular, **everything inside a skill directory is published**, so a stray `.env`,
an editor backup or a credential file in the library goes public with it. Keep skill directories
to the pack's own files; a target that lists extra files it is about to publish is telling you to
read that list.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- Try the change on a real task
- `ws-setup` — the change means a project's cartridge needs regenerating
- `ws-refine` — another change
