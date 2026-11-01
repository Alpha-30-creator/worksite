# Tracks and the journal

The state model every loop skill shares. Read this before `ws-start`, `ws-plan`, `ws-verify`,
`ws-ship`, `ws-wrap`, `ws-debug`.

## Why tracks exist

One active task per workspace breaks the moment you run two chats. A **track** is one unit of
work with its own state, so each session knows which one it is on and they cannot collide.

```
<state_dir>/
  me                      your handle, if the project has collaborators
  tracks/
    current               ONE LINE: the track id this session is on
    <track-id>/
      task.md             the task verbatim from the tracker, plus metadata
      plan.md             the approved plan
      journal.md          append-only (see below)
      mockup.html         UI tasks only
      verify/             evidence and scratch
```

`tracks/current` is **per session, not per machine**. Two chats on one machine each set it when
they start, and every skill reads it rather than assuming. If it is missing or names a track
that does not exist, ask which track — never guess.

**Track id** = the tracker's own id, lowercased and filesystem-safe: `p3.2`, `issue-116`,
`card-6f2a91`, `t-14`. Never invent a parallel numbering scheme.

## Where the files live

Set by `artifacts:` in the cartridge:

| `artifacts` | Files live in | Crosses machines by |
|---|---|---|
| `workspace-state` (default) | `<state_dir>/tracks/<id>/` — uncommittable | the journal mirror, below |
| `in-repo` | `<repo>/implementation_plans/<id>/` — committed on the task branch | the branch itself |

`in-repo` is a company convention on some projects — the plan is wanted in the repo, with the
code. Respect it; do not argue with it.

## The journal — the cross-session fix

The problem it solves: today a plan is written at the start and a resume note at the end, so a
session that compacts or dies **in the middle** loses exactly the part nobody wrote down —
which plan step you reached, what you already tried, what turned out to be wrong.

**Skills append to it at every stage boundary. Not when asked.** That is the whole point: if it
depends on someone remembering, it is not there when it matters.

One entry per boundary, appended, never rewritten:

```markdown
## <stage> · <YYYY-MM-DD HH:MM> · <device> · <handle>
- did: <what actually changed — files, decisions, commands that mattered>
- next: <the single next step, concrete enough to act on cold>
- rejected: <what was tried and abandoned, and why — this is the part that saves the most time>
- open: <questions, or none>
```

Stages: `claimed`, `planned`, `step <n>` (one per completed plan step), `verified`, `reviewed`,
`paused`, `shipped`.

**Resuming cold** = read `task.md`, then `plan.md`, then the last two or three journal entries.
That is the whole recovery path, and every skill that writes a journal entry owes a reader that
property.

### Crossing machines

`workspace-state` files cannot be committed, so the journal is **mirrored** to
`<docs_home>/journal/<track-id>.md` and pushed — **one commit per stage, not per thought**.
`docs_home` is the project's docs folder or docs repo, so the mirror travels with the project.
`ws-ship` deletes it.

`artifacts: in-repo` projects need no mirror — the task branch already carries the files.
`lite` projects with no `docs_home` get a local journal only; say so once when the track is
created, so nobody expects it on the other machine.

## Running several tracks at once

Tracks make this possible; two things make it **safe**, and both are in `ws-fanout`:

1. **Isolation.** `worktrees: true` gives each track its own checkout. With `worktrees: false`
   every track shares one working tree and two agents editing it overwrite each other silently.
2. **File ownership assigned before any work starts.** Two tracks that touch the same file do not
   run in the same batch — the overlapping one is dropped and run afterwards.

`tracks/current` is for a **single** session on one track. A lead session running several does not
set it; each subagent is told its track explicitly.

Cap: **five in flight**, builders and reviewers counted together.

## Artifact lifespan — the rule that keeps docs clean

| Class | What | Lifespan |
|---|---|---|
| **Ephemeral** | plan, mockup, journal, verify scratch | deleted at ship, **always** |
| **Harvested** | one distilled entry per task | permanent, in `docs_home` |
| **Permanent** | the cartridge, `risks/`, `rules/` | permanent, edited deliberately |

So `ws-ship` **harvests then deletes**. Nothing ephemeral survives a shipped task. The exception
is `artifacts: in-repo`, where the company wants the plan kept in the repo — there, ship keeps
the plan and deletes only the journal and scratch.

The harvested entry goes to `<docs_home>/agent/worklog/<track-id>.md`. The PR description and
the tracker item are the project's record; the worklog is the part that keeps the **rejected
alternatives**, which a PR never does. Anything that turned out to be a durable fact about the
system belongs in `engineering/` or `decisions/` instead, in the same change.

```markdown
## <track-id> — <title> · <date> · <handle>
**What changed:** <2–4 lines>
**Decisions:** <what was chosen, and what was rejected and why>
**Evidence:** <summary, not raw logs — point at the PR and the checks>
**Risks learned:** <added to risks/ or a stack pack, or none>
**Docs touched:** <files>
**PRs:** <urls>
```

That "decisions, including rejected" line is the thing currently lost every time. It is why the
harvest is mandatory rather than optional.
