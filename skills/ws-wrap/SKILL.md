---
name: ws-wrap
description: Pause a track cleanly without closing it - push work in progress to the task branch, write a resume note into the journal and onto the tracker, and optionally hand it over or release the claim. Ends with the work saved and a note that a session with no memory of this one can resume from. Use when stopping for the day mid-task, switching tracks, running low on context, or handing work to someone else. Not for finishing a task, which is ws-ship; this deliberately keeps the track open.
---

# Pause the current track

Ends with the work saved and a note that lets **a session with no memory of this one** resume.

## Before anything

Read [../ws-shared/reference.md](../ws-shared/reference.md),
[../ws-shared/tracks.md](../ws-shared/tracks.md), the cartridge, the tracker adapter,
`tracks/current`, and the track's `task.md`, `plan.md` and `journal.md`.

**With `kind: none`** there is no tracker to put the resume note on, so the journal carries it
alone — say that, because the note is then the only copy and the wording matters more, not less.

## 1. Save the work

Per repo with changes, on the task branch — create it if the work is still on the integration
branch:

```bash
git -C "<repo>" status --short
git -C "<repo>" add <paths…>        # <paths…> is deliberately UNQUOTED: it is several words
git -C "<repo>" commit -m "wip(<area>): <what is in this commit> (<id>)"
git -C "<repo>" push -u origin <branch>
```

**A repo with no remote cannot run that last line**, and unguarded it emits a raw
`fatal: 'origin' does not appear to be a git repository` with no explanation — which is what a
stranger on a local-only project actually sees, and the exit `ws-start`'s stale sweep points such
a track at (p8.40). Check first, and say which of the two happened:

```bash
if [ -z "$(git -C "<repo>" remote)" ]; then
  echo "no remote: the commit above is saved locally and nothing was pushed."
  echo "The work is on branch <branch> in this repo, and the resume note has to say so."
else
  git -C "<repo>" push -u origin <branch>
fi
```

The track is still wrapped either way — the commit is what stops work being lost to a stray
`git checkout`, and the push is what gets it to another machine. Say plainly which protection the
project has.

`wip` is allowed **on a task branch only**. Show the commit and wait for a yes.

Hooks still run. If lint or typecheck fails on half-finished work, say so and ask: fix it now,
or skip only the failing check with an explicit OK. **Never `--no-verify` silently.**

Untracked files that matter get committed too — a file nobody staged is the most common thing
lost between machines.

## 2. Write the resume note

This is the whole point of the skill, so make it good. Append a `paused` journal entry:

```markdown
## paused · <YYYY-MM-DD HH:MM> · <device-alias> · <handle>
- did: <what is done, and what is half-done — be specific about half-done>
- next: <the single next step, concrete enough to act on with no context>
- rejected: <what was tried and abandoned, and why>
- open: <questions, blockers, anything surprising>
- state: <branches per repo, how to run and verify what exists, anything not committed>
```

Then put a one-line version on the tracker via the adapter, so it is visible to a person and to
the other machine.

`<device-alias>` is the derived alias defined in
[../ws-shared/tracks.md](../ws-shared/tracks.md), **not** the `device:` value from `device.yaml`.
This is the only skill that writes a journal entry from its own template rather than from that
page, so it is the one place the rule has to be repeated — and the entry it writes is the one
that gets pushed.

If the project has a `docs_home`, **mirror and push the journal** — without that push, the note
does not reach your other laptop, which is usually the reason you are wrapping. A machine is
commonly named after the person who owns it and the docs home may be public, which is why the
header carries an alias.

## 3. Keep, hand over, or release

Ask:

| Choice | Tracker | Track directory |
|---|---|---|
| **Keep it** — I'll resume | stays claimed by you | kept, `current` cleared |
| **Hand over** | stays claimed, note says "handover offered" | kept; they take it via `ws-start` once you have agreed |
| **Release** | back to open, note kept, branch kept | kept locally |

Clear `<state_dir>/tracks/current` either way — this session is done with it. **Keep the track
directory** unless the task was released *and* the user says to discard it; it costs nothing and
it is the resume path.

## Rules

- Never leave work only in the working tree. Unpushed work does not exist on the other machine —
  but a project with no remote has nowhere to push, so there the commit is the whole protection
  and the note has to name the branch.
- Never `--no-verify` without an explicit OK, and never silently.
- Never write a resume note that assumes the reader was here. Name files, branches and commands.
- Never release a task someone is waiting on without saying so.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-start` — resume it later, or pick something else now
- `ws-sync` — before picking it up on the other machine
