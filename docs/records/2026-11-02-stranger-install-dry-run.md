# The install, run by strangers — 2026-11-02

Measured against the tree at `649bb2f`. **44 distinct guess-points**, 18 of them inside
`INSTALL.md`'s own eight steps. Three defects where something reports success while doing the wrong
thing. The loop itself ran end to end on a real task in a project it had never seen.

## Method, and the one place this is not a true stranger run

The author cannot un-know the pack, and criterion 1 asks for "nothing the author happens to know",
so the strangers were **two agents with none of this project's history**, briefed only as a user
pointing an agent at a repository. Each wrote its own log continuously, because a subagent's
summary is a claim and its log is evidence. Every finding below was then reproduced by the lead
against the live pack before it entered this record.

**Both were given a forced `--store <temp>`, and that is a deviation.** A real stranger runs
`agent-sync setup` and creates `~/.agent-sync/store` — which here is the author's live library,
holding **73 skill directories** across worksite and five other projects. The alternative to forcing
the flag was destroying it.

**What was checked afterwards, stated exactly:** the lead hashed the **73 top-level `SKILL.md`
files** — one per skill directory — before the run and confirmed them identical after. That is a
`SKILL.md`-level check, **not** a whole-tree one: the fourteen `ws-*` directories alone hold 47
files, and the reference pages, examples and adapters under them were not hashed. Both strangers
separately confirmed individual artifacts byte-identical with `diff -rq`. Nothing observed suggests
the library was touched, and the check that would prove it exhaustively was not run.

Two agents are not a population, so nothing here is a rate. What it establishes is that the install
is **followable** — both agents finished what the constraints allowed — and that it is **not yet
clear**, which the 44 guess-points are direct evidence of. What two agents cannot tell you is which
of the 44 a third would hit.

## What worked, stated first because it is the larger half

- **The loop ran end to end, unaided**, on a one-file task in a throwaway CLI project the agent
  built itself: `ws-setup` (lite cartridge) → `ws-start` → `ws-plan` → build → `ws-verify` →
  `ws-review` → `ws-ship`, with the worklog harvested, the track retired and verified, the tracker
  marked done and a follow-up filed. Its own `ws-review` caught a real defect — the commit body
  claimed a "silent NaN" that never existed — and it amended rather than shipping the claim.
- **Both documented counts were exact.** `ws-review` with no cartridge asked **3** questions and
  continued to a verdict rather than refusing; a tracker kind with no adapter produced **4**
  questions. Claimed three and four, observed three and four.
- **R4 holds.** A complete working adapter for an invented tracker kind was written with **zero
  skill edits**, verified by `diff -rq` against the repo.
- **`ws-env` and `ws-sync` run with no cartridge**, as `cartridge-schema.md`'s R1 promises. The word
  "cartridge" does not appear in `ws-env/SKILL.md` at all.
- **p4.2's comparison guard held on a relocated store** — the case its review was fixed for, tested
  live here for the first time.

## The three that cost a user something real

Two are defects in shipped behaviour. The third is a documentation gap whose **consequence** is a
silent wrong outcome, which is why it sits here rather than below — and why it was routed onto a
documentation task.

### 1. A `$1` in a skill body is replaced by the caller's argument
`ws-env/SKILL.md`:51 and `ws-sync/SKILL.md`:18 both contain
`ws_root() { … sed -n "s|^  $1: *||p" … }`. Both files are byte-identical to the repo. **The
corruption happens at delivery**: invoke the skill with arguments and `$1` becomes the second
whitespace-separated word of the argument string.

Reproduced three times: twice by a stranger, which established that **a word from the argument
string** replaces `$1`, and once by the lead under control, which established **which** word.
Invoked with `inspect ZZQQPROBE delivery-test-do-nothing`, the delivered line read
`s|^  ZZQQPROBE: *||p` — the second whitespace-separated word. The substitution is certain; that it
is always the second word rests on that single controlled probe and is stated as such.

The consequence is not an error. `ws-env pull`'s next line is
`[ -n "$root" ] … || { echo "skip $project — not linked on this device"; continue; }`, so a broken
helper prints a plausible, specific, **wrong** diagnosis for all 28 manifest rows, writes no
credentials, and finishes cleanly. In the skill that handles secrets.

No author test would find it: the file is perfect, and the trigger — passing a track id, as in
`/ws-plan p4.2` — is the author's own habit. The two `$1` sites in *reference* files
(`ws-shared/reference.md`:138, `tracks.md`:213-214, where 213 is a comment and 214 the live `git -C "$1"`) are **safe**, because nothing substitutes into a
file an agent opens directly. That distinction is the shape of the fix.

