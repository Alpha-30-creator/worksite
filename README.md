# worksite

**A disciplined task loop for coding agents — plan, build, prove, review, ship — that works the
same way in every project you own.**

## The problem

An agent will write the code and lose almost everything around it: what the task actually was,
the plan it agreed to, whether the result was ever proved, and — when the session compacts or the
laptop closes — whatever it had worked out. None of that is a model defect to be prompted away;
each is a missing **stopping point**, and nothing in a chat has a defined end state for "done" to
be measured against. And every repo re-solves it alone, in its own half-remembered dialect, so
the effort never compounds.

## What it is

Thirteen skills and one shared reference they all read by path. Each skill refuses to finish
without producing one specific named thing — the table below says which — and every fact that is
particular to your project lives in a single declarative file, the **cartridge**, rather than
inside the skills. So the skills stay generic, the cartridge makes them yours, and improving a
skill improves every project you own.

The pack is opinionated in four ways that each cost you something real: a gate that stops before
the build, evidence mapped to every acceptance criterion, a review run where none of the writing
conversation exists, and a coordinator forbidden from writing code.
[docs/product/overview.md](docs/product/overview.md) is the argument for all four — each with the
objection worth taking seriously and its honest limit. This page does not re-argue them.

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

A stranger has now run it. Two agents with none of this project's history installed the pack from
`INSTALL.md` alone and then ran the loop end to end on a real task — 44 points where they had to
guess, ask or improvise, [recorded with the date](docs/records/2026-11-02-stranger-install-dry-run.md)
and each one closed as a fix, a written limitation or a filed task rather than a note to self: five
`INSTALL.md` fixes, three limitations, two tasks that have both since shipped, and one criterion
added to the third row below.

The gaps a reader would still hit, each carried as a task:

| Gap | Task |
|---|---|
| a project with no git remote has no documented way to retire a finished track; the guard that refuses is correct, the workaround is undocumented | p8.40 |
| `ws-refine` ends by pushing the whole library while `ws-fanout` forbids its subagents to push, so a library track inside a fanout batch is instructed both ways | p8.30 |

Three more open tasks are about this repo's own authoring and tooling rather than anything a reader
would meet; [docs/STATUS.md](docs/STATUS.md) has them.

**To install it**, point your agent at [INSTALL.md](INSTALL.md) — it is written for the agent
rather than for you, and it stops rather than guessing whenever only you can answer. If you would
rather decide before installing, [docs/product/overview.md](docs/product/overview.md) is the
argument with its objections answered. [docs/STATUS.md](docs/STATUS.md) says what is being worked
on now.

## Documentation

- [docs/README.md](docs/README.md) — the map of the docs tree: which page answers which
  question, and which folders are living versus immutable. The index for everything below.
- [INSTALL.md](INSTALL.md) — the install, addressed to an agent: prerequisites, the library, the
  comparison that runs before anything is written, and where to go for the first project.
- [docs/product/overview.md](docs/product/overview.md) — the full argument: the loop, each
  opinion with its objection and its honest limit, the state model, and what this is not. Start
  here.
- [docs/integration/cartridge-schema.md](docs/integration/cartridge-schema.md) — every cartridge
  key: type, default, which skills read it, and what happens when it is missing. For writing
  your own.
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
  check looks at it, including what each section of `check.sh` does **not** look at. It also
  holds where `skills/` comes from and what a publish does, step by step.
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
