# Tracker: a single TASKS.md

The `lite` default, and right for anything small. Cartridge key: `tracker.path` (default
`TASKS.md` in the docs home or the repo root).

Format — flat, no phases, no dependencies:

```markdown
## Open
- [ ] t-14 Make the export include archived rows
- [ ] t-15 Fix the 500 on an empty filter

## In progress
- [~] t-13 Rework the settings screen · @you · 2026-10-20

## Done
- [x] t-12 Add the health endpoint · 2026-10-19 · #41
```

## List
Read the file. Everything under `## Open` is pickable; there are no dependencies to resolve.

## Claim
Move the line to `## In progress`, change `[ ]` to `[~]`, append the handle and date. If the
file is in a repo, commit and push — that makes it a lock, with the same
**rejected → pull --rebase → re-check → retry** rule as any pushed claim. If it is not in a
repo, say plainly that there is no lock and it is single-player.

## Mark
In review: leave it `[~]` and append the PR url. Done: move to `## Done`, `[x]`, date, PR.

## Note
Append `· stopped: <one line>` to the in-progress line. There is nowhere else to put it, and
that is fine for a project this size.

**Ids** are `t-<n>`, never reused. Next id = highest ever used plus one, counting Done.