### 2. `ws-sync`'s repo sweep cannot see a single-repo project, and says nothing
`ws-sync/SKILL.md`:45 is `for r in "$root"/*/` with `[ -d "$r/.git" ] || continue` — it enumerates
**children** of the workspace root. Where the root *is* the repo, every child is a source directory,
all are skipped, and the project contributes no rows and no message, which reads as "nothing to
report". **It applies to this repo**, whose cartridge declares `repos: [{dir: .}]`. The glob is
correctly quoted; this is a depth assumption, not p8.10's word-splitting bug.

### 3. The documented way to add a tracker adapter does not make it readable
`ws-shared/trackers/README.md`:12 — "is adding a file **in this folder**". Which copy is unstated:
authoring happens in the library, reading happens in the deployed `~/.claude/skills/…`, and only
`agent-sync save` bridges them. No adapter doc mentions a deploy step. So a correct adapter was
written and **never picked up** — and the author's own test of this would pass, because the author's
library is already deployed.

Worse, the only bridge is unusable in a trial: `save` validates, deploys to every agent, commits
**and pushes** the whole private library. There is no read-path override and no dry-run.

## `INSTALL.md`'s eighteen, by what they cost

| | |
|---|---|
| **Dead ends** | `storeExists: false` is a correct, well-signposted hard stop whose **only** exit is another repository's `INSTALL.md`. The stranger improvised with `agent-sync init`, which this document never names — the `doctor` error text does. |
| **A level error waiting to happen** | `--store <path>` makes the library `<path>/store`; agent-sync appends it. Verified: passing `<X>` yields `store: <X>/store`. The prose reads as though the flag names the library, so passing a library path creates a nested `store/store`. §3's "read it out of the `store` field" is what saves you, and it is the only thing that does — **and only while `$LIB` and the user's library resolve from one source.** A stranger claimed the step-4 guard "would still pass silently"; that is overturned for the run as performed, because the block derives `$LIB` from the same `doctor` call. It stands for the case step 4's own new paragraph now warns about: thread `--store` into the `doctor` call or `$LIB` answers about a different library. |
| **Vocabulary the document does not define** | §6 names `synced` as the expected state. Real output was `✔ adopted` on all fourteen plus `51 change(s) pending`. Fourteen green ticks that do not say the documented word invite a false success report. §6's `ok`/`problems`/`notes` guidance, added by p4.2, is correct and did its job. |
| **The step that cannot be done in halves** | §5's `save` is one atomic command that validates, deploys to three agent directories, commits and pushes. An agent that may not write outside a sandbox cannot perform *any* part of the install's second half. The CLI meanwhile printed `next: agent-sync apply` fourteen times, against §5's `save`. |
| **Steps written to the wrong reader** | §7 is an instruction to a human with no command and no success criterion, in a document whose first line addresses an agent. |
| **Unstated preconditions** | step 4's script never says which directory to run it in, and needs hand-editing to carry `--store`; its `node -e` stdin parse has an unwarned failure mode; step 1's "it will tell you which it found" has no command behind it; no minimum agent-sync version; step 2's existing-clone branch offers no way to find the clone or handle a dirty one. |

### The eighteen, enumerated — because the logs do not survive this task

