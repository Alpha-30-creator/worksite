---
schema_version: 1
project: worksite
profile: full
state_dir: .worksite
docs_home: docs/agent
artifacts: workspace-state
agents_file: copy
worktrees: true
worktree_root: ../worksite-tracks   # the default made explicit: this is a single-repo project, so
                                    # the root is necessarily outside the workspace, which is the repo

shared_stores:
  - id: agent-library
    path: ~/.agent-sync/store
    publish: agent-sync save
    note: "one global save — validates, deploys to every agent, then commits and pushes the whole store"

tracker:
  kind: roadmap-files
  path: docs/roadmap
  status_file: docs/STATUS.md
  markers: default
  claim: push

repos:
  - dir: .
    owner: Alpha-30-creator
    role: docs
    integration_branch: main
    deploy_branches: {}
    stack: []
    commands:
      typecheck: null
      lint: null
      test: null
      build: null
      verify: bash scripts/check.sh

git_flow:
  branch_pattern: "<type>/<id>-<slug>"
  pr_into: integration_branch
  release: "tag v<x.y.z> on main; no deploy, nothing is published to a registry"
  forbidden:
    - force-push to main
    - "--no-verify"
    - committing skills/ before scripts/check.sh is green

environments: {}

house_rules:
  ai_attribution: false
  owned_by: me
  commit_convention: conventional
  hooks: ".githooks/pre-commit — enable with: git config core.hooksPath .githooks"

machine: {}
---

# worksite reference

Read this before any work on worksite. Facts about *what worksite is* live in the
[root README](../../README.md) and in [../product/overview.md](../product/overview.md); facts
about **how to work on it** live here.

## The thing to understand first

**This repo is the pack it ships.** The thirteen `ws-*` workflow skills that run the loop here,
plus the `ws-shared` reference pack they all read, are the same ones this repo publishes.
`skills/` therefore holds fourteen directories while the pack is described as thirteen skills:
`ws-shared` is counted apart because it is reference material rather than a step in the loop,
and it carries `disable-model-invocation: true` deliberately (p8.1). Do not "correct" the count
in either direction. So two rules follow, and they are the only unusual thing about working in
this project:

1. A workflow step that feels wrong while working here is **a finding about the product**, not a
   nuisance — and it is **recorded whatever its size**. Where it is recorded is the second
   question, and `ws-task`'s *Where a finding belongs* answers it: `ws-refine` or a roadmap row
   when it is work someone will do, and otherwise one line in
   [records/known-limitations.md](../records/known-limitations.md) or the track's worklog entry,
   which closes it. Working around it silently is still wrong — say so in the line.

   **This rule had no threshold until 2026-11-02, and it cost the board nineteen rows in two
   days.** On a repo where the product *is* the workflow, an agent running the loop meets friction
   continuously, so an unqualified "it goes onto the roadmap" makes the agent's own experience the
   board's primary input. The fix is not to record less; it is that a record and a task are
   different things.
2. The skills an agent loads come from the author's agent-sync library, not from this repo's
   `skills/` directory. The library is the working copy and this repo is a published artifact
   ([ADR 0001](../decisions/0001-library-is-the-source-of-truth.md)), so those are two copies and
   editing the one here changes nothing an agent loads. Check which you are editing before you
   edit it.

## Workspace layout

The workspace root **is** the repo — a single-repo project. That matters twice:

- Always `git -C .` from the root; there is no sibling repo to confuse it with.
- The state dir is normally uncommittable because the workspace root is not a git repo. Here it
  is, so `.worksite/` is protected by `.gitignore` alone. **Do not remove that line** — and since
  p8.31, removing it is a **check** rather than a reminder: `scripts/check.sh` section 5 reads
  `state_dir` from this file and asserts `git check-ignore` matches it, and says so in its output
  rather than passing silently ([ADR 0004](../decisions/0004-a-check-must-state-what-it-read.md)).

| Path | Role |
|---|---|
| `skills/` | the pack as published: the thirteen workflow skills plus `ws-shared`, a plain copy out of the library ([ADR 0001](../decisions/0001-library-is-the-source-of-truth.md)). Markdown apart from three files, and `scripts/publish.sh` classifies the two kinds differently: `ws-refine/audit.sh` is allowed by **exact relative path** (its `PACK_EXEC` list, deliberately not a `*.sh` glob), while `ws-shared/examples/manifest.tsv` and `ws-shared/examples/device.yaml` are allowed as **data extensions** and listed on every run. The audit is the only script here, is mode 644, and is run as `bash audit.sh` rather than executed ([ADR 0005](../decisions/0005-the-graph-audit-is-a-script-in-the-library.md)) |
| `skills/ws-shared/examples/` | worked examples a stranger can read: two whole cartridges, `device.yaml`, `manifest.tsv`, a tracker example. **There is no top-level `examples/`**, and git history shows there never was — this row named one until p8.25 measured it |
| `docs/` | STATUS, roadmap, `decisions/`, worklog and this cartridge, plus the reference pages: the cartridge schema under `integration/`, the concepts page under `product/`, and **four** pages under `engineering/` — `layout.md` (what each check covers and misses), `stacks.md`, `sync-direction.md`, `trackers.md`. Then `records/` for what a validation run found, and `runbooks/` for procedures to follow under pressure, including purging a leak from history |
| `scripts/check.sh` | the whole test suite, and the only thing any gate runs: leak scan, frontmatter, links, library parity, the state-dir ignore assertion, the object store, and the README's own claims (section 7 calls `scripts/check-readme-claims.sh`, p7.3) |
| `scripts/publish.sh` | copies the `ws-*` skills out of the agent-sync library into the repo it sits in, behind the guard — the only way skills reach this repo ([ADR 0002](../decisions/0002-publishing-is-a-guarded-copy-from-the-library.md)). Which workspaces get published into is resolved by `ws-refine` from configuration that is never published, because a workspace path is itself a private name |
| `scripts/leak-patterns.txt` | the patterns section 1 scans for, **and the `!` allowlist entries it strips before matching** — this file alone defines the scan's coverage. A private name that is not in here is invisible to the guard |
| `scripts/object-store-baseline.txt` | the unreachable objects known to carry a pattern, with the measurement and the decision not to prune. Section 6 fails on any undeclared hit |
| `.githooks/pre-commit` | runs the leak scan on staged content |
| `.worksite/` | tracks, journal, scratch. Gitignored |

