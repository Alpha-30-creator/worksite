---
name: ws-ship
description: Close out one finished track - commit, open the PR, merge it, mark the task done on the tracker, update the docs it touched, harvest the plan and journal into one durable worklog entry that keeps the rejected alternatives, then delete every ephemeral artefact and remove the worktree. Ends with the work merged, the record written and nothing ephemeral left behind. Also handles a release from the integration branch to production on an explicit go. Use only on an explicit instruction to ship, merge or release - never inferred from work merely looking finished, since it merges and closes the task.
---

# Ship one finished track

Ends with the work merged, the tracker closed, **one** durable entry in the docs, and every
ephemeral artefact gone.

## Before anything

### Resolve the track id, and say it out loud

Every command below substitutes it: the commit message, the PR title, the worklog path and its
heading, the `rm -rf`, the journal mirror, the worktree paths, the `in-repo` plan path. **An
unresolved id is a stop, not a quiet no-op** — `rm -rf <state_dir>/tracks/` with nothing after it
deletes *every* track on the machine, claimed ones included. That is why the id is resolved
first, echoed, and guarded again inside the retirement block itself.

**First match wins:**

1. **An id given with the invocation** — `/ws-ship p3.2`, `$ws-ship p3.2`, the `Skill` tool's
   `args`, or prose from a lead: "ws-ship, track p3.2". Use it, and **do not read
   `tracks/current` at all** — a stale `current` naming an earlier track is exactly how the
   wrong track gets cleaned up.
2. **Otherwise `<state_dir>/tracks/current`**, if it exists and names a directory that exists.
   Its absence is normal, not an error: a `ws-fanout` lead never writes it, `ws-wrap` clears it
   on all three of its paths while deliberately keeping the track, and a compacted or restarted
   session has lost it too. Any of those arrives here with no `current`.
3. **Otherwise, if exactly one directory exists under `<state_dir>/tracks/`** — name it and ask
   for a yes. Do not assume.
4. **Otherwise list the track directories with their last journal stage, and ask which.**

Then echo one line, before reading anything else:

```
shipping track: p3.2 (<state_dir>/tracks/p3.2)
```

That resolution is `$id`, and it is the only source of `<id>` anywhere below.

### Then read

[../ws-shared/reference.md](../ws-shared/reference.md) and
[../ws-shared/tracks.md](../ws-shared/tracks.md) — including its **Retiring a track** section,
which section 6 runs — the cartridge, the tracker adapter, and the track's `task.md`, `plan.md`,
`journal.md` and `verify/`.

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

## 5. Harvest

The step that keeps the docs clean, and it is a step of its own: a section named for two jobs is
a section that gets half done. Write **one** entry to
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

Append the `shipped` journal entry now, while the journal still exists, and **commit the worklog
entry**. Nothing is deleted until that commit exists — the worklog is the only copy of the
rejected alternatives once the journal is gone.

## 6. Retire the track

Follow **Retiring a track** in [../ws-shared/tracks.md](../ws-shared/tracks.md). That section is
the authority — four skills run this same job, and four copies of it would drift. What it does,
for `$id`:

1. **Resolve the repos and worktrees** from `task.md`'s `- Repos:` and `- Worktrees:` lines,
   cross-checked against `git worktree list --porcelain` per repo. `ws-start` creates one
   worktree **per repo the task touches**, so a single `worktree remove` under-removes.
2. **Check every worktree is clean and pushed.** Uncommitted changes, unpushed commits, **or a
   branch with no upstream at all** are each a **refusal**: report it and stop. Do not remove it,
   do not stash it. The no-upstream case is the dangerous one — those commits exist nowhere
   else — and the obvious `log @{u}..HEAD 2>/dev/null` cannot see it, so the shared block uses a
   separate upstream check.
3. **Show what you are removing, then wait for a yes.** Yes, even here, with the harvest
   already committed — retirement is a delete, and the house rule has no exception for a delete
   the user will probably approve. One line: the worktrees, the track directory, and the branches
   and PRs that survive.
4. **`worktree remove` per repo, then `worktree prune` per repo**, then `rm -rf` the track
   directory, `tracks/current` **only if it names `$id`**, and `git rm` the journal mirror if it
   is tracked. Commit that mirror deletion. **Run that block whole, in one shell** — its first
   line is the guard that bounds the `rm -rf`, and a fragment of it run on its own has no `$id`.
5. **Print the verification line** — one line: `clean: track p3.2 removed`, or `NOT REMOVED: …`
   naming every survivor. It asks git about worktrees, not the filesystem.

**`artifacts: in-repo` differs**: the company wants the plan kept in the repo. Keep
`implementation_plans/$id/plan.md` and retire only the journal, the verify scratch and the
worktree, and say the plan was kept.

## 7. Mark it done

**Not until section 6 has printed its verified line.** A task marked done with its track still on
disk is the exact failure this closing step exists to prevent, so the tracker transition is the
thing held hostage — not a reminder for later. If section 6 printed `NOT REMOVED`, say so and
stop here.

Via the adapter, with the PR urls. Then confirm it actually moved — tracker automation does not
always fire.

Then the last thing the skill outputs: one line, the track id and five facts.

```
shipped p3.2 — merged <prs> · worklog <path> · track removed · 2 worktrees removed · tracker [x]
```

Any fact that is not true says so **in that same line** — `track NOT REMOVED: …`,
`tracker not confirmed`. The failure this defends against is a session that ends mid-way and
reports success anyway, so the line is written from what the commands printed, never from what
was intended.

## Releases

A release from the integration branch to production is a **separate, explicit** act: its own PR,
its own go from the user, after the staging deploy has been verified where staging exists. Never
push a deploy branch directly, never force-push one, never deploy from a local machine.

## Rules

- Never ship without verify and review, or without saying that you are.
- **Never ship a track whose id you could not state.** If resolution reached step 4 and nobody
  has answered, stop. Cleaning up the wrong track is the one unrecoverable thing here.
- Never `git add -A`, never `--no-verify`, never force-push.
- Never merge into a deploy branch without naming the deployment and getting a yes.
- Never delete the track before the harvest entry is committed.
- **Never mark the task done before the track is removed and the removal verified.** With the
  rule above it, that brackets the closing step from both sides.
- Never remove a worktree that holds uncommitted work, unpushed commits, or a branch with no
  upstream. Report it and stop — retiring a track removes session state, never work.
- **Never run the retirement block in pieces, and never with an unresolved id.** Both end in the
  same place: an `rm -rf` whose target is `<state_dir>/tracks/` itself.
- Never leave a half-shipped multi-repo task without saying exactly which repos are merged.
- No AI attribution anywhere.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-start` — pick the next task
- `ws-fanout` — more tracks from the same batch still to ship, one at a time
- `ws-task` — file the follow-ups this task turned up
- `ws-sync` — if the other machine should pick this up next
