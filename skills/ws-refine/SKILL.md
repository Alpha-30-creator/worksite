---
name: ws-refine
description: Change the workflow system itself - a generic ws-* skill, a shared review pack, a tracker adapter or a project's cartridge - keeping the What next? graph, the shared reference and the generated workspace instructions consistent, then validate, deploy everywhere and audit. Ends with the system changed and audited, and it always proposes before applying. Use when a workflow step felt wrong or was missing, when a fact in a skill or cartridge is out of date, when a repeatable workflow should become a skill or a pack, or when a review found a risk worth writing down for every project. Not for changing one project's tasks, which is ws-task.
---

# Change the system

The system edits itself through this skill. Nothing else should edit it.

## Before anything

1. Read [../ws-shared/reference.md](../ws-shared/reference.md). Read
   [../ws-shared/tracks.md](../ws-shared/tracks.md) if the change touches the loop.
2. **Edit the library, never a deployed copy.** The library is
   `~/.agent-sync/store/skills/`; everything under `.claude/skills/`, `.codex/skills/` and
   `.cursor/skills/` is written by `agent-sync save` and overwritten on every save. Reading a
   deployed copy to see what an agent currently loads is fine. The public `worksite` repo is a
   **published artifact**, not a place to edit: it receives a plain copy of the generic skills
   after they are saved here. Never edit a skill there, and never fix something there — fix it
   in the library and let the publish carry it. The copy is carried by the **Publish** step at
   the end of this skill, so "let the publish carry it" means that step and nothing manual.
3. **One blast radius to respect:** a generic `ws-*` skill is shared by every project. A bad
   edit breaks all of them at once, which is the cost of the generic design. So: propose, wait,
   then audit.

## What is being changed?

| Intent | Where it goes |
|---|---|
| A workflow step was wrong or missing | the `ws-*` skill |
| A risk class worth catching everywhere, on a stack several projects use | `ws-shared/stacks/<name>.md` |
| An objective security or quality rule | `ws-shared/stacks/security-baseline.md` or `review/tier1-universal.md` |
| A risk specific to one project | that project's `<docs_home>/risks/` — **a docs commit, not a library change** |
| A fact about repos, branches, commands, environments | that project's cartridge |
| A new tracker, or a tracker detail | `ws-shared/trackers/<kind>.md` — **a new file, never a skill edit** |
| A new stack | `ws-shared/stacks/<name>.md` — a new file, plus a row in the tag table |

**Adding a tracker or a stack never edits a skill** (R4). If you find yourself about to branch
on a tracker kind inside a skill, the design is being broken — add an adapter instead.

## Rules for the change itself

- Frontmatter: `name` matching the directory, and a `description` in the third person saying
  **what + when** under 1024 characters. **Workflow skills are model-invocable** — they carry no
  `disable-model-invocation`, so the loop runs when the work calls for it rather than when
  someone remembers the command. That makes the description load-bearing: it must say what the
  skill **ends with**, or it will fire in place of a sibling that ends with something else. A
  **rule** skill likewise omits the flag and ends its description with "Load it automatically …
  before …". **A reference pack keeps the flag** — `ws-shared` is read by path, not invoked, so
  making it invocable only adds a competitor to the trigger space with nothing behind it.
- **A skill with an expensive or outward-facing effect narrows its own trigger** and restates its
  gates as refusals. `ws-ship` only on explicit ship intent, `ws-fanout` only on explicit
  parallel intent, `ws-env` read-only unless asked for by name. Auto-invocation removed the typed
  command that used to serve as the confirmation; the skill has to supply it instead.
- First section **Before anything**, reading `../ws-shared/reference.md`. Last section
  **What next?**, starting "Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in
  Codex."
- **Generic means generic, permanently.** A generic `ws-*` skill, a shared review pack and a
  tracker adapter name no project, repo, person, device or path belonging to anyone real — not as
  an example, not as a "serves X" note, not as a pointer into a private doc. This is not
  tidiness. The library is published to a public repo as a **plain copy**, so a private name
  introduced here breaks publishing rather than merely reading badly. Project-specific knowledge
  goes to that project's `<docs_home>/risks/` and stays there; where a generic skill needs a
  concrete example, use the pack's invented example projects, never a real one.
- Facts several skills need go in `ws-shared/reference.md`, not repeated per skill. Facts about
  one project go in its cartridge. Facts about a product go in that project's docs.
- **Degrade, never fail** (R1): a new field or file must not break a project that lacks it.
  Unknown keys are ignored; a missing one means less capability, never an error.
- **New behaviour arrives as a flag defaulting to today's behaviour** (R5).
- Every command or fact you add must be checked — run it, or read the code. **Mark anything you
  could not check**, rather than implying you did.
- Never propose changing a project's `house_rules` when `owned_by: company`.
- No AI attribution anywhere, including the library commit message.
- Do not rename or delete a skill without an explicit yes.

## Propose — always, before touching anything

