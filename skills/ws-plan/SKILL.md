---
name: ws-plan
description: Decide the approach for an already-claimed task before any code - refresh the repos, read the task's sources and the decisions that touch it, write the API contract first for backend work and an interactive mockup for UI work, name where the documentation this change produces will live, then stop for approval and create the branches. Ends with an approved plan, never with code written. Use after claiming a task, when entering plan mode, or when designing a screen or an endpoint before building it. Not for finding out why something broke, which is ws-debug, and not for changing the task itself, which is ws-task.
---

# Plan the current track

Ends with **an approved plan**, not with code written.

## Before anything

1. Read [../ws-shared/reference.md](../ws-shared/reference.md) and
   [../ws-shared/tracks.md](../ws-shared/tracks.md); read the cartridge.
2. Read `<state_dir>/tracks/current`, then that track's `task.md` and `journal.md`.
   No current track → ask for `ws-start`. **Never plan an unclaimed task.**
3. Trivial docs or copy change? Say so and offer to skip straight to the work.

## 1. Refresh before believing anything

```bash
while IFS= read -r r; do
  [ -n "$r" ] || continue
  _pfx=$(git -C "$r" rev-parse --show-prefix 2>/dev/null) && [ -z "$_pfx" ] \
    || { echo "NOT A REPO ROOT: $r — run that rev-parse by hand to see why"; continue; }
  git -C "$r" fetch --all --prune -q
  printf '%-24s behind/ahead %s\n' "$r" "$(git -C "$r" rev-list --left-right --count origin/<integration>...HEAD)"
  git -C "$r" status --short | head -5
done <<'REPOS'
<repo paths, one per line>
REPOS
```

Read line by line, never `for r in <repos>`: a workspace path containing a space word-splits
under bash, every `git -C` fails on a fragment, and the block still prints a row per fragment
with an empty `behind/ahead` — a refresh that refreshed nothing, at exit 0. The `rev-parse` line
catches the other half: a wrong *fill* now prints a named `NOT A REPO ROOT` instead of another
empty row. **That line is not a result** — fix the fill and run it again. It is loud but not
fatal, so read the output rather than the exit status.

Read the code you plan around **as it is on the integration branch**, without checking anything
out:

```bash
git -C <repo> show origin/<integration>:<path>
git -C <repo> grep -n "<term>" origin/<integration> -- src/
```

## 2. Read the sources

- The task's own source: the spec screen, the current site, the scope row, the issue body.
- Decisions that touch this area — grep the project's `decisions/` if it has one. **A decision
  the task depends on that has not been made yet is a blocker**: either make it through the
  task, raise it as its own task via `ws-task`, or record it as a question. Do not quietly build
  around an undecided question.
- Existing contracts, the schema, and the practices docs for the repos touched.
- `<docs_home>/risks/` — the known traps in this project — **and the `ws-shared/stacks/` pack
  for each `stack:` tag on the repos the plan touches**. These are the rulebooks `ws-review`
  will judge the result against, so plan around them now rather than meeting them in review.

## 3. Write the plan

`<state_dir>/tracks/<id>/plan.md` (or `<repo>/implementation_plans/<id>/plan.md` when
`artifacts: in-repo`). In Codex or Cursor, use native plan mode and write the file only if asked.
**Never into a repo** unless `artifacts: in-repo` says to.

1. **Plain-English summary** — what changes, for whom.
2. **Task snapshot** — the task block verbatim, so later steps need not re-read the tracker.
3. **What the user sees** — fields, labels, who can see or edit, and the empty, loading, error
   and long-text states, at the project's wide and narrow widths. Backend-only: "none".
4. **API contract first** (backend) — the draft contract doc in the project's template: routes,
   auth and permission, request and response shapes, errors. It may be committed right after
   approval so frontend work marked "(contract)" can start in parallel.
5. **Technical approach** — modules, data flow, real paths, and the edge cases: concurrency,
   money, permissions, partial failure of anything external.
6. **Repos and order** — API before web where web consumes a new endpoint.
7. **Database** — none, or which tables change, then the migration rules.
8. **Branches** — per repo, from the cartridge's `branch_pattern`.
9. **Steps** — small, ordered, each independently checkable. **These become the journal's
   `step <n>` entries, so make them real boundaries.**
10. **Verification** — the evidence `ws-verify` will produce, mapped to each acceptance
    criterion, one by one.
11. **Docs impact** — not a list of destinations but a **decision**: name the writing this
    change will produce and where each piece lives. Contracts, schema, setup, design, status as
    before, and in particular: a choice whose alternatives were rejected is an **ADR** in
    `decisions/`; a fact about how the system composes goes in `engineering/`; a measurement with
    a date goes in `records/`. **Carry each as an acceptance criterion**, so `ws-verify` checks it
    shipped. Writing with no home named at plan time is what ends up as a thirty-line comment.
12. **Cost** — paid API calls the work or its checks need, and roughly how many. Prefer fakes
    behind a port.
13. **Out of scope** — and anything found along the way, for `ws-task`.
14. **Open questions** — blocking vs not.

Name anything that does not exist yet (an environment, a service, a credential) rather than
planning as if it does.

## 4. Mockup gate — UI tasks

Required when the task adds a screen, a control, or an interactive state, or changes a flow or a
layout. Not for copy-only or backend-only work.

Write a self-contained `mockup.html` in the track directory and open it:

- **Real tokens** from the project's design system, not a generic wireframe palette.
- **Composed from existing primitives**; a new primitive is called out as new.
- **True widths**, both breakpoints, side by side.
- **Interactive** — hover, click, what follows, validation.
- **The easy-to-forget states**: empty, loading, error, long text, logged out, keyboard focus.
- **Against the spec** where one exists, with deliberate differences listed.
- **Current behaviour read from the code**, not from memory.

Present it and **stop**. Expect the design to change; that is why this gate is before the code.

## 5. Approval, then branch

Show the plan (and mockup) and **wait for a yes**. Then, per repo touched — asking about
uncommitted work first, never discarding it:

```bash
git -C <repo> switch <integration> && git -C <repo> pull --ff-only
git -C <repo> switch -c <branch>
```

With `worktrees: true`, the worktree and branch already exist from `ws-start`; work there.

**Before writing any code, load the rule skills for what the plan touches** — the project's
`<prefix>-<area>` skills. If your agent cannot invoke a skill, read its `SKILL.md` and the
`rules/<area>.md` it points at. They are the build step's rulebook; building without them is not
following the plan.

Update `task.md` (`Branches:`, `Plan:`) and append a `planned` journal entry whose `next` line is
plan step 1. Mirror and push the journal if the project has a `docs_home`.

## Rules

- **Do not widen scope.** The acceptance criteria are the contract; changing them goes through
  `ws-task`.
- If docs and code disagree, the code wins and the plan includes the doc fix.
- Plan and mockup are ephemeral: `ws-ship` harvests then deletes them.
- Write the journal entry even if the plan is rejected — "rejected: this approach, because…" is
  the most valuable line in the file.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- Build it, following the project's rule skills
- `ws-start` — there is no current track to plan, so claim one first
- `ws-verify` — prove it works
- `ws-review` — independent review before shipping
- `ws-task` — it is too big, or something out of scope turned up
- `ws-wrap` — stopping before it is built
