# worksite

**A disciplined task loop for coding agents — plan, build, prove, review, ship — that works the
same way in every project you own.**

## The problem

Coding agents are good at writing code and bad at nearly everything around it. They start
without establishing what the task actually is. They skip the plan, or write one and quietly do
something else. They declare success on a reading of their own diff, and they review their own
work and find it good. Then the session compacts, or the laptop closes, and whatever they had
worked out goes with it.

It is tempting to read that as a model defect, fixable by a better prompt. It is not. Every one
of those failures is a missing **stopping point** — nothing in a chat has a defined end state,
so there is nothing for "done" to mean, nothing to hand to a second reader, and no place a
record gets written on the way past. A stronger model with no stopping points fails the same
way, faster.

And the gap gets re-solved per repo. Each project grows its own instruction file and its own
half-remembered conventions, all slightly different, none complete; an improvement made in one
reaches none of the others. The effort is real and it never compounds.

## What it is

worksite closes the gap once: thirteen skills plus a shared reference they all read, each one
with a named terminal state it refuses to end without, and all of a project's own facts in one
declarative file per project rather than inside the skills. The skills are generic; the file —
the **cartridge** — is what makes them yours. Improve a skill and every project you own gets
the improvement.

Five of the thirteen are the loop, and one task walks them in order: `ws-start` claims it,
`ws-plan` settles the approach before anything is written, `ws-verify` proves it against the
criteria, `ws-review` judges it from a context that did not write it, and `ws-ship` merges it
and writes the record. The skills table below says what each one refuses to end without. That
those ends are *named* is the mechanism rather than decoration: a stage with no defined output
cannot be seen to collapse, so planning that slid into building is invisible — against "ends
with an approved plan" it is simply the gate not reached.

## Why you should want the opinions

### Gates that stop

The failure a gate prevents is design churn discovered *after* the build, when changing course
is expensive and an agent has already produced something that looks finished. An agent that can
produce a screen or a migration in ninety seconds has removed the last natural pause from the
process — there used to be one, and it was not discipline, it was the hour the work would take.
`ws-plan` puts it back where changing your mind is still free, and for UI work it writes a
mockup, presents it and stops. What you give up is real: a round trip and a human decision on
every task, including the ones that did not need it. The gate worth being suspicious of is the
one that never changes anything — a gate that only ever gets a yes is a formality, and
formalities get skipped.

### Evidence, not assertion

The failure here is "done" meaning *the code it wrote reads as though it would work*.
`ws-verify` produces evidence mapped one-by-one to each acceptance criterion, and records
explicitly what it could **not** prove — the second half does the work, because an unprovable
criterion written down is a visible gap someone can decide about, while the same criterion with
no evidence and no note silently passes. The trade is that this is not a test runner and does
not replace one; the point is the **mapping**, and a project with an excellent suite still has
criteria no suite covers.

### Fresh eyes

The failure is the session that wrote the code reviewing the code: it reads its own intent into
what is on the page, and where the intent and the text disagree it defends the text. `ws-review`
composes a standalone brief — the criteria verbatim, the decisions summarised into it rather
than linked, the project's own risks written as questions — and runs it where none of the
writing conversation exists. The trade is tokens, and the counter-discipline comes in the same
breath: every finding is verified against the code before it is reported, and overturned
findings are recorded, or fresh eyes become a confident-noise generator.

### The lead that never builds

The failure is the coordinator quietly becoming the busiest builder; once it has a half-finished
edit of its own, the two jobs only it can do are the first two it stops doing. When several
tracks run at once, `ws-fanout`'s lead claims them, assigns **file ownership before any work
starts**, briefs one builder per track in its own worktree and a *separate* reviewer per track,
then reconciles. It is enforced by a refusal rather than a preference: two tracks that would
touch the same file do not run in the same batch. The trade is that a lead who writes no code is
overhead on a solo project — so it is opt-in, and the single-track loop has no lead at all.

