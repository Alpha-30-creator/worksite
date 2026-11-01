# Example: a `tasks-file` tracker

What `lite` projects default to. One `TASKS.md` in the repo, same markers as every other adapter,
no phases and no status file. A pushed commit is the lock, exactly as with `roadmap-files`.

```markdown
# Tasks

## [x] t-1 — Parse the uploaded CSV · 2026-03-04 · @you
- **Acceptance:** a malformed row is rejected with the row number, not swallowed

## [~] t-2 — Reject duplicate uploads @you · 2026-03-05
- **Depends on:** t-1
- **Acceptance:**
  - [ ] the same file uploaded twice is rejected on the second attempt
  - [ ] the check is on content, not filename
- Where it stopped (2026-03-05 @you): hashing works, the rejection path has no test yet

## [ ] t-3 — Show upload history
- **Depends on:** t-2
- **Acceptance:** the ten most recent uploads, newest first, with who uploaded each

## [?] t-4 — Retention policy
- **Blocked on:** a decision — how long uploads are kept

## [-] t-5 — Bulk delete
- Dropped 2026-03-02: no user asked for it, and it needs the retention decision first
```

Markers are the same everywhere: `[ ]` open, `[~]` claimed, `[r]` PR open, `[x]` done,
`[-]` dropped, `[?]` blocked. A task is **pickable** when it is `[ ]` and every id on its
`Depends on:` line is `[x]`.
