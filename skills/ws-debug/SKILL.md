---
name: ws-debug
description: Find the cause of a failure in any environment - establish what is actually broken and where, reproduce it at the smallest scale, read the evidence before theorising, confirm the cause rather than guessing at a fix, then record it and offer it as a review risk so it is caught next time. Ends with a confirmed cause, never with a fix that seems to work. Use when something fails for an unknown reason, when a check or deploy breaks, or when a bug needs its cause found before it can be planned or filed. Not for designing the fix once the cause is known, which is ws-plan.
---

# Find the cause

Ends with **a confirmed cause**, not a fix that seems to work.

## Before anything

Read [../ws-shared/reference.md](../ws-shared/reference.md), the cartridge, and
`<docs_home>/risks/` plus the stack packs for the repo that broke — a known trap is the most
likely cause, so check there before anywhere else. If there is a current track, read its
`task.md`, `plan.md` and journal.

## 1. Establish the facts, before any theory

Answer these in writing. Guessing here is what makes debugging take all day:

- **What is the observed behaviour**, exactly? The error text, the status code, the wrong value.
- **What was expected**, and who says so — a criterion, a contract, a test?
- **Which environment**, and which commit or deploy? `environments` in the cartridge; confirm
  which one you actually reached rather than which one you meant to.
- **When did it last work?** A commit, a deploy, a date. If it never worked, say that — it
  changes the search completely.
- **Is it deterministic?** Every time, or sometimes? Intermittent means concurrency, ordering,
  caching, or state, and that narrows things hard.

## 2. Reproduce it smaller

A reproduction you control beats reading code. Shrink it until it is one call:

```bash
# the smallest thing that still fails — save it under the track's verify/ if there is a track
```

Cannot reproduce it? Say so plainly and work from evidence instead (step 3). **Do not
"fix" something you cannot reproduce** — you will not know whether it worked.

## 3. Read the evidence before theorising

In this order, because this is the order that pays:

1. **The actual error**, in full, including the stack. Not a summary of it.
2. **Logs around the failure**, from the right environment.
3. **The diff** since it last worked: `git log --oneline <last-good>..HEAD`, then the files it
   touched.
4. **The data** — the actual row, the actual payload. Many "logic bugs" are a value nobody
   expected.
5. **Only then** read the code path, from the entry point inward.

## 4. Confirm the cause

State the cause as a claim, then **prove it**: change the one thing and watch the behaviour
change, or show the value that is wrong at the point it becomes wrong.

| Signal | What it usually means |
|---|---|
| works locally, fails deployed | environment variable, build output, a timeout, a cold start |
| intermittent | race, ordering, cache, or shared state |
| worked yesterday | the diff, a dependency, or data that changed |
| works for you, not for them | permissions, locale, timezone, or a feature flag |
| fails only under load | a limit: connections, memory, a function timeout |

**Two or more plausible causes is not a conclusion.** Narrow it to one, or say explicitly that
you have not, and which experiment would decide it.

## 5. Record it

- If there is a track, append a `debugged` journal entry: the cause, the evidence, and what was
  ruled out — the ruled-out list is what stops the next person re-walking it.
- **Offer the cause as a review risk.** If this class of bug is not in `<docs_home>/risks/` or a
  stack pack, propose one line, phrased as what to look for. This is how the project stops
  making the same mistake, and it is the main reason this step exists.
- A fix worth more than a line or two goes through `ws-plan`; a bug that is not this task's
  business goes to `ws-task`.

## Rules

- Never apply a fix before the cause is confirmed. A fix that works by accident hides the bug.
- Never change production to diagnose it, and never run a destructive command to "reset" state
  without asking — that includes any reseed or nuke script.
- Never change more than one thing at a time while narrowing.
- Never report "fixed" when you mean "no longer reproducing".
- Say which environment every piece of evidence came from.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-plan` — the fix is more than a line or two
- `ws-task` — it is a real bug, but not this task's business
- `ws-verify` — prove the fix
