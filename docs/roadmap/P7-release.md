# P7 — Proven by a stranger, then tagged

**Goal:** the install is known to work for someone who is not the author.

## [~] p7.1 — Dry-run the install as a stranger · @Alpha-30-creator · 2026-11-02

- **Repos:** worksite
- **Depends on:** p4.2
- **Re-scoped 2026-11-02:** the `p5.1` dependency is removed because P5 is closed and both its
  tasks are dropped — the loop runs with no secrets syncing at all, so a stranger's dry run does
  not need an init mode. The `p6.2` dependency is now carried by p4.2, which absorbed it. The two
  cheapest cases of **p8.4** are absorbed here, because this task already stands up a throwaway
  project and running them costs almost nothing once it exists; p8.4 itself is dropped.
- **Acceptance:**
  - [ ] a fresh agent-sync library and a throwaway project, following `INSTALL.md` only, using
        nothing the author happens to know
  - [ ] every point where the agent had to guess, ask or improvise is recorded in
        `docs/records/` with a dated report
  - [ ] each one becomes a fix or a documented limitation — not a note to self
  - [ ] the loop is then run on one real task in that throwaway project, end to end
  - [ ] run with **no cartridge**: `ws-review` must ask its three questions and continue;
        `ws-env` and `ws-sync` must work from the device file alone *(absorbed from p8.4,
        2026-11-02)*
  - [ ] run against a tracker kind with **no adapter** — the four questions must get asked and a
        new adapter written, with no skill edited *(absorbed from p8.4, 2026-11-02)*

## [ ] p7.2 — Tag and announce

- **Repos:** worksite
- **Depends on:** p7.1
- **Cut 2026-11-02** to one criterion. Tagging and the reciprocal links are a release mechanic
  that needs no tracking; the claim-by-claim verification is the part that can fail silently, so
  it is the whole task.
- **Acceptance:**
  - [ ] the README's claims all verified against the tagged tree
