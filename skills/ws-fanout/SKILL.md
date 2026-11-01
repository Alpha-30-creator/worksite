---
name: ws-fanout
description: Run two to five tracks at once from one session as the lead - claim them, assign file ownership up front, plan every track and get the plans approved together, then brief a separate build subagent per track in its own worktree and a separate reviewer per track so no agent reviews its own work, then verify every finding and reconcile across the tracks. Refuses tracks that would touch the same files. Ends with a reconciled report; the lead never builds, and tracks ship one at a time. Use only on an explicit request to run work in parallel, since it spawns several subagents and the cost is the user's.
---

# Run several tracks at once

This session is the **lead**. It claims, plans, briefs, reconciles and reports. **It does not
build.**

The order is: claim → **plan every track and get them approved** → build → review → ship one at a
time. The plan and mockup gates are not skipped because there are several tracks; they matter
more, because a wrong approach now costs N times as much.
The moment the lead starts writing code it loses track of what the subagents are doing, and the
whole point was to keep one head above the work.

## Before anything

1. Read [../ws-shared/reference.md](../ws-shared/reference.md) and
   [../ws-shared/tracks.md](../ws-shared/tracks.md); read the cartridge and the tracker adapter.
2. Check you can actually spawn subagents. Claude Code: the Agent tool. Codex / Cursor: their
   equivalent. **No subagent mechanism → stop and say so.** Fanning out is the only thing this
   skill does.

## 1. The safety gate — do this before claiming anything

Two things decide whether fanning out is safe, and both are refusals rather than warnings.

### Is isolation on?

```bash
grep '^worktrees:' <docs_home>/agent/reference.md
```

| `worktrees:` | What it means |
|---|---|
| `true` | Each track gets its own checkout. Two agents cannot touch the same file. Proceed |
| `false` | **All tracks share one working tree.** Two agents editing it will overwrite each other silently — no error, no warning, both reports confident |

With `worktrees: false` you have two honest options, and **inventing a third is not allowed**:

- **Turn it on for this project** — offer it: `ws-refine` sets `worktrees: true` in the cartridge,
  then `ws-start` creates a worktree per track. Say that each worktree needs its own dependency
  install, which is the real cost (see `ws-shared` on worktrees).
- **Fan out anyway, with hard file ownership** — only when the tracks provably touch **different
  repos**. Not "different features": different repos. Anything less and you are relying on a
  briefing being obeyed, which is not isolation.

Say which of the two you are doing, out loud, before continuing.

### Do the tracks overlap?

For each candidate track, work out which files it will touch — from its plan if it has one, from
its acceptance criteria and the repos it names if not. Then:

```bash
# per track, the files its plan or task names
# then: is any file claimed by two tracks?
```

**Any overlap and the overlapping track is dropped from this batch.** Not reordered, not
assigned a "primary owner" — dropped, and run on its own afterwards. File collisions are the way
parallel agent work corrupts itself, and the only reliable fix is not having them.

Also drop a track that:
- has no acceptance criteria you could brief someone with — vague scope is the biggest predictor
  of a wasted subagent run;
- depends on another track in the same batch (do them in order instead);
- touches a migration *and* another track touches the same database.

### What else do the tracks share?

Worktrees isolate **files**. They do not isolate anything else, and a batch collides on the rest
without a word of warning. Before claiming, name what the tracks will share and say who owns it:

| Shared | What goes wrong | What to do |
|---|---|---|
| **One local database** | one track runs the project's reset/seed script and wipes the data another is verifying against; a migration applied from a worktree that lacks the other's file leaves the schema half-applied | a database per track where the project allows it, or: resets go through the lead, and no track reverts a migration it did not write |
| **One port per service** | the second track's dev server silently fails or attaches to the first's | assign ports per track in the brief; never let a builder discover 8000 is taken |
| **One mail catcher, queue or other dev service** | one track's test run consumes or clears another's | same — assign, or say in the brief that it is shared and must be left as found |
| **The docs repo** | it usually gets no worktree, so two tracks edit one working tree and their changes land in one uncommitted file for the lead to split by hunk | give the docs repo a worktree too, or name in the brief exactly which files each track may touch |

Say which of these this batch shares, out loud, before continuing. A builder that is told "another
track holds port 8000 and the database is shared; leave its migration alone" behaves; one that is
not finds out by breaking something.

## 2. Pick the batch

**Two to five tracks. Five is the hard cap.** Beyond that the coordination costs more than the
parallelism gains, and every subagent call re-sends its whole brief, so the cost is round trips.

Show the batch and **wait for a yes**:

```markdown
| Track | Title | Repos | Files it owns | Worktree |
|---|---|---|---|---|
| p3.2 | Stock levels | northwind-api | src/modules/inventory/** | ../northwind-tracks/p3.2 |
| p5.4 | Order history UI | northwind-web | src/app/(account)/orders/** | ../northwind-tracks/p5.4 |

Dropped: p4.1 — touches `src/shared/money.ts`, which p3.2 owns. Run it after.
```

## 3. Claim them all, then set up

Per track, in order, via the tracker adapter — **including its retry rule**. A rejected claim
means that task went to someone else: drop it from the batch and say so.

