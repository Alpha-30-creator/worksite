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
- Never propose changing a project's `house_rules` when `owned_by: company`. **With the key absent,
  say so before proposing**: it is read as `me`, which is the permissive branch, so an unstated
  value and a deliberate `me` are indistinguishable here — one line, "`owned_by` is not set, so I
  am treating these as yours to change", is the difference between a decision and an accident
  (p8.34).
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

## Verifying a change to a skill's own text

A skill's body is served to an agent from the **deployed** copy, not from the library, and the
argument string is substituted into it on the way. Two consequences, learned the expensive way:

Both facts were measured by p7.1's stranger run — the probe and its three reproductions are in
that task's record under `docs/records/` in the project that found them.

- **A positional parameter in a skill body is not yours.** It becomes a word from the caller's
  argument string before the agent sees it, so a snippet using one arrives corrupted while the file
  on disk stays perfect. Use a named variable. A reference page an agent opens with a file tool is
  not affected — nothing substitutes into a plain read.

  This paragraph does not write one out, and that is not squeamishness: until 2026-11-03 it did,
  and the sentence defining the rule was itself delivered with the caller's argument in place of
  the example — the rule losing its own subject. Found by a reviewer invoking this skill and
  reading what arrived (p8.37). Part 3b scans the whole file for this now, prose included.
- **Verify in two runs, and the first one must fail.** Invoke the skill with arguments *before*
  deploying and confirm the old behaviour still reproduces: a delivery test that passes pre-deploy
  proves nothing, because it read a copy the change had not reached. Then deploy and invoke again.
  Pre-deploy reproduces, post-deploy confirms — anything else and you have tested the wrong file.

## Deploy

**Only the lead runs either of these, and `apply` is not the same step as `save` — see
*Who may run what* below before you run them.**

```bash
agent-sync apply       # deploy the library to this machine's agents. No commit, no push
agent-sync save        # that, plus commit and push the library — the publish half
agent-sync status      # expect no drift
```

**The audit below reads this same `agent-sync status`.** These are not two independent checks
you can satisfy separately: run the audit before you have deployed and its first gate aborts,
because the library has moved and the deployed copies have not.

### Who may run what — deploying is not publishing

**This is the one statement of the rule. `ws-fanout`, `ws-review` and
[../ws-shared/trackers/README.md](../ws-shared/trackers/README.md) point here rather than
answering it again.** It matters whenever more than one agent is involved, and the single-session
case is one line: you are the lead, so all of it is yours.

The two halves of `agent-sync save` have completely different costs, and the first draft of this
section treated them as one — which made it forbid a step this skill *requires* earlier, under
*Verifying a change to a skill's own text*: "**Verify in two runs, and the first one must fail.**
Invoke the skill with arguments *before* deploying … Then deploy and invoke again.":

| Step | What it costs | Who |
|---|---|---|
| **deploy** — `agent-sync apply`, or the first half of `save` | local and reversible. Writes each agent's copy; **commits nothing, pushes nothing** | **the lead**, as often as verification needs. A skill-body change cannot be verified until it is deployed, so this runs *before* review, more than once if need be |
| **publish** — `save`'s commit-and-push half | the store's history, and every other machine | **the lead**, **once, after review** |
| **either one** | — | **never a subagent.** A `ws-fanout` builder, or any agent you briefed, edits library files and **stops**: no `apply`, no `save`, no audit |

Two mechanisms force the subagent row, so it is not a matter of taste:

1. **Both halves are store-wide.** `apply` deploys the whole library and `save` also commits and
   pushes it, so the first builder to run either carries every *other* track's half-finished edits
   with its own — and `save` pushes them to every machine. No worktree isolates a store (see
   `shared_stores:` in [../ws-shared/reference.md](../ws-shared/reference.md)), so nothing warns
   either track and both reports read as successes. `save --no-push` is not a loophole: it still
   deploys and still commits the whole store, so the collision is the commit, not the push.
