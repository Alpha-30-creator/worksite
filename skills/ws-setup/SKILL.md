---
name: ws-setup
description: Set up or upgrade one project's agentic workspace - interview for the repos, tracker, git flow, environments and house rules, then generate the state directory, the cartridge, the workspace instruction files, the per-area rule skills and the agent-sync wiring. On a project that already has some of this it detects what exists, shows a table of what it would add or change, and waits for a yes. Ends with a project an agent can work in, and never with something overwritten that you did not approve. Use when starting a new project, onboarding an existing one, or bringing an older one up to the current workflow. Not for making this machine current, which is ws-sync.
---

# Set up a workspace

Ends with a project an agent can work in, and **never** with something overwritten that you
did not approve.

## Before anything

1. Read [../ws-shared/reference.md](../ws-shared/reference.md).
2. Work out where you are and what already exists:

```bash
ROOT=$(pwd)
echo "root: $ROOT"
[ -f .agent-sync.yaml ] && echo "agent-sync marker: $(sed -n 's/^project: *//p' .agent-sync.yaml)" || echo "no agent-sync marker"
git rev-parse --is-inside-work-tree 2>/dev/null && echo "root IS a git repo" || echo "root is not a git repo (good for multi-repo)"
for d in */; do [ -d "$d/.git" ] && printf '  repo: %-28s %s\n' "${d%/}" "$(git -C "$d" remote get-url origin 2>/dev/null)"; done
ls -d .*/ 2>/dev/null | grep -vE '^\.(git|claude|codex|cursor|agents|vscode|idea)/$'
# find distinguishes "searched it all, found nothing" from "could not descend" by its own exit
# code; throwing that away turns an unsearchable tree into the mode "new", and new on a
# configured project is the damaging answer. Checked on BSD/macOS find; GNU find documents the
# same non-zero-on-error contract, but that was not run here.
hits=$(find . -maxdepth 3 -name 'reference.md' -path '*agent*' 2>/dev/null); rc=$?
if [ -n "$hits" ]; then printf 'cartridge candidate: %s\n' "$hits"
  [ "$rc" -eq 0 ] || echo "(and the search was incomplete — there may be more)"
elif [ "$rc" -ne 0 ]; then echo "UNSEARCHABLE: could not descend under $ROOT — the mode is UNKNOWN"
else echo "searched $ROOT to depth 3, and found no cartridge"
fi
ls AGENTS.md CLAUDE.md 2>/dev/null
```

3. Pick the mode from what you found — and say which you picked and why:

| Found | Mode |
|---|---|
| A cartridge (`<docs_home>/reference.md` with frontmatter) | **upgrade** |
| Repos, maybe an `AGENTS.md`, but no cartridge | **adopt** — interview, but seed every answer from what is there |
| An empty or near-empty folder | **new** |
| `UNSEARCHABLE: …` | **none — stop.** You have not established there is no cartridge, and **new** on a configured project is the damaging answer. Say which path you tried, ask, re-run |
| One repo, throwaway or experimental | **lite** (offer it; `profile: lite`) |

**Offer lite whenever it fits.** A one-off project should cost five questions, not thirty. Using
the system must never cost more than the work is worth.

## The interview

Ask in order. **Every question carries your recommendation**, so "yes, next" is a valid answer
all the way through. Where the folder already tells you the answer, state it and ask only for
confirmation — never ask what you can read.

### Lite profile — five questions

1. Project id and what it is, in a sentence.
2. The repo (or repos), and its GitHub owner.
3. Stack, and the commands for typecheck / lint / test / build. Read `package.json`,
   `pyproject.toml` or `requirements.txt` first and propose what you found.
4. Branch and PR flow, or "just commit to main".
5. AI attribution on or off.

Then generate and stop. No tracker, no journal, no rule skills, no risks file.

### Full profile

