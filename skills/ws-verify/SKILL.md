---
name: ws-verify
description: Prove the current work does what the task asked - run the repos' own checks, then produce evidence mapped one by one to each acceptance criterion, keeping the artefacts in the track's verify directory and recording what could not be proved. Ends with evidence against every criterion, never with looks right. Use after building and before review, when asked whether something actually works, or when a deploy needs confirming. Not an independent code review, which is ws-review; this proves behaviour rather than judging quality.
---

# Prove it works

Ends with **evidence against each acceptance criterion**, not with "looks right".

## Before anything

Read [../ws-shared/reference.md](../ws-shared/reference.md) and
[../ws-shared/tracks.md](../ws-shared/tracks.md), the cartridge, `tracks/current`, then the
track's `task.md`, `plan.md` and `journal.md`.

## 1. The repos' own checks

From each changed repo's `commands` in the cartridge. Prefer `verify` where the repo has one;
otherwise run them individually, **batched into one call**:

```bash
( cd "<repo>" && npm run typecheck && npm run lint && npm test && npm run build ) # plus `extra`
```

A `null` command means the repo genuinely does not have that check — **say so rather than
inventing one**. A repo with no test runner is verified by the other checks plus driving it.

Report each as pass/fail with the failing output, not a summary of it. **A failure stops here**:
fix it, then re-run. Do not carry a red check into review.

## 2. Evidence per acceptance criterion

This is the part that matters. For each criterion from `task.md`, in order:

| Criterion | How it was proved | Artefact |
|---|---|---|

Acceptable evidence, strongest first:
- An automated test that **fails without the change** — say that you checked it fails, not just
  that it passes.
- A request/response transcript, saved into `verify/`, with the ids used.
- A database row before and after, for anything that writes.
- A screenshot at both breakpoints, for anything visual.
- A log line proving the path ran, for anything asynchronous.

Scratch scripts go in the scratchpad and are deleted. Artefacts worth keeping go in
`<state_dir>/tracks/<id>/verify/` and are deleted at ship — the **summary** survives in the
harvest, not the raw logs.

## 3. Check the things the plan said were risky

Re-read the plan's edge cases and `<docs_home>/risks/`, and prove each one specifically:
concurrency under two simultaneous requests, money with an amount that does not divide cleanly,
permissions as the wrong user, the empty and error states, the migration's `down()`.

**Evidence from the case that was failing is not evidence the class is fixed.** Where the
change fixes a behaviour rather than adding one, prove it on a neighbouring case too, and on
one that should still behave differently.

**A criterion you cannot prove is a finding, not a pass.** Write what would be needed.

## 4. Record it

Append a `verified` journal entry: what passed, what could not be proved and why, and the next
step. Mirror and push if the project has a `docs_home`.

## Output

```markdown
# Verify: <id> <title>

## Checks
<repo: command — pass/fail>

## Acceptance
| Criterion | Proved by | Artefact | Verdict |

## Not proved
<criterion — what would be needed>

## Next step
```

## Rules

- Never report a check as passing without having run it in this session.
- Never claim a test is meaningful without confirming it fails when the code is wrong.
- Never mark a criterion proved by reading the code — that is review, not verification.
- Say explicitly which environment the evidence came from. Local evidence is not deploy evidence.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-review` — independent review, now that it demonstrably works
- `ws-debug` — a check fails for an unknown reason
- `ws-plan` — verification showed the approach is wrong
