---
schema_version: 1
project: <id>                   # the agent-sync project id, lowercase-kebab
profile: standard               # lite | standard | full. Asked, never inferred from folder shape.
                                # lite = cartridge + AGENTS.md + tracks/, and no tracker
                                # standard = + a tracker, so work can be claimed
                                # full = + rule skills and rules/<area>.md
rule_prefix:                    # full only: 2-3 letters naming the rule skills, e.g. nw -> nw-backend.
                                # Required for `full`, because ws-fanout briefs builders to read
                                # <rule_prefix>-<area> and cannot look the value up anywhere else
state_dir: .<id>                # local, ephemeral, never committed
docs_home: <project>-docs/agent      # or <repo>/docs/agent for a single-repo project
artifacts: workspace-state      # workspace-state | in-repo
agents_file: copy               # copy | include | symlink  (copy unless you know why not)
worktrees: true                 # each track its own checkout; false only where the per-worktree dependency install is genuinely prohibitive
worktree_root:                  # optional. Default: the workspace root's SIBLING, <workspace>/../<project>-tracks.
                                # A relative value is relative to the workspace root. Resolved absolutely once per session

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
  merge_style: squash           # squash | merge | rebase — as the repo is actually set up.
                                # Written rather than left absent: ws-ship reads it and otherwise
                                # asks once per ship, forever
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

<!-- Writing the prose above so it survives the next few tasks:
     * Prefer a LINK TO A DECISION RECORD over a task id. "(p3.2)" says which task changed a
       paragraph, not why, and it stops resolving once the roadmap entry is archived. Keep a bare
       id only where no record exists — it is then a signal the reasoning was never written down.
     * Write what is true NOW. A path named before it exists never fails, because a bare path in a
       table cell is not a link and no link check sees it. If a path is aspirational, say so.
     * Keep "Open questions" to actual questions. It is the section that silently becomes a list
       of settled statements, each one still accurate, which is why `ws-ship` asks whether a row
       READS correctly rather than whether it is true.
     `ws-ship`'s DOCS step — section 4, before the merge, not the harvest — re-reads anything here
     naming a task id, a phase, a not-yet-existing path or a count, and its closing line reports
     whether it did. Fewer of those is less to re-read. -->
