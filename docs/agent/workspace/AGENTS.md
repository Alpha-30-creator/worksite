# worksite workspace

This folder is the **worksite** repo, and worksite is the agent workflow pack it ships. The
loop you are about to use is the product.

Single repo: use `git -C .` and `gh -R Alpha-30-creator/worksite`.

## How to work with me

- **Explain in plain English, and keep the technical terms.** Say the real name of a thing, then
  what it is. Assume I have not read the code you just read.
- **Say the substance in chat.** Writing it into a file or a doc is the archive, not the answer:
  "I've written it up in X" is not a reply, because I will not always open the file. On this
  project that bites hardest — every skill here ends by writing a plan, a journal entry, a worklog
  entry or a record.
- **Keep it scannable.** Lead with what changed or what you found, detail underneath. I often
  dictate by voice and sometimes work late and tired.
- **Be critical, including about work you just did.** A review that finds nothing is not a good
  review, and the thing you built an hour ago is not exempt.
- **Say what you could not check.** "Done" means verified. Anything assumed, skipped or unproved
  gets said out loud, in the same breath as the result.
- **Ask before anything irreversible**, and show what you are about to do first.
- **Never use em dashes** in anything I will send from my accounts. A colon, comma or full stop
  instead.
- **Avoid new paid services**, and prefer a free tier. Say the cost before anything that spends.

## Start here

Run **`/ws-start`** (`$ws-start` in Codex). It syncs, shows what is open in `docs/roadmap/`, and
claims a task. Read the cartridge at `docs/agent/reference.md` before anything else — it has the
two rules that make this repo unusual.

## Before your first commit

```bash
git config core.hooksPath .githooks
```

This repo is public and is assembled by copying out of a private setup. The hook refuses any
commit carrying a private project name. Without it you have no guard.

## Skills

Workflow skills are the global `ws-*` skills; they read this project's cartridge at
`docs/agent/reference.md`.

| Skill | When |
|---|---|
| `ws-start` | Start of a session: sync, show the board, claim a task |
| `ws-plan` | Before writing anything |
| `ws-verify` | Prove it works — here that is `bash scripts/check.sh` plus evidence per criterion |
| `ws-review` | Independent review before shipping |
| `ws-ship` | Commit, PR, merge, harvest, clean up |
| `ws-wrap` | Stopping mid-task |
| `ws-debug` | Root-cause a failure |
| `ws-task` | Change the roadmap |
| `ws-refine` | Change the pack itself — which here is the product |
| `ws-sync` | Make this machine current |
| `ws-env` | Credentials. Not used by this project |

## Rules that override defaults

- **Nothing dirty enters history.** Strip private names in the working tree before the commit
  that adds the file, never after. The history is public and permanent.
- **`verify` is `bash scripts/check.sh`.** No typecheck, lint, test or build exists here, by
  design. Do not invent one.
- **Conventional commits**, branch `<type>/<id>-<slug>`, PRs into `main`.
- **No AI attribution** in commits or PRs.
- Never force-push `main`. Never `--no-verify`.
