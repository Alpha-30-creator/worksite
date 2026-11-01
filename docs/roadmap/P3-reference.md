# P3 — The docs a stranger needs

**Goal:** someone who has never seen this can write a cartridge, add a tracker and add a review
pack without reading the skills' source.

## [x] p3.1 — Write the cartridge schema · 2026-11-01 · @Alpha-30-creator · https://github.com/Alpha-30-creator/worksite/pull/1

- **Repos:** worksite
- **Depends on:** p2.2
- **Acceptance:**
  - [x] `docs/integration/cartridge-schema.md` documents every key: type, whether it is
        required, the default, and **which skills read it**
  - [x] the degrade behaviour is stated per key — what happens when it is missing
  - [x] `machine:` overrides and `TODO:` values are explained
  - [~] **kept partial 2026-11-02: met to the limit of the pack, and the residue now has one
        home.** The pack-side residue this criterion names is **p8.33** (cartridge honesty) and,
        where it is a boundary rather than work, the limitations record at
        [`records/known-limitations.md`](../records/known-limitations.md) — the three-list board,
        and there being no way to say a command exists but must not be run. Original text follows.
        A reader can write a working cartridge from this page alone, verified by doing it —
        **met to the limit of what the pack can express.** Two blind readers wrote cartridges from
        the page alone: round one raised 14 gaps (9 page defects, all fixed), round two raised 5
        more (all page defects, all fixed) and confirmed the first round held. The residue is
        pack-side and filed separately: a Trello board's third list has no key, nothing says which
        repo holds a multi-repo `in-repo` plan, `owned_by`'s enum does not cover a small team, and
        there is no way to express "this command exists, do not run it". Writing keys for those
        would make the page wrong about the system, which this task's own plan forbids
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

## [x] p3.2 — Write the concepts page · 2026-11-01 · @Alpha-30-creator · https://github.com/Alpha-30-creator/worksite/pull/2

- **Repos:** worksite
- **Depends on:** p2.2
- **Acceptance:**
  - [x] `docs/product/overview.md` — the problem, the loop, and the four design moves:
        generic skills plus a cartridge, tracker adapters, tracks plus an append-only journal,
        harvest-then-delete
  - [x] it argues for the opinions rather than listing them — gates, fresh-eyes review, the
        lead that never builds — because those are the reason to adopt it
  - [x] the track and journal state model is explained well enough to resume cold

## [x] p3.3 — Write the extension guides · 2026-11-02 · @Alpha-30-creator · https://github.com/Alpha-30-creator/worksite/pull/5

- **Repos:** worksite
- **Depends on:** p3.1
- **Acceptance:**
  - [x] `docs/engineering/trackers.md` — the four questions an adapter answers, and a worked
        example of adding one
  - [x] `docs/engineering/stacks.md` — how a review pack is selected and how to write one
  - [x] `docs/engineering/layout.md` — what lives where in this repo
  - [x] both guides state the rule that adding a tracker or stack never edits a skill

## [ ] p3.4 — The docs tree has no index

- **Repos:** worksite
- **Depends on:** p3.2
- **Why:** `ws-shared/reference.md` specifies a docs root with `README.md` and `00-START-HERE.md`;
  `docs/` has neither. Three reference pages landed on 2026-11-01 (the cartridge schema, the
  concepts page, ADR 0002) and the only way to any of them is the root `README.md`, which does not
  link two of them. A docs tree whose own structure the pack documents and this repo does not follow
  is the weakest possible advertisement for the pack.
- **Acceptance:**
  - [ ] `docs/README.md` or `docs/00-START-HERE.md`, per the pack's own structure, linking every
        reference page that exists — and nothing that does not, since `check.sh` §3 fails on a
        missing target
  - [ ] the root `README.md`'s documentation list reaches `product/overview.md` and
        `integration/cartridge-schema.md`
  - [ ] it says which folders are living and which are immutable, matching `ws-shared/reference.md`
- **Notes:** raised independently by both p3.1's and p3.2's builders. Worth doing before P3 adds
  p3.3's three extension guides.
  **Write it after the documentation trim (added 2026-11-02):** an index built now would enshrine
  pages that are being deleted or halved, and every link it added to one of them would then fail
  `check.sh` §3.

## [x] p3.5 — Stale pointers and the skill count in the cartridge · 2026-11-02 · @Alpha-30-creator · https://github.com/Alpha-30-creator/worksite/pull/4

- **Repos:** worksite
- **Depends on:** p3.1
- **Why:** three small factual defects, all in files that were frozen while the batch ran:
  - `docs/agent/reference.md` says `The cartridge format | not written yet — task p3.1`. It is
    written; the row should point at `integration/cartridge-schema.md`.
  - The same file says "the fourteen `ws-*` skills" twice, while `README.md`:18 and :48 say
    thirteen. There are 14 directories and `ws-shared` carries `disable-model-invocation: true` —
    shipped task p8.1 decided that deliberately. `product/overview.md` already resolves it as
    "thirteen skills plus a shared reference they all read"; the cartridge is the loose file.
  - The cartridge's layout table has no row for `scripts/publish.sh`, which p6.1 added. The publish
    **target** must never appear there, only the script.
- **Acceptance:**
  - [x] the cartridge format row points at the schema page
  - [x] the repo says one thing about how many skills there are
  - [x] `scripts/publish.sh` is in the layout table, and no publish target path is
  - [x] `check.sh` green, which for the first item means the link resolves
- **Notes:** each is one line. Filed rather than patched mid-batch because all three files were
  frozen for the p3.1/p3.2/p6.1 batch.
