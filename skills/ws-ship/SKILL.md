---
name: ws-ship
description: Close out one finished track - commit, open the PR, merge it, mark the task done on the tracker, update the docs it touched, harvest the plan and journal into one durable worklog entry that keeps the rejected alternatives, then delete every ephemeral artefact and remove the worktree. Ends with the work merged, the record written and nothing ephemeral left behind. Also handles a release from the integration branch to production on an explicit go. Use only on an explicit instruction to ship, merge or release - never inferred from work merely looking finished, since it merges and closes the task.
---

# Ship the current track

Ends with the work merged, the tracker closed, **one** durable entry in the docs, and every
ephemeral artefact gone.

## Before anything

Read [../ws-shared/reference.md](../ws-shared/reference.md),
[../ws-shared/tracks.md](../ws-shared/tracks.md), the cartridge, the tracker adapter,
`tracks/current`, and the track's `task.md`, `plan.md`, `journal.md` and `verify/`.

**Gates.** `ws-verify` has passed and `ws-review` says ready. If either has not run, say so and
ask before continuing — do not ship on an assumption.

## 1. Commit

Per repo, on the task branch. **Stage explicit paths**, never `-A`:

```bash
git -C <repo> status --short
git -C <repo> add <paths…>
git -C <repo> diff --cached --stat
git -C <repo> commit -m "<type>(<scope>): <what> (<id>)"
```

Show the exact diff stat and the message, and **wait for a yes**. Hooks always run; never
`--no-verify`. **No AI attribution** when `house_rules.ai_attribution: false` — no
`Co-Authored-By`, no "Generated with", in the commit or the PR.

## 2. PR into the integration branch

```bash
git -C <repo> push -u origin <branch>
gh pr create -R <owner>/<repo> --base <integration> --head <branch> \
  --title "<id>: <title>" --body-file <body>
```

Body: what changed, the acceptance criteria with their evidence, the PR links of sibling repos,
and anything a reviewer should look at first. Link the tracker item so it closes itself where
the tracker supports that.

Then mark the task in-review via the adapter.

## 3. Merge

Only after CI is green and any required review is in. Use the project's merge style
(`merge_style` in the cartridge). **Check `deploy_branches` before merging and say out loud
whether this merge deploys, and to where.** If it does, that needs an explicit go.

Order matters when several repos are involved: whatever the plan said — usually API before web,
and **a migration reaches the database before the code that needs it**.

## 4. Docs

The task is not done until the docs it touched are updated: contracts, schema, setup, design,
decisions. These are repo changes and ship in **this** PR, not a later one.

## 5. Harvest — then delete

The step that keeps the docs clean. Write **one** entry to
`<docs_home>/worklog/<id>.md` (or append to the project's changelog):

```markdown
## <id> — <title> · <date> · <handle>
**What changed:** <2–4 lines>
**Decisions:** <what was chosen, and what was rejected and why>
**Evidence:** <summary — the PR, the checks, which criteria were proved how. Not raw logs>
**Risks learned:** <what went into risks/ or a stack pack, or none>
**Docs touched:** <files>
**PRs:** <urls>
```

Read the journal for that **Decisions** line — the rejected alternatives are the thing currently
lost on every task, and they are the reason this step is mandatory.

Then **offer any new risk class** to `<docs_home>/risks/` or a stack pack, as `ws-review` does.

Then delete the ephemera:

```bash
rm -rf <state_dir>/tracks/<id>            # plan, mockup, journal, verify scratch
rm -f  <state_dir>/tracks/current         # only if it names this track
git -C <docs> rm -q <docs_home>/journal/<id>.md 2>/dev/null   # the mirror
```

Commit the worklog entry and the journal-mirror deletion **together**, so the tree is clean and
the history still holds the record.

**`artifacts: in-repo` differs**: the company wants the plan kept in the repo. Keep
`implementation_plans/<id>/plan.md`; delete only the journal and the verify scratch.

With `worktrees: true`, remove the worktree properly — deleting the folder by hand leaves git
believing it exists:

```bash
git -C <repo> worktree remove "../<project>-tracks/<id>/<repo>"
git -C <repo> worktree prune
```

## 6. Mark it done

Via the adapter, with the PR urls. Then confirm it actually moved — tracker automation does not
always fire.

## Releases

A release from the integration branch to production is a **separate, explicit** act: its own PR,
its own go from the user, after the staging deploy has been verified where staging exists. Never
push a deploy branch directly, never force-push one, never deploy from a local machine.

## Rules

- Never ship without verify and review, or without saying that you are.
- Never `git add -A`, never `--no-verify`, never force-push.
- Never merge into a deploy branch without naming the deployment and getting a yes.
- Never delete the track before the harvest entry is committed.
- Never leave a half-shipped multi-repo task without saying exactly which repos are merged.
- No AI attribution anywhere.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-start` — pick the next task
- `ws-fanout` — more tracks from the same batch still to ship, one at a time
- `ws-task` — file the follow-ups this task turned up
- `ws-sync` — if the other machine should pick this up next
