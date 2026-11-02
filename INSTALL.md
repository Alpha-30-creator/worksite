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

## Before you start: this install needs the user present, and it writes outside this repo

Read this now rather than discovering it at step 5. **Added 2026-11-02 after two agents ran this
document cold**; both got through step 4 and then could not finish.

**Three stops need an answer only the user can give**, so an install run with nobody to ask will
halt at one of them:

1. **Step 3, if `storeExists` is `false`.** agent-sync is installed but not set up, and setting it
   up asks questions about their machine. You cannot answer them.
2. **Step 4, for every skill that reads `DIFFERS`.** Whether their version or this one survives is
   theirs to decide, and you must not choose.
3. **Step 5's `save`**, which publishes to their machine and their remote — see below.

**And step 5 writes well outside this repository.** `agent-sync save` is one command that
validates, deploys into each agent's own skills directory (`~/.claude`, `~/.codex`, `~/.cursor` as
applicable), commits to the library, **and pushes it to the user's private remote.** `--no-push`
suppresses the push only — it still deploys into every agent directory, and there is no documented
way to do the library half without the deploy half.

So if you are running in a sandbox, cannot write outside a working directory, or have no user to
ask: **stop here and say so.** Steps 1 to 4 are all read-only and safe to run first — doing them
and reporting what you found is a useful outcome. Starting step 5 and stopping halfway is not.

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
agent-sync doctor --json
```

The library is where agent-sync keeps the canonical copy of every skill. **Read its path out of
that JSON's `store` field — do not assume `~/.agent-sync/store`.** It is the default, but
`agent-sync --store <path>` overrides it, and the next step compares against this path before
writing: if you guess it wrong, the comparison finds nothing, tells you there is nothing to lose,
and step 5 then deletes the user's real skills.

**Mind the level of `--store`.** It names the library's **parent**: agent-sync appends `store`
to it, so `--store /tmp/x` makes the library `/tmp/x/store`. Passing a path that already ends in
`store` creates a nested `store/store`. This is why you read the path out of the `store` field
instead of constructing it — that field is already resolved, whichever way the flag was given.

**If `storeExists` is `false`, stop**: the user has agent-sync installed but not set up, and
`agent-sync setup` asks questions only they can answer. Point them at agent-sync's `INSTALL.md`
step 3 and come back.

Do **not** improvise past this with `agent-sync init`, even though `doctor`'s own error text
suggests it. It scaffolds a library — on this machine it added three artifacts of its own — so an
agent that runs it has silently created a different library from the one the user will later expect,
and step 6's count will not match. An agent ran it here for exactly that reason; the fix is to say
so rather than to leave the gap.

## 4. Compare before you write

The next step uses `agent-sync add skill`, and **that command deletes the destination directory
before copying into it**. There is no prompt and no backup. On a first install that is harmless. On
a re-run it would destroy any change the user has made to any of these skills — so compare first,
every time, including the first time.

**Run this from the root of the worksite clone** — the `skills/ws-*/` glob is relative to it, and
from anywhere else the loop matches nothing and prints no rows at all, which looks like agreement.
If the user runs agent-sync with `--store`, add that flag to the `doctor` call here too, or `$LIB`
resolves to the default library and the comparison answers about the wrong one.

```bash
LIB="$(agent-sync doctor --json | node -e 'console.log(JSON.parse(require("fs").readFileSync(0,"utf8")).store)')/skills"
[ -d "$LIB" ] || { echo "the store path did not resolve to a directory: $LIB"; exit 1; }
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

This comparison runs one way — over what this pack ships. A `ws-*` skill in the user's library that
this pack does not have (one they wrote, or one retired from an older version) is not printed and
is not touched. Nothing deletes it; just do not report the library as fully accounted for.

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

In `status`, **the `skill/ws-*` entries for the skills the user agreed to install** should read
`synced`.

You may instead see **`adopted`**, and it does **not** mean what its position in a fresh install
suggests. agent-sync reports `adopted` only when the agent's own copy already exists **and hashes
equal to the library's** — so it means that agent had this skill already and it matched, not that
the skill is waiting to be deployed. On a genuinely fresh machine you will not see it; you will see
`missing` until `save` runs. If you do see it, say so: the user had a copy of this pack before you
arrived, which is worth telling them.

A trailing `N change(s) pending` line means `save` has not deployed yet. **That is not arrived**,
so do not report success on fourteen green ticks alone: check the word, not the tick. The full set is fourteen — thirteen workflow skills plus `ws-shared` — but if they chose
to keep their own version of one in step 4, expect one fewer and say which. Do not re-add a skill
to make the number come out.

In `doctor --json`, **do not look for an `ok: true` and stop there** — `ok` only says the command
ran. Read **`problems`** and **`notes`**: both empty is the healthy case, and anything in either is
something to repeat to the user rather than swallow. Exit code 2 means it worked with warnings. If
an agent they use was not detected, say so.

## 7. Their first project

The pack does nothing until a project has a cartridge — the file that tells the skills where that
project's repos, tracker and rules are.

Tell the user to open the project they want to use this on and run **`/ws-setup`** (`$ws-setup` in
Codex). It interviews them and generates the cartridge, the state directory and the workspace
instruction files. Worked cartridges are in `skills/ws-shared/examples/`, alongside a device file and a secrets manifest.

After that, **`/ws-start`** begins the loop.

**You can check this step landed**, which is worth doing because it is the first thing that proves
the install was useful rather than merely complete. In the project they chose:

```bash
ls -d .worksite 2>/dev/null && sed -n '1,12p' docs/agent/reference.md 2>/dev/null
```

A cartridge with frontmatter and a state directory means `ws-setup` ran. If the paths differ, read
the cartridge's own `state_dir` and `docs_home` — `ws-setup` may place them elsewhere, and a `lite`
profile deliberately generates less. **If step 5's `save` did not happen, step 7 cannot work at
all**: the skills are in the library and not in any agent, so `/ws-setup` will not resolve. Say that
rather than reporting the install complete.

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
