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
[root README](../../README.md) until P3 writes them up properly; facts about **how to work on
it** live here.

## The thing to understand first

**This repo is the pack it ships.** The fourteen `ws-*` skills that run the loop here are the
same fourteen this repo publishes. So two rules follow, and they are the only unusual thing
about working in this project:

1. A workflow step that feels wrong while working here is **a finding about the product**, not a
   nuisance. It goes through `ws-refine` or onto the roadmap, not into a workaround.
2. The skills an agent loads come from the author's agent-sync library, not from this repo's
   `skills/` directory. Until **p2.1** is decided those are two copies, and editing one does not
   change the other. Check which you are editing before you edit it.

## Workspace layout

The workspace root **is** the repo — a single-repo project. That matters twice:

- Always `git -C .` from the root; there is no sibling repo to confuse it with.
- The state dir is normally uncommittable because the workspace root is not a git repo. Here it
  is, so `.worksite/` is protected by `.gitignore` alone. **Do not remove that line.**

| Path | Role |
|---|---|
| `skills/` | the pack. Does not exist yet — see p2.2 |
| `examples/` | the author's own facts, rewritten as a stranger can read them — p2.3 |
| `docs/` | STATUS, decisions, roadmap, and this cartridge. Reference docs arrive in P3 |
| `scripts/check.sh` | the whole test suite: leak scan, frontmatter, links |
| `.githooks/pre-commit` | runs the leak scan on staged content |
| `.worksite/` | tracks, journal, scratch. Gitignored |

## Where things are

| Need | Read |
|---|---|
| What is open, and whose | [../STATUS.md](../STATUS.md), then [../roadmap/](../roadmap/) |
| How a task is claimed | the `roadmap-files` adapter in the pack's `ws-shared/trackers/` |
| The cartridge format | not written yet — task p3.1. The template in the pack's `ws-setup/templates/`, and this file, are the only examples |
| Project-specific review risks | [risks/common.md](risks/common.md) |
| What a shipped task left behind | `worklog/<track-id>.md` — created by `ws-ship` on the first harvest |
| An in-flight track's journal | `journal/<track-id>.md` — created when the first track is claimed |

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

- **p2.1 — who owns the skills?** Blocking the whole of P2. Three options, written out in
  [../roadmap/P2-depersonalise.md](../roadmap/P2-depersonalise.md). Needs an ADR.
- **No rule skill, deliberately.** `ws-setup` would normally generate one per code repo. This
  repo's "code" is the pack itself, and `ws-refine` already governs editing it — a rule skill
  would duplicate it. Revisit if `skills/` grows a build step.
- **`worktrees: true`**, matching the new pack default (p8.6). Free here — a repo of Markdown
  has no dependency install to repeat. **It does not make `ws-fanout` usable on this project**:
  most open work edits the agent-sync library, which is not in `repos:`, so a worktree of this
  repo isolates none of it. See p8.5.
- **No environments and nothing deploys.** `environments: {}` is accurate, not unfinished.
- **CI does not exist yet** (p4.3). Until it does, the hook is the only thing standing between a
  private name and a public commit, and a contributor without the hook has nothing.
