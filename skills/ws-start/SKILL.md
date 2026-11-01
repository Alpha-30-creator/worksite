---
name: ws-start
description: Begin or resume one unit of work - sync the repos, show what is open and in progress on whichever tracker the project uses, claim a task, create its track directory and optionally its git worktree, then summarise what it asks for. Ends with a claimed task and a summary, never with a plan and never with code. Use at the start of a session, when picking what to do next, when resuming paused work, or when taking over a task someone else wrapped. Not for changing what the work is, which is ws-task, and not for deciding how to build it, which is ws-plan.
---

# Start or resume a track

Ends with a claimed task, a track directory and a summary. **Not** with a plan, and **not** with
code.

## Before anything

1. Read [../ws-shared/reference.md](../ws-shared/reference.md) and
   [../ws-shared/tracks.md](../ws-shared/tracks.md).
2. Resolve the workspace root from `device.yaml`; read the cartridge at `<docs_home>/reference.md`.
   No cartridge → offer `ws-setup` in adopt mode, then continue as best you can (R1).
3. Read `<state_dir>/me` if the project has collaborators. Missing → ask once and write it.
4. Read the tracker adapter for `tracker.kind` from `../ws-shared/trackers/`. Unknown kind → ask
   the four questions in that folder's README and carry on.

## 1. Sync

```bash
for r in <repos>; do
  git -C "$r" fetch --all --prune -q
  printf '%-26s %-24s %s\n' "$r" "$(git -C "$r" branch --show-current)" \
    "$(git -C "$r" status --porcelain | wc -l | tr -d ' ') changed"
done
```

Report any repo that is dirty, behind, diverged, `[gone]`, or not on its integration branch.
**Do not discard anything** — report and ask. Pull the docs repo if the tracker lives there.

## 2. Is something already yours?

Check in this order, because the answer changes what you ask:

```bash
cat <state_dir>/tracks/current 2>/dev/null          # this session's track
ls <state_dir>/tracks/ 2>/dev/null                  # every track on this machine
```

- **`current` is set** → say which track, its stage from the last journal entry, and its "next"
  line. Ask: continue it, or switch? Continuing → re-read the journal and stop here.
- **Other tracks exist** → list them with their last stage, so you can see what you have open.
- **The tracker shows work claimed by you that has no local track** → you claimed it on the
  other machine. Say so, and offer to recreate the track from the journal mirror.

## 3. Show the board

Via the adapter: in progress first (and by whom), then blocked, then pickable now. Recommend one
and say why in a line. **The user picks.** Flag anything that touches the same files as someone
else's in-progress task.

## 4. Claim it

Only once the user has chosen. Follow the adapter exactly, including its retry rule — for a
pushed claim that is **rejected → pull --rebase → re-check it is still open → retry or pick
another**. Never take a task someone else holds. For a handover, only on the user's word that
the other person agreed.

## 5. Create the track

```bash
id=<track-id>                       # the tracker's own id, lowercased, fs-safe
mkdir -p <state_dir>/tracks/"$id"/verify
printf '%s\n' "$id" > <state_dir>/tracks/current
```

Write `task.md`:

```markdown
# <id> — <title>
- Tracker: <kind> · <url or path>
- Claimed: <date> by <handle> on <device>
- Repos: <which this touches>
- Branches: none yet
- Plan: none yet
- PRs: none

## Task, verbatim from the tracker
<the whole thing: description, acceptance criteria, dependencies, links>
```

Then the first journal entry (`claimed`), per `../ws-shared/tracks.md`. If the project has a
`docs_home`, mirror the journal and push it — one commit.

**Taking over a wrapped task**: keep the previous journal entries, add a new `claimed` entry
saying you took it over, and check out the branch the note names.

## 6. Worktree, if the project opted in

Only when `worktrees: true`. Create one **per repo the task actually touches**, not all of them
— the cost is a dependency install per worktree:

```bash
git -C <repo> worktree add "../<project>-tracks/$id/<repo>" -b <branch-pattern-filled-in>
```

Then materialise env into it — a fresh worktree has **no** gitignored files, so nothing runs
until you do:

```
ws-env pull        # writes the env files the cartridge's manifest maps into this tree
```

Say plainly that dependencies need installing in the new worktree, and that every later command
runs against `<worktree>/<repo>`, not the main checkout.

## 7. Summarise, then stop

Three to five bullets: what the task asks for, which repos it touches, which spec or source
applies, and anything unclear or blocked. **Do not plan. Do not write code.**

## Rules

- Never code on an unclaimed task.
- Never claim without the adapter's re-check-after-rejection step.
- Never set `current` for a track you did not just claim or resume.
- Never discard uncommitted work to make a clean start — ask.
- One track is current per session; several tracks may exist at once.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-plan` — plan it before writing code
- `ws-fanout` — run two to five tracks at once instead of one
- `ws-debug` — it is a bug with an unknown cause
- `ws-task` — it is too big, unclear, or something is missing from the tracker
- `ws-wrap` — stopping again already