1. **Identity** — project id (matching `agent-sync`'s, if linked), one-line description, short
   prefix for the rule skills — two or three letters, e.g. `nw` for northwind.
2. **Repos** — for each: folder, GitHub owner, role (`backend` / `frontend` / `docs` / `infra` /
   `lab` / `legacy`), integration branch. Propose the list you found on disk.

   Then: **is there anywhere else this project's work edits, that is not one of these repos?** A
   library a tool owns, a shared fixture store, somewhere a generated artifact is published from.
   Recommend **none** — most projects have none, and a wrong entry is worse than an absent one
   (R2). Each one the answer names becomes a `shared_stores:` entry: an `id`, a `$HOME`-relative
   `path` (**never an absolute home path** — the cartridge is committed and read on every
   machine), the single global command that publishes the **whole** store as `publish:` or `null`
   if there is none, and a `note`. It is read by `ws-fanout`, which runs one track per declared
   store per batch because a worktree isolates the repos above and nothing outside them. Declaring
   nothing is a real answer with a real cost: that gate can then see no further than `repos:`.
3. **Docs home** — decided by the project's shape, not by who owns the repos:

   | Project shape | Docs home |
   |---|---|
   | one repo | `<repo>/docs/` |
   | several repos | a dedicated `<project>-docs` repo, cloned into the workspace |

   The docs repo may be in your own account even when the code repos are in a company
   organisation — that is the usual case, since the docs carry your way of working. **The
   cartridge is always `<docs>/agent/`.**

   No docs repo yet on a multi-repo project? Offer to create one (`gh repo create
   <project>-docs --private`), clone it into the workspace root, and `agent-sync link` stays
   pointed at the workspace.

   Generate the standard tree — `product/ engineering/ integration/ design/ decisions/
   roadmap/ runbooks/ records/ agent/` plus `README.md`, `00-START-HERE.md`, `STATUS.md` — and
   seed each with a one-line README saying what belongs there and whether it is living or
   immutable. See `../ws-shared/reference.md` for the full table.

   **Never put docs in the brain.** `~/brain` keeps business decisions, people, meetings and
   contracts; anything describing the system goes in the docs.

4. **Stack per repo**, and the commands. Read the manifests; propose; let them correct. A repo
   with no typecheck or no test runner is normal — record `null`, do not invent one.
5. **Tracker** — `github-projects`, `roadmap-files`, `trello`, `tasks-file`, or `none`. Recommend
   from the project's size: issues for a team, roadmap files for a solo build with phases, a
   `TASKS.md` for something small. An unfamiliar tracker is fine (R3): ask how to list, claim
   and close work, and offer to write a new adapter into `ws-shared/trackers/`.
6. **Git flow** — branch pattern, what PRs merge into, how a release happens, and
   **which branches deploy**. That last one is a safety fact, not trivia; get it exactly right.
7. **Environments** that exist *now*, and which do not exist yet — record the absent ones with a
   note rather than leaving them out, so a plan can say "this needs staging, which doesn't exist".
8. **House rules** — AI attribution, commit convention, hooks, and anything that overrides a
   default harness behaviour. Then: **do you own these rules, or follow them?**
   `owned_by: company` means `ws-refine` must never propose changing them.
9. **Rule skills** — one per repo that has code, plus one for migrations if there is a schema.
10. **Collaborators and handles**, if more than one person. Sets up `<state_dir>/me`.

Where an answer is genuinely unknown, write `TODO:` into the cartridge. **Never invent a fact
to fill a field** — a wrong fact in the cartridge is worse than a missing one, because every
skill reads it.

## Generate

Show the full file list first and wait for a yes. Then, from `templates/`:

| Write | From | Notes |
|---|---|---|
| `<docs_home>/reference.md` | `templates/cartridge.md` | the cartridge: frontmatter + prose |
| `<docs_home>/risks/common.md` | `templates/risks.md` | seeded empty; grows via `ws-review` |
| `<docs_home>/rules/<area>.md` | — | one per rule skill; start from what the repo already does |
| `<docs_home>/workspace/AGENTS.md` | `templates/workspace-agents.md` | **the source** of the workspace instructions |
| `<root>/AGENTS.md` | copy of the above | with the generated-by header |
| `<root>/CLAUDE.md` | `@AGENTS.md` | one line |
| `<state_dir>/`, `<state_dir>/tracks/` | — | and `me` if there are collaborators |
| `~/.agent-sync/store/skills/<prefix>-<area>/SKILL.md` | `templates/rule-skill.md` | thin: points at `rules/<area>.md` |

The generated copy always starts with:

```
<!-- Generated by ws-sync from <docs_home>/workspace/AGENTS.md. Edit the source, not this. -->
```

**Do not use a symlink** even on macOS. Windows git checks a symlink out as a text file
containing the path, silently, and the agent then has no rules. See ws-shared.

**If the workspace root is itself a git repo** (single-repo projects), add `<state_dir>/` to its
`.gitignore` — the root being a non-repo is what normally keeps state uncommittable, and that
protection is absent here. Say so.

Then wire it up:

```bash
agent-sync link <id>                      # registers this directory on this device
agent-sync include skill/<prefix>-<area> --project <id>
agent-sync save                           # validate, deploy, commit, push
agent-sync status                          # expect no drift
```

If the workspace root is not a git repo, `agent-sync link` will say the marker cannot travel.
**Record that**: the other device needs `agent-sync link <id>` run there by hand.

## Upgrade / adopt mode

Never write first. Read, compare, show, wait.

1. **Read** what exists: the cartridge if any, `AGENTS.md`, the state dir, the skills already
   in the library for this project, `agent-sync status`.
2. **Compare** against what the current design would generate.
3. **Show one table** and stop:

```markdown
| Thing | Now | Would become | Action |
|---|---|---|---|
| cartridge | absent | <docs_home>/reference.md | add |
| AGENTS.md | symlink into docs repo | generated copy + source | change (Windows-safe) |
| tracker | roadmap files | unchanged | leave |
| state dir | .<project>/active-task.md | .<project>/tracks/<id>/ | migrate |
| `<prefix>`-plan … `<prefix>`-ship | project workflow skills | generic `ws-*` | retire after the loop lands |
| risks | inline in a project review skill's prompt | `<docs_home>/risks/common.md` | extract |
```

4. **Apply only what was approved**, one line at a time where the user wants that.

**Expect disagreements.** An older project's facts will have drifted from reality — a branch
that was renamed, an environment that now exists, a command that changed. When the cartridge and
the repo disagree, **the repo wins and the cartridge is corrected**; when you cannot tell, ask.
Do not quietly copy a stale fact forward.

**Migrating a singleton active task**: `<state_dir>/active-task.md` becomes
`<state_dir>/tracks/<id>/task.md` and `tracks/current` gets its id. Keep the old file until the
user confirms, then delete.

**Retiring project workflow skills** is the last step and needs its own yes, after the generic
loop has been used on a real task in that project. Never in the same change as the upgrade.

## Rules

- Degrade, never fail. A cartridge with only `project` and `repos` must work. Ship a partial
  cartridge rather than blocking on an unanswered question (R1).
- Never invent a fact. `TODO:` is a valid value; a wrong fact is not.
- Never overwrite a file the user has edited without showing the diff and waiting.
- Never create a symlink for an instruction file.
- Never propose changing `house_rules` when `owned_by: company`.
- Never touch a repo's own `AGENTS.md` / `CLAUDE.md` or its practices docs — those are repo
  changes and ship through a task, not through setup.
- No AI attribution in anything generated, including the library commit.
- Adding a tracker or a stack means adding a file in `ws-shared/`, never editing a skill (R4).

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-sync` — confirm the machine is current and the generated copies match their sources
- `ws-env` — bring this project's credentials into the store
- `ws-start` — claim the first task
- `ws-refine` — change a generic skill or this project's cartridge
