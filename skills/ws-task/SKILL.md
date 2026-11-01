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
| **Drop** | **When:** nothing has depended on it for two phases; or a shipped task has covered its consequence; or it was filed where *Where a finding belongs* would now send it elsewhere; or the board has grown past what the open work can absorb and this is the row you would not miss. Mark dropped with the reason **on the heading line**; anything depending on it gets re-pointed or dropped too; **then retire its track if one exists locally** (below) |
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

### After a drop, retire the track

Dropping is the only way a task legitimately ends **without shipping**, so this is the one place
that cleanup path has an owner. Nothing else ever looks.

```bash
ls <state_dir>/tracks/<id>/ 2>/dev/null
```

Nothing there → done. If the directory exists:

1. **Harvest three lines first.** A dropped track has no `ws-ship` harvest, so its journal —
   including its `rejected:` lines, the most valuable content in the pack — is about to be
   deleted with the directory. Read it and write a stub to
   `<docs_home>/worklog/<id>.md`, in the harvest format, and commit it:

   ```markdown
   ## <id> — <title> · <date> · <handle>
   **Dropped:** <why, and who decided>
   **Decisions:** <what was rejected while it was open, and why — from the journal>
   **Survives:** <branches, commits and PRs kept, by name>
   ```

2. **Then follow *Retiring a track*** in [../ws-shared/tracks.md](../ws-shared/tracks.md): say
   what survives, show it, **wait for a yes**, remove per repo, verify, print the one-line
   result. A dropped task's **branches and commits are kept** — dropping is a scope decision,
   not a decision to destroy work, and the branch is often why someone revisits it.

Removing session state is neither implementing nor branching, so this does not breach this
skill's boundary.

## Where a finding belongs

**Everything found gets recorded. Not everything found is a task.** A task is work someone will
do, and the board is read before every claim — so a board holding rows nobody will act on charges
every future session the time to read them again.

| The finding | Where it goes |
|---|---|
| Something **reports success while doing the wrong thing**; a check or gate can pass without running; work would be lost; a private name or a secret could escape | **a task.** These are the ones worth interrupting a board for, and they are also the ones that read as pedantry and are not — never route one of these away because it looks small |
| Wrong behaviour, a gap a user would hit, or something the project's stated goal needs | **a task** |
| A wording, numbering, citation or consistency defect; authoring friction; a limitation that is honest once stated | **one line in the track's worklog entry**, or the project's limitations record where it keeps one. Not a task |
| It exists **only because another change moved something** | the worklog entry of the change that moved it. It becomes a task when the mechanism recurs across three changes |

A finding recorded in the right place is closed, not dropped. Say which place you chose in one
line and move on: *"not filing this — it is a line in the limitations record instead"* is a
complete answer, and it is the answer more often than filing is.

## Rules

- Never implement, never branch, never touch code.
- **Ids are never reused**, even for dropped tasks. Next id = highest ever used plus one.
- Never change someone else's in-progress task beyond adding a note, unless they agreed.
- Never invent a dependency; only reference ids that exist.
- A follow-up found mid-task is **not done inline** — that is how scope creep starts. Whether it is
  *filed* is a second question, and *Where a finding belongs* below answers it. Letting one go, on
  the record, is a legitimate outcome and a common one.
- **Dropping is part of the job, not a failure.** A board that only ever grows is a board nobody
  reads. `[-] <reason>` on the heading line is maintenance, and the reason is what makes it safe.
- **A drop keeps branches, commits and PRs.** It retires session state only, after a yes, and
  only after the three-line worklog stub is committed.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-start` — claim the new task
- `ws-wrap` — a dropped task's worktree still holds work you want pushed first
- `ws-plan` — re-plan, if you just split your own current track
- `ws-debug` — the bug's cause is still unknown