`ws-ship` deletes the track directory, so this list is the only place the headline number stays
checkable. In the order met: no command behind step 1's "it will tell you which it found" · no
minimum agent-sync version to check against · step 2's existing-clone branch, with no way to locate
the clone and nothing for a dirty one · `--store` being the library's parent while the prose reads
as though it were the library · the flag's position guessed · `storeExists: false` resolved with a
command (`init`) the document never names · step 4's script's required working directory never
stated · step 4's script needing a hand-edit to carry `--store` · the `node -e` stdin parse having
an unwarned failure mode · "each skill the user agreed to install" with no user present · the CLI
printing `next: agent-sync apply` fourteen times while step 5 says `save` · no documented way to do
`save`'s library half without its deploy half · `status` printing `adopted` and `51 change(s)
pending`, neither of which step 6 defined · step 6's "both empty is the healthy case" being
unreachable on a current machine · the library holding seventeen artifacts rather than the promised
fourteen, because `init` scaffolds three of its own · step 7 written as an instruction to a human
rather than a command · step 7 having no success criterion · and step 7 being unreachable at all on
a machine where step 5's deploy did not happen.

**The other twenty-six were downstream**, in the pack documentation step 7 hands off to, and they
fall into four classes: a skill assuming a git remote or an upstream a fresh local repo has not
got; a skill naming a file or path that is not shipped inside the skills; a count or state word
used without being defined; and a documented step with no form that can run without writing outside
the working directory. Each produced a fix, a limitations entry, or a criterion on p8.30, p8.35 or
p8.36 — the dispositions in this record are the complete set, and nothing was left as a note to
itself.

**The single most valuable fix**, in the stranger's own judgement and accepted here: a block before
step 1 saying the install **needs a human present**, naming its three user-answered stops, and
stating that step 5 writes into three agent directories and pushes the library — so an agent that
cannot finish stops before starting.

## Recorded, not fixed

- **`ws-review` has no degrade branch for a project absent from `device.yaml`**, and its prescribed
  gather dies on a repo with no remote (`fatal: ambiguous argument 'origin/main...HEAD'`) while
  step 5's `git fetch -q` exits 0 silently. **Measured, because the stranger's "four of five" was
  too broad:** exactly two skills hold an `origin/<ref>` **revision** reference that dies without a
  remote — `ws-plan` (3 sites) and `ws-review` (1) — and `ws-plan`'s refresh failed outright.
  `ws-start`'s is a `git fetch --all --prune -q` that exits 0 silently, the same class in a quieter
  voice. `ws-ship` and `ws-wrap` hold pushes, which is a different thing: a local-only project
  genuinely cannot push, and refusing is correct rather than a defect. A first-ever run in a fresh
  local repo — the stranger's exact situation — hits all of it.
  **Fixed 2026-11-03 by p8.36**, every clause of it: the `device.yaml` branch, the gather (which
  now resolves and *prints* its base ref), and step 5's `fetch -q`, whose line was rewritten to
  say that `fetch` proves nothing in a repo with no remote and to check `git remote` first.
  p8.36 also found two more sites under the same criterion: the stale sweep's `log @{u}..HEAD`,
  where failure reads as "holds no work" and the track is then offered for removal, and
  `ws-plan` §5's `pull --ff-only`, which failed between two commands that both ran, so the branch
  was cut from whatever the local tip happened to be. The two push sites remain out of scope, as
  this entry says they should.
- **Three documented steps cannot be exercised in a sandbox at all**: `ws-sync` step 1
  (`agent-sync sync` pushes the real library, and has no read-only form), `ws-env pull`, and
  `agent-sync save`. A cautious first-time user cannot trial the pack without writing to their own
  machine.
- **`ws-review`'s three questions exist only as topics**, not as askable wording
  (`ws-review/SKILL.md`:16-18). The count is right; "asks its three questions" overstates what is
  written down.
- **`ws-env status` cannot complete without the age key** — its own table promises a store
  comparison, which requires decrypting. The mode the skill calls "read-only and always safe" is
  not fully answerable on a machine without the key.
- **The four adapter questions exist in two versions**, and the fuller one —
  `docs/engineering/trackers.md`, which carries the lock rule — is **not shipped inside the
  skills**, so an installed pack cannot reach it.
- **"Unknown kind is not an error" is cited as R3**, where `docs/integration/cartridge-schema.md`:97
  already defines R3 as "unknown keys are ignored". Two rules, one id. **And that page is a repo
  doc, not a shipped skill file** — there is no `cartridge-schema.md` anywhere under the library, so
  an installed pack cannot reach the rules it cites as authority, exactly as with the fuller
  four-questions page above. Every bare `cartridge-schema.md` reference in this record means the
  repo copy.
- **The library held seventeen artifacts, not the promised fourteen**, because `agent-sync init`
  scaffolds three of its own.

## Two that are not worksite's

- **`agent-sync link` reported "this directory is not a git repository, so the marker cannot
  travel"** on a directory that is a git repository with two commits. A false negative in
  agent-sync, which already owes its tracker two items from p4.2: `add skill` destroying a
  destination with no guard, and its skill pack telling agents to read a `healthy` field
  `doctor --json` does not emit.
- **A documented safety mechanism and a platform one in direct opposition.**
  `ws-shared/tracks.md`'s retirement block insists on running whole in one shell because an
  in-script `$id` guard is what bounds its `rm -rf` — and the stranger's harness refused the block
  *for containing exactly that construct*. It ran the removal with the path written out literally
  instead. Nothing in the pack can fix this; it is recorded because the next person will meet it.