A table of the changes and why, the files touched, and **the graph table**, which is included
even when nothing else changes:

```markdown
## Graph and shared files affected

| File | Change? | Proposed edit |
|---|---|---|
| `ws-shared/reference.md` | yes / no | … |
| `ws-shared/tracks.md` | yes / no | … |
| each `ws-*` What next? that should name this | yes / no | … |
| the generated workspace `AGENTS.md` of affected projects | yes / no | … |
```

**Wait for a yes.** Then apply only what was approved.

## Deploy

```bash
agent-sync save        # validate, deploy to every agent, commit and push the library
agent-sync status      # expect no drift
```

## Audit afterwards — always

Run this. It catches the two mistakes this skill actually makes: a `What next?` naming a skill
that does not exist, and a sibling path that does not resolve.

```bash
cd ~/.agent-sync/store/skills
# frontmatter: name matches directory, description present and under the limit
for d in ws-*/; do d=${d%/}; f="$d/SKILL.md"
  nm=$(sed -n 's/^name: *//p' "$f" | head -1)
  len=$(sed -n 's/^description: *//p' "$f" | head -1 | wc -c | tr -d ' ')
  [ "$nm" = "$d" ] || echo "NAME MISMATCH: $d -> $nm"
  [ "$len" -gt 1 ] && [ "$len" -lt 1024 ] || echo "DESCRIPTION PROBLEM: $d ($len)"
done
# every skill named in a What next? exists
grep -hoE '`ws-[a-z]+`' ws-*/SKILL.md | tr -d '`' | sort -u | while read -r s; do
  [ -d "$s" ] || echo "MISSING SKILL: $s is referenced but does not exist"
done
# every sibling path resolves
grep -rhoE '\]\((\.\./)?[a-z0-9./-]+\.md\)' ws-*/SKILL.md | tr -d '](){}' | sort -u | while read -r rel; do
  found=0
  for base in ws-*/; do [ -f "${base}${rel}" ] && { found=1; break; }
    t=$(python3 -c "import os,sys;print(os.path.normpath(os.path.join(sys.argv[1],sys.argv[2])))" "${base%/}" "$rel")
    [ -f "$t" ] && { found=1; break; }
  done
  [ $found -eq 1 ] || echo "BROKEN LINK: $rel"
done
```

Report the result. A broken link is silent at runtime — the agent reads nothing and carries on
as if the rulebook said nothing — so an unaudited change is not a finished change.

Then summarise in a few bullets: what changed, which shared files moved, and how to invoke
anything new. **Do not run the changed skill unless asked.**

## Publish — a step, not a suggestion

Run this after the deploy and the audit, every time a generic `ws-*` skill changed. Some setups
publish the generic skills as a public artifact; that artifact is a **published copy** and the
publish below is the only way content reaches it. Doing it by hand is how the two drift.

Targets are **configured on the machine, never named in a skill**: a published artifact's path
belongs to one person's setup, and a path written here would be copied into every published
artifact along with it. One absolute workspace path per line, `#` for comments, file absent
means there is nothing to publish — which is the normal case for most setups and must not be an
error.

```bash
targets="$HOME/.agent-sync/publish.targets"
if [ ! -f "$targets" ]; then
  echo "no publish targets configured — nothing to publish"
else
  while IFS= read -r t; do
    case "$t" in ''|\#*) continue ;; esac
    if [ -f "$t/scripts/publish.sh" ]; then
      # </dev/null matters: the child may read stdin, and stdin here IS the target list. Without
      # it, one target can swallow the rest and the next is silently never published.
      bash "$t/scripts/publish.sh" </dev/null \
        || { echo "PUBLISH REFUSED at $t — stop here"; break; }
    else
      echo "no scripts/publish.sh at $t — skipping"
    fi
  done < "$targets"
fi
```

**Each target owns the copying.** Only the target knows its own leak guard, which skills it
accepts, and how it commits — so this skill runs the target's script and respects the answer. It
never copies files itself, and never works around a refusal.

**On a non-zero exit, stop.** Report what the script printed, name the **library** file to fix,
and do not retry, do not continue to another target, and do not offer to publish "just the clean
ones" — a partial publish is a transformation by omission. A target is expected to refuse without
leaving anything behind; if its output says it could **not** put itself back, that is the one case
to report as needing a hand, and still not to work around.

**A green publish means no *known* pattern, not "no private data".** A target's guard bounds the
patterns it has been told about; a private name nobody has added to its pattern file passes it,
and a secret is not a name at all. Read a green publish as the floor, never as a clean bill of
health — in particular, **everything inside a skill directory is published**, so a stray `.env`,
an editor backup or a credential file in the library goes public with it. Keep skill directories
to the pack's own files; a target that lists extra files it is about to publish is telling you to
read that list.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- Try the change on a real task
- `ws-setup` — the change means a project's cartridge needs regenerating
- `ws-refine` — another change
