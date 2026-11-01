---
schema_version: 1
project: worksite
profile: full
state_dir: .worksite
docs_home: docs/agent
artifacts: workspace-state
agents_file: copy
worktrees: true

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
   nuisance. It goes through `ws-refine` or onto the roadmap, not into a workaround.
2. The skills an agent loads come from the author's agent-sync library, not from this repo's
   `skills/` directory. The library is the working copy and this repo is a published artifact
   ([ADR 0001](../decisions/0001-library-is-the-source-of-truth.md)), so those are two copies and
   editing the one here changes nothing an agent loads. Check which you are editing before you
   edit it.

## Workspace layout

The workspace root **is** the repo — a single-repo project. That matters twice:

- Always `git -C .` from the root; there is no sibling repo to confuse it with.
- The state dir is normally uncommittable because the workspace root is not a git repo. Here it
  is, so `.worksite/` is protected by `.gitignore` alone. **Do not remove that line.**

| Path | Role |
|---|---|
| `skills/` | the pack as published: the thirteen workflow skills plus `ws-shared`, a plain copy out of the library ([ADR 0001](../decisions/0001-library-is-the-source-of-truth.md)) |
| `examples/` | the author's own facts, rewritten as a stranger can read them. Does not exist yet — p2.3 |
| `docs/` | STATUS, roadmap, decisions, worklog and this cartridge, plus the reference pages — the cartridge schema under `integration/`, the concepts page under `product/`, sync direction under `engineering/` — and `records/` for what a validation run found, `runbooks/` for procedures to follow under pressure, including purging a leak from history |
| `scripts/check.sh` | the whole test suite: leak scan, frontmatter, links, library parity |
| `scripts/publish.sh` | copies the `ws-*` skills out of the agent-sync library into the repo it sits in, behind the guard — the only way skills reach this repo ([ADR 0002](../decisions/0002-publishing-is-a-guarded-copy-from-the-library.md)). Which workspaces get published into is resolved by `ws-refine` from configuration that is never published, because a workspace path is itself a private name |
| `scripts/leak-patterns.txt` | the patterns section 1 scans for. A private name that is not in here is invisible to the guard |
| `.githooks/pre-commit` | runs the leak scan on staged content |
| `.worksite/` | tracks, journal, scratch. Gitignored |

## Where things are

| Need | Read |
|---|---|
| What is open, and whose | [../STATUS.md](../STATUS.md), then [../roadmap/](../roadmap/) |
| How a task is claimed | the `roadmap-files` adapter in the pack's `ws-shared/trackers/` |
| The cartridge format | [../integration/cartridge-schema.md](../integration/cartridge-schema.md). The template in the pack's `ws-setup/templates/`, and this file, are worked examples of it |
| Project-specific review risks | [risks/common.md](risks/common.md) |
| What a shipped task left behind | [worklog/](worklog/) — one file per track, written by `ws-ship` at harvest |
| An in-flight track's journal | `.worksite/tracks/<id>/journal.md` — **local only** here, not mirrored; see p8.8 |

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
- **`worktrees: true`**, matching the new pack default (p8.6). Free here — a repo of Markdown
  has no dependency install to repeat, and fanout batches have run here on worktrees. What a
  worktree cannot isolate is work in the agent-sync library, which is not in `repos:`: saving the
  library is a global deploy-and-push, so two library tracks at once overwrite each other. The
  rule while that is true is **at most one library track per batch**. See p8.5.
- **No environments and nothing deploys.** `environments: {}` is accurate, not unfinished.
- **CI does not exist yet** (p4.3). Until it does, the hook is the only thing standing between a
  private name and a public commit, and a contributor without the hook has nothing.
