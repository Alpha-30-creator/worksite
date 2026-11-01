# P6 — Publishing, and how users take updates

**This phase is closed (2026-11-02).** p6.1 shipped; p6.2 is dropped, two of its criteria
absorbed into p4.2 and one already delivered by the README. Nothing here is open.

**Goal:** every refinement reaches the public repo without anyone remembering to send it, and a
user who installed in January can take February's version safely.

Shaped by [ADR 0001](../decisions/0001-library-is-the-source-of-truth.md): the library is the
working copy, this repo is a published artifact.

## [x] p6.1 — Build publishing into ws-refine · 2026-11-01 · @Alpha-30-creator · https://github.com/Alpha-30-creator/worksite/pull/3

- **Repos:** worksite (pack)
- **Depends on:** p2.2
- **Acceptance:**
  - [~] **kept partial 2026-11-02: the outstanding half is a boundary, not work.** Whether an
        agent performs the publish unprompted is observable only in ordinary use, and it is
        recorded as the last of the eleven entries in
        [`records/known-limitations.md`](../records/known-limitations.md) — the pack's gates are
        desk-verified, not live-verified. Original text follows.
        `ws-refine` ends by copying the generic `ws-*` skills into this repo, running the leak
        guard, committing and pushing — as a step, not a suggestion
        **Mechanically proven, behaviourally outstanding.** The step is mandatory in wording and
        the command ran end to end at ship time — candidate scan, staged-tree scan, hook, commit
        `0e6481a`, real push — taking `check.sh` §4 from drift back to "ok — identical". That an
        agent performs it unprompted on the next refinement is the half still to be observed.
  - [x] the guard runs on the publish path, since publishing is the only way content gets here —
        three times: the candidate clone, the real staged tree, and the pre-commit hook
  - [x] publishing a skill whose content still holds a private name **fails loudly** and changes
        nothing in the repo
  - [x] `ws-refine`'s "edit the library, never a deployed copy" instruction gains its third
        clause, so an agent cannot reasonably guess wrong about which copy to edit
  - [x] the publish is a plain copy with no transformation — if it needs to rewrite anything, P2
        is not finished and the fix belongs there
- **Notes:** the friction budget for this is zero. If refining a skill becomes more steps than it
  is today, the design in ADR 0001 has failed and should be revisited rather than endured.

## [-] p6.2 — Document how a user takes an update — absorbed into p4.2; its pull-request criterion already shipped in the README

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. The convergence criterion and the locally-edited-skill
criterion are now p4.2's; the README already declines pull requests, shipped in p4.1.

