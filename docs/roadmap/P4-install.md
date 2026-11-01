# P4 — README and an agent-readable install

**Goal:** a user says "set up worksite from this repo" and their agent does it, correctly, and
reports honestly what happened.

## [ ] p4.1 — Write the README

- **Repos:** worksite
- **Depends on:** p3.2
- **Acceptance:**
  - [ ] opens with the problem, not the feature list
  - [ ] the dependency table: Node 20+, git, agent-sync, one of Claude Code / Codex / Cursor,
        `gh` for PRs and the GitHub Projects tracker, `sops` + `age` only for `ws-env`
  - [ ] says plainly that the loop works with no secrets syncing at all
  - [ ] the thirteen skills in one table with what each ends with
  - [ ] makes the case for the opinions; a reader should want them, not tolerate them

## [ ] p4.2 — Write INSTALL.md for an agent to execute

- **Repos:** worksite
- **Depends on:** p4.1
- **Acceptance:**
  - [ ] addressed to the agent, in the same voice as agent-sync's `INSTALL.md`
  - [ ] checks prerequisites and **stops** rather than installing runtimes itself
  - [ ] installs or repairs agent-sync, then places the pack in the user's library and saves
  - [ ] safe to re-run: converges instead of duplicating
  - [ ] ends by pointing at `/ws-setup` for the user's first project
  - [ ] tells the agent to report what actually happened, including failures

## [ ] p4.3 — Repo furniture

- **Repos:** worksite
- **Depends on:** p4.1
- **Acceptance:**
  - [ ] `CONTRIBUTING.md`, including `git config core.hooksPath .githooks` as step one
  - [ ] `SECURITY.md` — what the pack does and does not protect, in the honest register the
        secrets docs already use
  - [ ] `CODE_OF_CONDUCT.md`
  - [ ] CI running `scripts/check.sh` on every PR
