# P3 — The docs a stranger needs

**Goal:** someone who has never seen this can write a cartridge, add a tracker and add a review
pack without reading the skills' source.

## [~] p3.1 — Write the cartridge schema @Alpha-30-creator · 2026-11-01

- **Repos:** worksite
- **Depends on:** p2.2
- **Acceptance:**
  - [ ] `docs/integration/cartridge-schema.md` documents every key: type, whether it is
        required, the default, and **which skills read it**
  - [ ] the degrade behaviour is stated per key — what happens when it is missing
  - [ ] `machine:` overrides and `TODO:` values are explained
  - [ ] a reader can write a working cartridge from this page alone, verified by doing it
- **Notes:** the highest-value document in the repo and the one that does not exist in any form
  today. `ws-setup` generates cartridges by interview, so the format has never been written down.

## [ ] p3.2 — Write the concepts page

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