Then per track: create `<state_dir>/tracks/<id>/`, write `task.md`, append a `claimed` journal
entry, and create the worktree if isolation is on.

**Do not write `tracks/current`.** That file is for a single session working one track; the lead
is working several and none of them is "current". Each subagent is told its own track explicitly,
**and so is `ws-ship` at step 8** — you name the track id in the invocation. That is the
replacement channel for the file you are not writing: omit it and `ws-ship` has no id to clean up
with, which is a **stop**, not a harmless no-op — an unguarded cleanup with an empty id targets
`<state_dir>/tracks/` itself, every other track included.

## 4. Plan every track, and get them approved — before any code

**Fanning out does not skip the plan or the mockup gate.** They are the cheapest place to catch a
wrong approach, and skipping them because there are several tracks gets it exactly backwards:
with N agents building, a bad approach costs N times as much.

So the batch goes through planning **as a phase**, all tracks together, and no builder starts
until the user has approved.

### Spawn one planner per track

One subagent per track, in the background, each **following `ws-plan`** — that file is the
authority and this is the same job run N times. Each brief carries:

- its track id and the directory it works in (its worktree, if isolation is on);
- the task and acceptance criteria verbatim;
- the files it owns;
- the sources to read: the task's own source, the project's `decisions/`, the contracts, the
  schema, the practices docs, and `<docs_home>/agent/risks/` — plan around the known traps rather
  than meeting them in review;
- **write the plan to its track directory as `plan.md`. Do not write code. Do not create
  branches.**
- for a UI track: **write `mockup.html` too**, to `ws-plan`'s mockup rules — real design tokens,
  both breakpoints, interactive, and the easy-to-forget states (empty, loading, error, long text,
  logged out, keyboard focus).

### Present all of them together, and stop

This is the part a one-at-a-time flow cannot do, and it is worth the wait:

- **The plans side by side**, each with its plain-English summary, its approach, its steps and its
  verification. One screen, so the batch is judged as a batch.
- **The mockups side by side**, opened together. Three screens designed by three agents that
  could not see each other drift apart; seen next to each other, the drift is obvious.
- **Cross-plan conflicts**, which the file-ownership check in step 1 cannot catch, because they
  are about intent rather than paths:
  - two plans inventing the same component, helper or pattern separately;
  - two plans changing the same contract, schema or shared type in incompatible ways;
  - two plans adding the same dependency, or different versions of it;
  - one plan assuming behaviour another plan is about to change;
  - two migrations whose order now matters.

Then **wait for a yes, per track**. The user may approve some and send others back — that is
normal, and a rejected plan means that track drops out of this batch rather than holding up the
rest.

**Append a `planned` journal entry per track**, including anything rejected and why. That line is
the most valuable one in the file.

Only once a track's plan is approved does its builder start, and the builder is **given the
approved plan** — it does not re-plan.

## 5. Brief one builder per track

One subagent per track, **in the background**, so they run concurrently. Each brief must stand
alone — the subagent has none of this conversation.

Every brief contains:

- **Its track id, and the directory it works in.** With isolation on, that is the worktree path,
  and every `git -C` in the brief points there — not at the main checkout.
- **The approved plan, summarised in the brief itself** — the approach, the ordered steps and the
  verification it owes. Do not merely point at `plan.md`; the subagent should not have to go
  looking for its own instructions. **It implements the approved plan and does not re-plan.** A
  builder that decides on a different approach has thrown away the gate the user just passed.
- **The mockup's decisions**, for a UI track, summarised the same way: what was approved, and
  what was deliberately left out. Do not report those as deviations; do report them if built
  wrongly.
- **The task and its acceptance criteria verbatim.** Plus what is out of scope.
- **The files it owns, and the instruction that it may not write outside them.** State the other
  tracks' owned paths explicitly as forbidden. This is the single most important line in the
  brief.
- **The rule skills and rulebooks to read**, named by path, in **two or three calls, never one** (a single
  batched read of a dozen files truncates silently): the project's
  `<prefix>-<area>` skills, `<docs_home>/agent/rules/`, and the repo's own practices docs.
- **The project's house rules** that override defaults — attribution, commit convention, never
  `--no-verify`, never `git add -A`.
- **Commit, do not push, do not open a PR, do not merge.** Shipping is the lead's decision after
  review. A subagent that pushes has taken a decision that was not its to take.
- **The risks to go after, as questions** — the same list `ws-review` step 2 builds, written into the *build*
  brief. A builder handed the questions catches the cheap ones itself; a review round costs a spawn, a report,
  the lead's verification, a fix round and a full re-run of the gates.
- **The checks to run** from the cartridge's `commands`, and to report pass/fail with output.
- **What to return**: what changed, which criteria are met, what it could not do, and anything it
  found that is out of scope. Not a narrative.

Then **carry on with something else, or wait**. Do not poll, and do not start building.

## 6. Brief one reviewer per track — a different one

When a builder returns, review that track. **A separate subagent, never the builder, and never
this session.** The builder reads its own intent into its work; the lead has been reading its
reports and has absorbed its framing.

