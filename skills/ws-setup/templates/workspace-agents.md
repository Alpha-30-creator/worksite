# <Project> workspace

This folder is **not** a git repo. It holds:

| Folder | Repository | What |
|---|---|---|

Use `git -C "<repo>"` — quoted, because a workspace path may contain a space — and
`gh -R <owner>/<repo>`, which is a GitHub slug rather than a path and takes no quotes.

## How to work with me

<Written for the person, not for the project — the one section in this file that is about how you
are talked to rather than about what the code is. `ws-setup` writes these six defaults and shows
them; edit, cut or add to them freely, and `ws-sync` keeps the deployed copy in step.>

- **Explain in plain English, and keep the technical terms.** Say the real name of a thing, then
  what it is. Assume I have not read the code you just read.
- **Say the substance in chat.** Writing it into a file or a doc is the archive, not the answer:
  "I've written it up in X" is not a reply, because I will not always open the file.
- **Keep it scannable.** Lead with what changed or what you found. Detail underneath.
- **Be critical, including about work you just did.** A review that finds nothing is not a good
  review, and the thing you built an hour ago is not exempt.
- **Say what you could not check.** "Done" means verified. Anything assumed, skipped or unproved
  gets said out loud, in the same breath as the result.
- **Ask before anything irreversible**, and show what you are about to do first.

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

## Services, and how you reach them

<Generated from the cartridge's `services:`. Omit this whole section where that list is empty.
One row per service: how access works, what proves it, and what must never be run from here.>

| Service | How you reach it | What you did once | Proves it works | Never from a local machine |
|---|---|---|---|---|

<The third column is `human_step:` — the thing a human did, or still has to do, once per machine:
a `login`, a token pasted, nothing. It is in the table because a session that finds a service
unreachable needs to know whose step is missing before it starts debugging.

Where a service is `runtime-var`, name the file `env_file:` points at — the credential is already
there and an agent that is not told which file cannot find it, which is the state that kind exists
to replace.

Where a service is `token`, say which file holds it and how to load it:
`set -a; source "<state_dir>/env/agents.env"; set +a`. Where a service is `none`, say in one line
that there is no programmatic access and the agent asks instead of looking for one.>

## Rules that override defaults

<from the cartridge's house_rules and git_flow>
