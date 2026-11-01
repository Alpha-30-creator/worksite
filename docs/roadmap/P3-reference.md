# P3 — The docs a stranger needs

**Goal:** someone who has never seen this can write a cartridge, add a tracker and add a review
pack without reading the skills' source.

## [~] p3.1 — Write the cartridge schema · @Alpha-30-creator · 2026-11-01

- **Repos:** worksite
- **Depends on:** p2.2
- **Acceptance:**
  - [ ] `docs/integration/cartridge-schema.md` documents every key: type, whether it is
        required, the default, and **which skills read it**
  - [ ] the degrade behaviour is stated per key — what happens when it is missing
  - [ ] `machine:` overrides and `TODO:` values are explained
  - [ ] a reader can write a working cartridge from this page alone, verified by doing it
- **Plan approved 2026-11-01, not built.** Keeping its substance here so it survives the local
  track directory:
  - **Sections by concern, not one flat table** — a flat table cannot carry `repos:` (a list of
    maps) or `tracker.*` (four disjoint key sets conditional on `kind`).
  - Every key table carries six columns — key · type · required · default · **read by** ·
    **missing →** — so the two hardest acceptance criteria are structural rather than prose.
  - The "read by" mapping comes from an exhaustive grep ledger over `skills/`, in three passes
    (backticked literal, dotted form, then English concept for keys with no literal hit), with
    `examples/` and `templates/` excluded as data rather than readers.
  - **Degrade behaviour is not documented per key anywhere**, so each "missing →" cell is marked
    *stated* (cited) or *inferred*. That provenance convention doubles as a punch-list.
  - Document the schema **as it is, with gaps named** — do not specify the missing keys, which
    would quietly turn this into a `ws-refine` change to `ws-setup`.
- **Three findings already banked from the planning pass:**
  - **`merge_style` is a ghost key.** `ws-ship` reads "the project's merge style (`merge_style` in
    the cartridge)" and nothing in the pack defines it. Verified.
  - **Five keys have no literal reader:** `schema_version`, `git_flow`, `integration_branch`,
    `pr_into`, `commit_convention`. Four are pulled in wholesale by a template line;
    `schema_version` has no reader at all.
  - `ws-setup`'s interview collects a one-line description and a rule-skill prefix that have **no
    cartridge key to land in**, and `github-projects` says to "record them in the cartridge"
    without naming a key.
- **Notes:** the highest-value document in the repo and the one that does not exist in any form
  today. `ws-setup` generates cartridges by interview, so the format has never been written down.

## [~] p3.2 — Write the concepts page · @Alpha-30-creator · 2026-11-01

- **Repos:** worksite
- **Depends on:** p2.2
- **Acceptance:**
  - [ ] `docs/product/overview.md` — the problem, the loop, and the four design moves:
        generic skills plus a cartridge, tracker adapters, tracks plus an append-only journal,
        harvest-then-delete
  - [ ] it argues for the opinions rather than listing them — gates, fresh-eyes review, the
        lead that never builds — because those are the reason to adopt it
  - [ ] the track and journal state model is explained well enough to resume cold

## [ ] p3.3 — Write the extension guides

- **Repos:** worksite
- **Depends on:** p3.1
- **Acceptance:**
  - [ ] `docs/engineering/trackers.md` — the four questions an adapter answers, and a worked
        example of adding one
  - [ ] `docs/engineering/stacks.md` — how a review pack is selected and how to write one
  - [ ] `docs/engineering/layout.md` — what lives where in this repo
  - [ ] both guides state the rule that adding a tracker or stack never edits a skill
