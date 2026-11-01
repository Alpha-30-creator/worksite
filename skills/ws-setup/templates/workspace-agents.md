# <Project> workspace

This folder is **not** a git repo. It holds:

| Folder | Repository | What |
|---|---|---|

Use `git -C <repo>` and `gh -R <owner>/<repo>`.

## Start here

Run **`/ws-start`** (`$ws-start` in Codex). It syncs, shows what's open, and claims a task.

## Skills

Workflow skills are global `ws-*` skills; they read this project's cartridge at
`<docs_home>/reference.md`. Rule skills for this project load automatically before touching the
repo they cover.

| Skill | When |
|---|---|
| `ws-start` | Start of a session: sync, show the board, claim a task |
| `ws-plan` | Before writing code |
| `ws-verify` | Prove it works |
| `ws-review` | Independent review before shipping |
| `ws-ship` | Commit, PR, merge, harvest, clean up |
| `ws-wrap` | Stopping mid-task |
| `ws-debug` | Root-cause a failure |
| `ws-task` | Change the tracker |
| `ws-sync` | Make this machine current |
| `ws-env` | Credentials |

## Rules that override defaults

<from the cartridge's house_rules and git_flow>