Use `ws-review`'s rules for the brief — that file is the authority, and this is the same job run
N times: standalone brief, the rulebooks named, **the risks specific to that change** picked from
the packs and the project's `risks/`, read-only, a 10–15 call budget, findings quoted as exact
source lines rather than line numbers, and coverage declared.

Reviewers can run concurrently with builders still working on other tracks. Keep the total in
flight at or under five, counting both kinds.

## 7. Verify every finding yourself

Per track, exactly as `ws-review` requires: **grep the quoted line, read around it, and drop the
findings that are wrong, saying why.** Across a batch this matters more, not less — N reviewers
produce N chances to act on something invented.

**Then look across the tracks**, which is the part a single-track review cannot do:

- Two tracks that changed the same contract, schema or shared type in incompatible ways.
- Two migrations whose order now matters.
- The same new dependency added twice, or two different versions of it.
- A pattern invented twice because neither builder could see the other's work.
- One track's acceptance criteria quietly satisfied by another's change.

## 8. Report, then ship one at a time

One table, then the decisions:

```markdown
| Track | Built | Checks | Review | Verdict |
|---|---|---|---|---|
| p3.2 | yes | all pass | 2 must, 1 should | needs fixes |
| p5.4 | yes | all pass | clean | ready to ship |

## Cross-track
<conflicts found, or none>

## Needs you
1. …
```

**Ship with `ws-ship`, one track at a time, in dependency order, naming the track id in the
invocation** — `/ws-ship p3.2`, then `/ws-ship p5.4`. The lead never writes `tracks/current`, so
the id in the invocation is `ws-ship`'s **only** source for it. Omit it and `ws-ship` has to stop
and ask which track it is shipping: that is the good outcome, and the reason it is written as a
stop is that the alternative — a cleanup running with an empty id — targets `<state_dir>/tracks/`
itself and takes every other track with it. Either way the batch does not finish itself, so pass
the id.

Never a batch merge: if something breaks you want to know which track did it, and a single merge
of five tracks tells you nothing.

Append a journal entry per track before handing off, so each one can be resumed cold by a normal
single-track session — fanning out must not leave state only this lead understands.

### An abandoned batch

A batch does not always end in ships. The user stops it; a plan is rejected after its track
directory was created; a claim is lost; a subagent fails. In every one of those the lead
**reconciles every track it created** — there is no other owner, because no single-track session
knows these tracks exist. Each one gets exactly one of three endings, by name:

- **shipped** — `ws-ship`, with the id in the invocation.
- **wrapped** — `ws-wrap`, which keeps the track deliberately. A subagent that failed leaves its
  track **claimed and unfinished**: that is a wrap, not a retirement.
- **retired** — session state removed, per **Retiring a track** in
  [../ws-shared/tracks.md](../ws-shared/tracks.md): say what survives, show it, wait for a yes,
  remove per repo, verify. Branches, commits and PRs are kept. A worktree holding uncommitted or
  unpushed work is a refusal — wrap it instead.

### Reconcile before you call the batch done

The last thing step 8 does, after the report table and after the ships. For every track in the
batch, check `<state_dir>/tracks/<id>/` and `git worktree list --porcelain` in each repo —
matching the worktree path one whole segment at a time, as *Retiring a track* shows:

- A directory or worktree still present for a task the tracker shows as **closed** means that
  track's `ws-ship` did not finish its closing step. Say which, and retire it per *Retiring a
  track*. You are finishing what `ws-ship` started, not running a second cleanup mechanism.
- A directory for a task still in progress is a wrapped or unfinished track and is **kept**. Say
  which, and why.

Then end the batch with one line per track: **shipped, wrapped, or retired.** The failure to
avoid is a lead reporting "batch done" with three track directories and three worktrees still on
disk and not a word about them.

## Rules

- **The lead never builds.** Claim, brief, verify, reconcile, report.
- **No builder starts before its plan is approved.** Fanning out never skips the plan or the
  mockup gate — with N agents building, a wrong approach costs N times as much.
- **Five in flight, maximum**, builders and reviewers counted together.
- **No track that overlaps another's files.** Drop it and run it afterwards.
- **Never the same agent for building and reviewing** a track.
- **Subagents commit but never push, PR or merge.**
- **Never `tracks/current`** from the lead — pass the track id to `ws-ship` in the invocation
  instead; that is the only channel it has.
- **Never end a batch without saying what happened to every track directory it created** —
  shipped, wrapped, or retired, one line each.
- **Never report a subagent's claim as fact.** Check the diff before saying something is done —
  a returned report is a claim, not evidence.
- If a subagent fails or returns nothing useful, say so plainly and leave that track claimed and
  unfinished rather than quietly picking it up yourself.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-ship` — ship a track whose review is clean, one at a time
- `ws-review` — re-review a track after its fixes
- `ws-debug` — a finding is a real defect with an unknown cause
- `ws-task` — a finding is real but out of that track's scope
- `ws-wrap` — stopping with tracks still open
- `ws-plan` — re-plan a single track whose plan was sent back
- `ws-refine` — turn `worktrees: true` on for this project
