---
name: ws-task
description: Change what the work is, on whatever tracker the project uses - add a task for a new requirement, bug or follow-up, split one that is too big, re-scope its acceptance criteria, reorder or drop it, or record a question that blocks it, keeping ids, dependencies and the status view consistent. Ends with the tracker changed; it never implements anything and never creates a branch. Use when something is missing from the tracker, a task is too big or unclear, a bug is found, or scope changes. Not for a bug whose cause is still unknown - that is ws-debug first, or the task becomes a guess.
---

# Change the tracker

**Never implements anything. Never creates a branch.** It changes what the work *is*.

## Before anything

Read [../ws-shared/reference.md](../ws-shared/reference.md), the cartridge, and the adapter for
`tracker.kind` in `../ws-shared/trackers/`. Refresh first — for a file-based tracker,
`git -C <docs> pull --rebase -q`.

## 1. Understand the change

Clarify until you can state all of these. If you cannot, ask rather than writing a vague task —
a vague task is the main cause of agent work going wrong:

- **What** should be true when it is done — the outcome, not the implementation.
- **Why**, and from whom: a spec page, a decision, a bug, the user, a review finding.
- **Which repos** it touches, and where it belongs in the order.
- For a bug: where it shows, how to reproduce, expected vs actual. **Cause unknown → `ws-debug`
  first.** Filing a bug whose cause is unknown as a task to "fix X" produces a guess.

Check it is not already there: search the tracker, and the project's scope or requirements doc.

## 2. Draft

| Change | How |
|---|---|
| **New task** | Next free id. Acceptance criteria as checkable, observable outcomes. Half a day to a day of work — bigger, split it |
| **Split** | Keep the original id for the first part, add ids for the rest; move the unmet acceptance criteria; **fix every dependency that pointed at the original**. Never split someone else's in-progress task without them |
| **Re-scope** | Edit the acceptance criteria and add a note: `<date> re-scoped by <handle>: <why>` |
| **Drop** | Mark dropped with the reason; anything depending on it gets re-pointed or dropped too |
| **Decision** | A task whose acceptance is a written decision record; tasks it blocks get marked blocked, with a note saying which decision |
| **Question** | Record it where the project puts open questions, referenced from the task it blocks |

**Acceptance criteria describe observable outcomes** — "a member can…", "the endpoint
returns…", "the export includes…" — never code structure. This is what `ws-verify` and
`ws-review` check against, so a criterion that cannot be observed cannot be verified.

Also update whatever the project uses as its status view, and its scope or requirements doc if a
requirement moved.

## 3. Show it, then commit

Show the **exact** diff — the task blocks and every other file — and wait for a yes. Then apply
it via the adapter, with its retry rule: a rejected push means
`pull --rebase`, re-check the ids are still free, retry.

## Rules

- Never implement, never branch, never touch code.
- **Ids are never reused**, even for dropped tasks. Next id = highest ever used plus one.
- Never change someone else's in-progress task beyond adding a note, unless they agreed.
- Never invent a dependency; only reference ids that exist.
- A follow-up found mid-task is filed here, not done inline — that is how scope creep starts.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-start` — claim the new task
- `ws-plan` — re-plan, if you just split your own current track
- `ws-debug` — the bug's cause is still unknown
