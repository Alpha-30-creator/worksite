# Install worksite

**You are an AI agent reading this on behalf of a user.** Follow it top to bottom. Every step is a
command you can run and check. Report what actually happened at each step; if something fails, say
so rather than working around it.

Safe to re-run: step 4 compares before it writes, so running this again on a machine that already
has the pack repairs it instead of overwriting it. **Read step 4 before you run anything in it** —
the command it guards deletes a skill directory, and the guard is the only thing between a re-run
and the user's own edits.

What the user gets: thirteen `ws-*` workflow skills plus the `ws-shared` reference pack they all
read, deployed to every agent they have.

---

## 1. Check prerequisites

```
node --version
git --version
agent-sync --version
```

Node must be 20 or newer. **If Node or git is missing or too old, stop.** Tell the user what to
install — Node from https://nodejs.org, git from https://git-scm.com — and do not try to install
runtimes yourself.

**If `agent-sync` is missing, stop and install that first.** It is the thing that deploys skills to
agents, and it has its own agent-readable install at
https://github.com/Alpha-30-creator/agent-sync/blob/main/INSTALL.md. Follow that file, then come
back here. Do not reproduce its steps; it checks things this file does not.

The user also needs at least one agent installed — Claude Code, Codex or Cursor. `agent-sync` can
only deploy to agents that are actually on the machine, and it will tell you which it found.

## 2. Get the pack onto the machine

```
git clone https://github.com/Alpha-30-creator/worksite.git
cd worksite
```

If they already have a clone, use it, and `git pull --ff-only` first so you are installing the
current pack rather than an old checkout.

## 3. Find the library

```
agent-sync status
```

The library is where agent-sync keeps the canonical copy of every skill — `~/.agent-sync/store` by
default. **If `status` fails because there is no library, stop**: the user has agent-sync installed
but not set up, and `agent-sync setup` asks questions only they can answer. Point them at
agent-sync's `INSTALL.md` step 3 and come back.

## 4. Compare before you write

The next step uses `agent-sync add skill`, and **that command deletes the destination directory
before copying into it**. There is no prompt and no backup. On a first install that is harmless. On
a re-run it would destroy any change the user has made to any of these skills — so compare first,
every time, including the first time.

```bash
LIB="$HOME/.agent-sync/store/skills"
for d in skills/ws-*/; do
  id="$(basename "$d")"
  if [ ! -d "$LIB/$id" ]; then
    printf 'NEW      %s\n' "$id"
  elif diff -rq "$LIB/$id" "$d" >/dev/null 2>&1; then
    printf 'CURRENT  %s\n' "$id"
  else
    printf 'DIFFERS  %s\n' "$id"
  fi
done
```

Then, by what it printed:

- **`CURRENT`** — already identical. **Skip it.** Do not re-add it; there is nothing to change, and
  saying so is the honest report.
- **`NEW`** — safe to add in step 5.
- **`DIFFERS`** — **stop for that skill.** Show the user what would be lost:

  ```
  diff -ru "$LIB/<id>" "skills/<id>"
  ```

  Then tell them plainly: adding it will delete their version. Ask which they want — keep theirs
  and skip it, or replace it deliberately now that they have seen the diff. **Do not choose for
  them, and do not add it to get a clean run.** A skill they edited is a skill they meant to edit.

If every skill is `CURRENT`, the pack is already installed and current. Say that and go to step 7.

## 5. Add what is missing, then save once

For each skill the user agreed to install:

```
agent-sync add skill "skills/<id>"
```

The directory name is the id, so `skills/ws-start` becomes `skill/ws-start`. Then, once, after the
whole set:

```
agent-sync save
```

That validates the library, deploys to every agent it detected, commits and pushes. One call for
the set — not one per skill.

`ws-shared` is reference material the other skills read by path, not a step in the loop, and it
carries `disable-model-invocation: true` on purpose. Copy it as it is; do not "fix" that flag.

## 6. Confirm it arrived

```
agent-sync status
agent-sync doctor --json
```

In `status`, the fourteen `skill/ws-*` entries should read `synced`. In `doctor`, read the
**`healthy`** field, not `ok` — `ok` only says the command ran, and is `true` even with work
pending. Exit code 2 means it worked with warnings: repeat them to the user rather than swallowing
them. If an agent they use was not detected, say so.

## 7. Their first project

The pack does nothing until a project has a cartridge — the file that tells the skills where that
project's repos, tracker and rules are.

Tell the user to open the project they want to use this on and run **`/ws-setup`** (`$ws-setup` in
Codex). It interviews them and generates the cartridge, the state directory and the workspace
instruction files. Two worked examples are in `skills/ws-shared/examples/`.

After that, **`/ws-start`** begins the loop.

## 8. Report what actually happened

Tell the user, in plain terms: which skills were added, which were already current, which you
stopped on and why, which agents they reached, and anything `doctor` warned about. If you skipped a
skill because they edited it, say which one — that is the most important line in your report.

Do not report success for a step you did not run.

## If something goes wrong

- **`add skill` says a path has no `SKILL.md`** — you are pointing at the wrong directory. The path
  is `skills/<id>`, from the repo root.
- **`save` fails validation** — it names the file. Nothing was deployed; fix it and re-run `save`.
- **`save` cannot push** — the library is a git repository the user owns. The commit is local and
  safe; the push is theirs to sort out, and `agent-sync sync` will carry it later.
- **A skill deployed but the agent does not offer it** — agents read their skill directory at
  session start. Tell them to restart the agent.
- **Anything else** — report it verbatim. A wrong guess here costs the user their library.