2. **The audit cannot run before a deploy.** Its first gate compares the library against each
   agent's deployed copy and aborts while they differ — so the audit is downstream of a step a
   subagent may not take. That settles who runs the audit without a second rule: **whoever
   deployed runs the audit**, and only the lead deploys.

A subagent that has finished a library change reports **what it edited**, not that it deployed. If
its report claims a deploy or a save, treat the change as unreviewed and re-read the files
yourself: it has published every project in the store, not just this batch.

**"Lead" means the session that can ask the user.** Where a lead is itself someone's subagent, it
is a subagent for this rule — the test is the one `ws-review` uses: a step that waits for a yes
belongs to a session that can wait for one.

## Audit afterwards — always

**One script, run whole, under `bash`.** It is one script because the later parts read counts the
earlier parts established; running part of it produces a verdict that has not been earned. Its
loops glob and word-split, and zsh does neither the same way, so `bash` is not a preference — it
is why the invocation names `bash` explicitly rather than relying on the shebang.

Eight parts in a deliberate order. Parts 1 and 2 are **gates** — they decide whether a verdict is
available at all. Parts 3 to 7 are the checks, and their subjects are: **frontmatter** and whether
it closed; **positional parameters** anywhere in a skill body; **forward coverage**, that every
skill named in the pack exists; **links**, resolved from the file that holds them; **reverse
coverage**, that an exit the prose offers is listed in `What next?`; and the **deployed copies**,
per agent. Part 8 is the verdict, and it names its own counts. That list is here so you can tell
whether the verdict covers the thing you changed without opening the script — which you are told
below not to do.

**A verdict without the counts is not a verdict.** An audit that printed no
`auditing N skills under <path>` line and no `deployed check:` line **has not run** — whatever else
it printed, including findings, and including nothing at all. This is the half no shell can
enforce, and it is the actual fix. Until 2026-11-02 the audit opened with a bare `cd` and had
neither gate, which failed two ways that both read as success:

- with the `cd` failed, the loops ran over an unexpanded glob and printed two meaningless findings
  — `NAME MISMATCH: ws-* ->` and `DESCRIPTION PROBLEM: ws-* (0)` — which read as noise to dismiss
  rather than as "I audited nothing". Two dismissible findings are easier to wave past than one;
- run from a directory holding a **published copy** of the pack, which is where an agent whose
  `cd` just failed plausibly already is, the same code enumerated every skill, resolved every
  link and reported **clean**. A verdict about files no agent loads. A count floor would have
  passed it too, which is why part 2 asserts **identity** and not merely a count.

**Which run certifies what.** Run *before* `agent-sync save`, part 1 **aborts**, because the
library has moved and the deployed copies have not. That abort is correct and is not something to
work around — an audit of a library that was never deployed is the thing part 1 exists to refuse.
The run that certifies a change is the one **after** the save, which is also the only one that can
answer part 7 truthfully. Running it twice is the design, not waste.

```bash
bash "$HOME/.agent-sync/store/skills/ws-refine/audit.sh"
```

**It is a file, and it is run rather than pasted.** Until 2026-11-03 the whole block lived in this
section, and a skill's body has the caller's argument substituted into its positional parameters
on the way to you — so invoked as `/ws-refine <anything>`, the awk programs inside it arrived
rewritten and would not parse. Part 3 then produced a spurious finding for every skill, and part
3b reported **no findings at all** while its scanner had never run, with its own count intact.
A clean verdict over a scan that did not happen, in the part added to catch exactly that (p8.37).
Nothing substitutes into a file read or run by path, which is the one property the file buys.

So: **do not open `audit.sh` and paste its contents**, and do not reconstruct it here. Run the
path above. It is the **library** copy on purpose — one absolute path on every agent, the library
is what the audit is about, and parts 1 and 2 refuse without it, so there is never a question of
which copy certified the change. If that path does not exist, say so and stop; do not substitute
a deployed copy, which may be one `save` behind the library you just edited.


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