## Where things are

| Need | Read |
|---|---|
| What is open, and whose | [../STATUS.md](../STATUS.md), then [../roadmap/](../roadmap/) |
| How a task is claimed | the `roadmap-files` adapter in the pack's `ws-shared/trackers/` |
| The cartridge format | [../integration/cartridge-schema.md](../integration/cartridge-schema.md). The template in the pack's `ws-setup/templates/`, and this file, are worked examples of it |
| Project-specific review risks | [risks/common.md](risks/common.md) |
| **What each check actually covers, and what it misses** | [../engineering/layout.md](../engineering/layout.md) — the only page with the per-section blind spots, and it was unreachable from here until 2026-11-02 |
| **Why the system is shaped as it is** | [../decisions/](../decisions/) — six ADRs. The ones that bind daily work: [0001](../decisions/0001-library-is-the-source-of-truth.md) the library is the source of truth, [0002](../decisions/0002-publishing-is-a-guarded-copy-from-the-library.md) publishing is a guarded copy, [0006](../decisions/0006-retirement-refuses-what-removal-would-lose.md) what retirement refuses |
| Limitations that are recorded rather than tracked | [../records/known-limitations.md](../records/known-limitations.md) |
| What a shipped task left behind | [worklog/](worklog/) — one file per track, written by `ws-ship` at harvest |
| An in-flight track's journal | `.worksite/tracks/<id>/journal.md` — **local only** here, not mirrored. The entry header carries a derived device **alias** since p8.31, so the mirror is no longer the leak it was; `.gitignore` keeps it local anyway, because a journal records what was done on which machine and this repo is public. The reason is in the ignore file, not in memory |

## Rules that override defaults

- **Public repo, private source.** Everything here is built by copying out of a personal setup.
  `scripts/check.sh` section 1 is the guard, and it is not optional: a private name committed to
  a public repo cannot be taken back. Enable the hook before your first commit.
- **Nothing dirty enters history.** Skills are stripped in the working tree *before* the commit
  that adds them. Never "commit now, clean up after" — the history is public.
- **`verify` is `bash scripts/check.sh`.** There is no typecheck, lint, test or build here, and
  those are `null` on purpose. A repo of Markdown does not get an invented test runner.
- **No AI attribution** in any commit or PR. No `Co-Authored-By`, no "Generated with".
- `LICENSE` and the public npm scope `@abdur-codes/...` are allowed to contain the author's
  name. Nothing else is.

## Open questions

- **No rule skill, deliberately.** `ws-setup` would normally generate one per code repo. This
  repo's "code" is the pack itself, and `ws-refine` already governs editing it — a rule skill
  would duplicate it. Revisit if `skills/` grows a build step.

## Settled, and worth knowing

The three below sat under *Open questions* until p8.25 — every sentence in them accurate, under a
heading that had stopped describing its contents some tasks earlier. They are answers now, and
they are kept because the reasoning is load-bearing.

- **`worktrees: true`**, matching the new pack default (p8.6). Free here — a repo of Markdown
  has no dependency install to repeat, and fanout batches have run here on worktrees. What a
  worktree cannot isolate is work in the agent-sync library, which is not in `repos:`, so the
  library is **declared** in `shared_stores:` above rather than remembered as a rule
  ([ADR 0003](../decisions/0003-shared-external-stores-are-declared-in-the-cartridge.md)).
  `ws-fanout`'s gate reads that declaration and runs **one track per declared store per batch** —
  which gives that track exclusive *write* access to the store and nothing more. **`agent-sync
  save` belongs to no track at all: it is the lead's**, forbidden by name in **every** brief
  including the owner's, because it acts on the whole store rather than one track's changes. Its
  deploying half (`agent-sync apply`) is the lead's too, though that one is local and reversible
  and may run as often as verification needs. The rule, and why the graph audit follows the
  deploy, is stated once in `ws-refine`'s *Who may run what* —
  [ADR 0003](../decisions/0003-shared-external-stores-are-declared-in-the-cartridge.md), whose
  item 5 was amended to say it.
- **No environments and nothing deploys.** `environments: {}` is accurate, not unfinished.
- **CI runs `scripts/check.sh`** on every pull request and on pushes to `main` (p4.3), so the
  pre-commit hook is no longer the only guard — a contributor who never ran
  `git config core.hooksPath .githooks` is now caught at the PR. The honest half is unchanged:
  both run the same `scripts/leak-patterns.txt`, so a private name nobody has added to that file
  passes every one of them. The pattern list is the limit of what either guard can catch. There
  are **five** automated run sites in all, enumerated in [SECURITY.md](../../SECURITY.md); the
  count said four until p8.31 corrected it.
