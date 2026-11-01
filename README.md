# worksite

**A disciplined task loop for coding agents — plan, build, prove, review, ship — that works the
same way in every project you own.**

> ### Pre-release
> The repo exists; the pack does not live here yet. The skills are being de-personalised and the
> install path is being written. **There is nothing to install today.** Progress is in
> [docs/STATUS.md](docs/STATUS.md).

## The problem

Agents are good at writing code and bad at everything around it. They start without knowing what
the task is, skip the plan, declare success without evidence, review their own work, and leave
nothing behind when the session dies. Every project you own has the same gap, so you solve it
again in every repo, slightly differently, and none of it survives a compaction.

worksite is thirteen skills that close that gap once. Each one ends with a specific thing and
refuses to end with anything else: `ws-plan` ends with an **approved plan**, not with code.
`ws-verify` ends with **evidence against each acceptance criterion**, not with "looks right".
`ws-review` runs in a fresh context that **did not write the code**. `ws-debug` ends with a
**confirmed cause**, not a fix that seems to work.

## Four design moves

- **Generic skills, per-project cartridge.** No skill knows anything about your projects. Repos,
  tracker, branch flow, environments and house rules live in one file per project, so one pack
  covers all of them.
- **Tracker adapters.** GitHub Projects, Trello, roadmap files, a `TASKS.md` — each answers the
  same four questions (list, claim, mark, note), so no skill knows which you use. Adding one is a
  new file, never a skill edit.
- **Tracks and an append-only journal.** Work gets its own state, so two sessions cannot collide,
  and every skill writes a journal entry at each stage boundary — automatically, because if it
  depends on someone remembering it is not there when it matters. A cold session resumes from it.
- **Harvest, then delete.** Plans, mockups and journals are deleted when a task ships. One
  distilled entry survives, and it keeps the **rejected alternatives** — which a PR never does.

## Dependencies

| Need | For | Required? |
|---|---|---|
| Node 20+, git | [agent-sync](https://github.com/Alpha-30-creator/agent-sync) | yes |
| agent-sync, plus a library repo you own | deploying the pack to your agents and machines | yes |
| Claude Code, Codex or Cursor | somewhere to run the skills | at least one |
| `gh` | opening PRs; the GitHub Projects tracker | for those |
| `sops` + `age` | `ws-env`, which syncs credentials between your machines | no |

**The loop works with no credential syncing at all.** `ws-env` is one skill of thirteen, and
every other skill degrades rather than failing when something is missing.

## Documentation

- [docs/STATUS.md](docs/STATUS.md) — what is being worked on now, and what is next
- [docs/roadmap/](docs/roadmap/) — the phases to a release
- [docs/decisions/](docs/decisions/) — why things are the way they are

The reference documentation does not exist yet; it is phase P3. These folders get created when
there is something to put in them, which is what the pack's own living-docs rule asks for.

## Contributing

Not yet — the pack is not in the repo. When it is, step one will be
`git config core.hooksPath .githooks`: this repo is assembled by copying out of a private setup,
and the hook refuses any commit carrying a private name.

MIT. Built on [agent-sync](https://github.com/Alpha-30-creator/agent-sync).
