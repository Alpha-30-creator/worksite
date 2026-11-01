# P4 — README and an agent-readable install

**This phase is complete (2026-11-02).** p4.1 wrote the README, p4.3 added the repo furniture and
CI, and p4.2 wrote `INSTALL.md`. All three shipped. What the phase does **not** establish is that
the install works for someone who is not the author — that is p7.1, and until it runs, this phase
is complete rather than proven.

**Goal:** a user says "set up worksite from this repo" and their agent does it, correctly, and
reports honestly what happened.

## [x] p4.1 — Write the README · 2026-11-02 · @Alpha-30-creator · https://github.com/Alpha-30-creator/worksite/pull/6

- **Repos:** worksite
- **Depends on:** p3.2
- **Acceptance:**
  - [x] opens with the problem, not the feature list
  - [x] the dependency table: Node 20+, git, agent-sync, one of Claude Code / Codex / Cursor,
        `gh` for PRs and the GitHub Projects tracker, `sops` + `age` only for `ws-env`
  - [x] says plainly that the loop works with no secrets syncing at all
  - [x] the thirteen skills in one table with what each ends with
  - [x] makes the case for the opinions; a reader should want them, not tolerate them

## [x] p4.2 — Write INSTALL.md for an agent to execute · 2026-11-02 · @Alpha-30-creator · https://github.com/Alpha-30-creator/worksite/pull/12

- **Repos:** worksite
- **Depends on:** p4.1
- **Absorbed 2026-11-02** by the owner after an independent audit: **p6.2**'s two real criteria
  (an update converges rather than duplicating; a locally edited skill survives or is flagged)
  and **p2.3**'s one undelivered criterion (a second example cartridge covering a hosted
  tracker). Both of those tasks are dropped and their bodies kept. p6.2's remaining criterion —
  the README declining pull requests — shipped with p4.1.
- **Acceptance:**
  - [x] addressed to the agent, in the same voice as agent-sync's `INSTALL.md`
  - [x] checks prerequisites and **stops** rather than installing runtimes itself
  - [x] installs or repairs agent-sync, then places the pack in the user's library and saves
  - [x] safe to re-run: converges instead of duplicating, and shows a diff **before** changing
        anything *(absorbed from p6.2, 2026-11-02)*
  - [x] a skill the user edited locally either survives or is flagged before it is lost — never
        silently overwritten *(absorbed from p6.2, 2026-11-02)*
  - [x] a **second** example cartridge covering a shape the first does not: a hosted tracker
        (`github-projects` or `trello`), `artifacts: in-repo`, and a non-empty `machine:` — the
        install is the first thing that needs one, since a stranger's project is likelier to be
        the shape neither existing example tests *(absorbed from p2.3, 2026-11-02 — its one
        undelivered criterion; p3.1's blind readers wrote two such cartridges from the schema
        page alone and those are a usable starting point)*
  - [x] ends by pointing at `/ws-setup` for the user's first project
  - [x] tells the agent to report what actually happened, including failures
  - [x] **the link from `README.md` is added by this task.** *2026-11-02 re-scoped by
        @Alpha-30-creator: p4.1 deliberately names these files in prose and never links them,
        because `check.sh` §3 fails on a missing target. Without this criterion the links are
        never added by anyone.*

## [x] p4.3 — Repo furniture · 2026-11-02 · @Alpha-30-creator · https://github.com/Alpha-30-creator/worksite/pull/8

- **Repos:** worksite
- **Depends on:** p4.1
- **Acceptance:**
  - [x] `CONTRIBUTING.md`, including `git config core.hooksPath .githooks` as step one
  - [x] `SECURITY.md` — what the pack does and does not protect, in the honest register the
        secrets docs already use
  - [x] `CODE_OF_CONDUCT.md`
  - [x] CI running `scripts/check.sh` on every PR
  - [x] **the link from `README.md` is added by this task.** *2026-11-02 re-scoped by
        @Alpha-30-creator: p4.1 deliberately names these files in prose and never links them,
        because `check.sh` §3 fails on a missing target. Without this criterion the links are
        never added by anyone.*
  - [x] *added during the batch:* `docs/engineering/layout.md` reflects the four new paths and
        that CI now runs the suite — its own rule is that it changes in the same PR as what it
        describes, and this change is what made it wrong
