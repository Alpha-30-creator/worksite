# P7 — Proven by a stranger, then tagged

**Goal:** the install is known to work for someone who is not the author.

## [ ] p7.1 — Dry-run the install as a stranger

- **Repos:** worksite
- **Depends on:** p4.2, p5.1, p6.2
- **Acceptance:**
  - [ ] a fresh agent-sync library and a throwaway project, following `INSTALL.md` only, using
        nothing the author happens to know
  - [ ] every point where the agent had to guess, ask or improvise is recorded in
        `docs/records/` with a dated report
  - [ ] each one becomes a fix or a documented limitation — not a note to self
  - [ ] the loop is then run on one real task in that throwaway project, end to end

## [ ] p7.2 — Tag and announce

- **Repos:** worksite
- **Depends on:** p7.1
- **Acceptance:**
  - [ ] `v0.1.0` tagged with release notes
  - [ ] the README's claims all verified against the tagged tree
  - [ ] agent-sync's README links to worksite, and worksite's links back
