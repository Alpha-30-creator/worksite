---
schema_version: 1
project: <id>                   # the agent-sync project id, lowercase-kebab
profile: full                   # full | lite
state_dir: .<id>                # local, ephemeral, never committed
docs_home: <project>-docs/agent      # or <repo>/docs/agent for a single-repo project
artifacts: workspace-state      # workspace-state | in-repo
agents_file: copy               # copy | include | symlink  (copy unless you know why not)
worktrees: true                 # each track its own checkout; false only where the per-worktree dependency install is genuinely prohibitive

shared_stores: []               # places the work edits that are NOT repos above; [] = none, which is
                                # the usual answer. Each: {id, path ($HOME-relative), publish, note}.
                                # ws-fanout runs one track per declared store per batch

tracker:
  kind: <github-projects | roadmap-files | trello | tasks-file | none>
  # kind-specific keys — the adapter in ws-shared/trackers/ says what it needs

repos:
  - dir: <folder>
    owner: <github owner>
    role: <backend | frontend | docs | infra | lab | legacy>
    integration_branch: <branch>
    deploy_branches: {}         # branch: environment. empty = nothing deploys
    stack: []                   # tags select the review packs
    commands: {}                # typecheck/lint/test/build/extra/verify — null where none exists

git_flow:
  branch_pattern: "<pattern>"
  pr_into: integration_branch
  release: "<how a release happens>"
  forbidden: []

environments: {}                # omit any that don't exist yet

house_rules:
  ai_attribution: false
  owned_by: me                  # me | company (company = rules followed, not authored)

machine: {}                     # per-device overrides, keyed by agent-sync device id
---

# <Project> reference

Read this before any work on <project>. Facts about the *product* live in the docs, not here;
facts about how to work on it live here.

## Workspace layout

The workspace root is **not** a git repo. It holds:

| Path | GitHub | Role |
|---|---|---|

Always `git -C "<repo>"`, with the quotes: a workspace path may contain a space. Never assume
the cwd is a git root.

## Where things are

| Need | Read |
|---|---|

## Rules that override defaults

## Open questions