Each opinion also has an objection worth taking seriously, and an honest limit.
[docs/product/overview.md](docs/product/overview.md) argues all four at length, answers the
objections, and lists what this is not.

## The thirteen skills

| Skill | Ends with | When you reach for it |
|---|---|---|
| [`ws-start`](skills/ws-start/SKILL.md) | a claimed task and a summary — never a plan, never code | starting a session, picking what is next, resuming or taking over paused work |
| [`ws-plan`](skills/ws-plan/SKILL.md) | an approved plan, never with code written | after claiming a task; designing a screen or an endpoint before building it |
| [`ws-verify`](skills/ws-verify/SKILL.md) | evidence against every criterion, never "looks right" | after building and before review; when a deploy needs confirming |
| [`ws-review`](skills/ws-review/SKILL.md) | a verdict you can act on, and a better risk list | before shipping; when a change touches money, auth, migrations or concurrency |
| [`ws-ship`](skills/ws-ship/SKILL.md) | the work merged, the record written, nothing ephemeral left behind | on an explicit instruction to ship, merge or release — never inferred |
| [`ws-debug`](skills/ws-debug/SKILL.md) | a confirmed cause, never a fix that seems to work | something fails for an unknown reason; a check or deploy breaks |
| [`ws-task`](skills/ws-task/SKILL.md) | the tracker changed; it never implements anything | something is missing from the tracker, a task is too big, scope changes |
| [`ws-wrap`](skills/ws-wrap/SKILL.md) | the work saved and a resume note a session with no memory can use | stopping for the day mid-task, switching tracks, running low on context |
| [`ws-fanout`](skills/ws-fanout/SKILL.md) | a reconciled report; the lead never builds | an explicit request to run two to five tracks at once |
| [`ws-setup`](skills/ws-setup/SKILL.md) | a project an agent can work in, nothing overwritten unapproved | a new project, onboarding an existing one, upgrading an older one |
| [`ws-sync`](skills/ws-sync/SKILL.md) | one drift table and a question wherever something needs deciding | a machine you have not used in a while; two computers out of sync |
| [`ws-env`](skills/ws-env/SKILL.md) | a report of variable names and counts only, never a value | credentials missing or stale, a key rotated, a workspace needing env files |
| [`ws-refine`](skills/ws-refine/SKILL.md) | the system changed and audited; it proposes before applying | a workflow step felt wrong or was missing; a fact in a skill is out of date |

[`skills/`](skills/) holds fourteen directories. The fourteenth is `ws-shared`: the reference
the thirteen read by path, carrying `disable-model-invocation: true` and never invoked — so the
count is thirteen skills plus a shared reference they all read.

## What you need

| Need | Required? | For | Without it |
|---|---|---|---|
| **git** | yes | everything — branches, worktrees, and the claim lock on a task file that lives in a repo | there is no loop; the state model is git's |
| **Node 20+** | yes | running agent-sync, which is how the pack reaches your agents | agent-sync will not run (`engines: node >=20`) |
| **[agent-sync](https://github.com/Alpha-30-creator/agent-sync)**, plus a library repo you own | yes | deploying the skills into every agent on every machine | the skills exist nowhere an agent can load them |
| **One of Claude Code, Codex or Cursor** | at least one | somewhere to invoke the skills | nothing to invoke them from |
| **`gh`** | for those | opening and merging PRs in `ws-ship`; the `github-projects` tracker; offered by `ws-setup` and the new-device path | `ws-ship` cannot open the PR for you, and the GitHub Projects tracker is unavailable — the other three adapters and `kind: none` are not affected |
| **`sops` + `age`** | no | `ws-env` only — the encrypted credential store | `ws-env` cannot run; `ws-sync` skips its credentials step. Nothing hard-stops |

**The loop works with no secrets syncing at all.** No other skill *fails* without `ws-env`, and
every one of them still reaches its terminal state. Two of them visibly do less: `ws-sync`
reports its credentials step skipped, and a worktree `ws-start` has just created comes up
without the env files it would otherwise have pulled into it. Neither is a stop. That is not a
special case for credentials — it is the pack's **degrade-never-fail** rule, which also covers
a missing cartridge, a missing key, an unknown tracker and a stack with no pack: less
enrichment, never a hard stop.

## Status: what works and what does not

The pack lives in this repo and is generic. The skills are here, the four tracker adapters plus
`kind: none` are here, and the reference documentation is here. Publishing works:
[`scripts/publish.sh`](scripts/publish.sh) copies the generic skills out of the author's
agent-sync library into this repo, refuses the copy if any known private name survives it, and
`ws-refine` runs it as a step rather than leaving it to be done by hand. That is how everything
you are reading arrived.

The roadmap carries each remaining gap as a task:

| Gap | Task |
|---|---|
| no install path — `INSTALL.md` is not written, so there is nothing to point an agent at | p4.2 |
| no stranger has run the loop end to end from these instructions | p7.1 |

Until p4.2 lands, the way in is to read [docs/product/overview.md](docs/product/overview.md) and
decide whether you want the opinions. [docs/STATUS.md](docs/STATUS.md) says what is being worked
on now.

## Documentation

- [docs/product/overview.md](docs/product/overview.md) — the full argument: the loop, each
  opinion with its objection and its honest limit, the state model, and what this is not. Start
  here.
- [docs/integration/cartridge-schema.md](docs/integration/cartridge-schema.md) — every cartridge
  key: type, default, which skills read it, and what happens when it is missing. For writing
  your own.
- [docs/engineering/sync-direction.md](docs/engineering/sync-direction.md) — how a change
  travels from the working copy to this repo to your agents, and which direction is never valid.
- [docs/engineering/trackers.md](docs/engineering/trackers.md) — adding a tracker kind is one
  file answering four questions, worked end to end on an invented board. Its honest centre is
  that claim is *not* uniform: a task file inside a repo gives a real lock, because a rejected
  push is the mutual exclusion; the same file outside a repo gives none; and a hosted board has
  no atomic claim at all. An adapter without a lock has to say so in those words and re-read the
  item straight after claiming it.
- [docs/engineering/stacks.md](docs/engineering/stacks.md) — how a review's rulebook is
  assembled before it reads the diff, and how to add to it. A tag with no pack behind it is a
  legitimate configuration rather than an unfinished one — this repo is the worked case, with
  `stack: []` and no tier-2 pack at all — and a tag that keeps turning up without one is the
  evidence that a pack should be written.
- [docs/engineering/layout.md](docs/engineering/layout.md) — a map of this repo: what each path
  is, whether it is authored here or a received copy the next publish overwrites, and which
  check looks at it, including what each section of `check.sh` does **not** look at.
- [docs/decisions/](docs/decisions/) — why things are the way they are, including the two
  rejected alternatives for which copy of the skills is authoritative.
- [docs/STATUS.md](docs/STATUS.md) and [docs/roadmap/](docs/roadmap/README.md) — what is in
  flight, and the open problems named as tasks rather than hidden.
- [docs/agent/reference.md](docs/agent/reference.md) — this project's own cartridge, if you want
  to read a real one.

## Pull requests, and the licence

**No pull requests.** This repo is a one-way mirror of one person's working setup: a merge here
would be overwritten by the next publish. Fork it if you want it different.

If you do work in a fork, step one is `git config core.hooksPath .githooks`. This repo is
assembled by copying out of a private setup, and the hook refuses any commit carrying a private
name; without it there is no guard. [CONTRIBUTING.md](CONTRIBUTING.md) is the rest of that
setup, and [SECURITY.md](SECURITY.md) says what the guard does and does not protect — green
means no *known* pattern, never no private data. Which check looks at which path is in
[docs/engineering/layout.md](docs/engineering/layout.md).

[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) applies to the issue tracker, which is the one place
anyone interacts here.

MIT — see [LICENSE](LICENSE). Built on
[agent-sync](https://github.com/Alpha-30-creator/agent-sync).
