# ws-shared reference

Read this before any `ws-*` work. These are facts about **your** machines and stores, not about
any one project. Project facts live in that project's cartridge (see *Cartridges* below).
Worked examples of every file named here are in [examples/](examples/).

## The two stores

| Store | Path | Git remote | Holds |
|---|---|---|---|
| **Library** | `~/.agent-sync/store` | a private repo you own, e.g. `<you>/agent-library` | skills, MCP definitions, routing |
| **Secrets** | `~/.agent-secrets` | a second private repo you own, e.g. `<you>/agent-secrets` | sops-encrypted credentials, `manifest.tsv` |

**Both are repos you create yourself.** `agent-sync setup --create-remote` makes the library;
the secrets store is created by `ws-env init`. Both are private, and neither ever holds a
decrypted secret. There is no shared or central store — the pack never points you at someone
else's.

## Where a project's docs live

| Project shape | Docs home |
|---|---|
| **one repo** | `<repo>/docs/` |
| **several repos** | a dedicated `<project>-docs` repo, cloned into the workspace beside the code |

A multi-repo project is a long-term one, so it earns its own docs repo. That repo may be in
your own account even when the code repos belong to a company organisation — that is the normal
case, not a mistake, because the docs carry a way of working that outlives any one engagement.

**The cartridge is `<docs>/agent/`**, wherever the docs are. There is no separate store for it:
a docs repo is already cloned into the workspace, already syncs, and `git -C "<project>-docs"`
works like any other repo.

### The structure, same in a folder or a repo

```
README.md  00-START-HERE.md  STATUS.md
product/       what it is and who for
engineering/   how it is built: architecture, database, practices, environments, local-setup
integration/   API contracts, one per feature
design/        design system, UI reference
decisions/     NNNN-<slug>.md ADRs
roadmap/       phases -> tasks, if tracked that way
runbooks/      recurring operational procedure: deploy, rotate, restore, reseed
records/       dated point-in-time: audits, regression reviews, feedback, incidents, experiments
agent/         the cartridge: reference.md, risks/, rules/, workspace/, worklog/
```

**Living or immutable** — the property the loop skills key off:

| Folder | Kind | Stale means |
|---|---|---|
| `engineering/` | **living, fast** | **confidently wrong. Changes in the same PR as the code** |
| `integration/` | living, contract | breaks the other repo |
| `product/`, `design/` | living, slow | drift |
| `roadmap/`, `agent/` | living | the plan; or skills read nothing |
| `runbooks/` | living | **dangerous** — someone follows it |
| `decisions/` | **immutable in substance** | a decision is superseded by a newer ADR, never rewritten — but an **item inside** one may be amended in place, with the date and the task in the header, and that is how a narrowed rule stays one rule instead of two |
| `records/` | **immutable, dated** — except a standing record, which is **living** | a dated report cannot be stale: it records a moment. A **standing** record — a limitations list — is the exception: it is living, so keep it clearly named and expect to edit it when a limitation closes or its stated cause turns out to be wrong |

Keep dated reports in `records/`, never loose among the reference docs. Mixing them is what makes
a whole docs tree feel untrustworthy.

### What stays in the brain

If you keep a personal knowledge base — a private notes repo, wherever it lives — it holds only
what matters **beyond** the project: business and commercial decisions, people, meetings,
contracts and the delivery relationship, plus a short note per project pointing at its docs.
This is optional; nothing in the pack requires it. Anything describing the system itself belongs in the docs.
Decisions about code go in `decisions/`; decisions about the business go in the brain.

## This device, and its projects

`~/.agent-sync/device.yaml` is the only place that knows where things are on *this* machine:

```yaml
device: work-laptop          # this device's id; `machine:` overrides in a cartridge key off it
agents: [claude, codex, cursor]
projects:
  northwind: /Users/example/code/northwind
  kestrel:   /Users/example/code/kestrel
```

A fuller one, with the Windows equivalent, is in [examples/device.yaml](examples/device.yaml).

**Always resolve a workspace path from here. Never hardcode one** — another machine has
different paths, and that is the whole point of this file.

A project in the library but absent from `projects:` is not linked on this device
(`agent-sync link` / `unlink`). A workspace folder that does not exist yet is normal on a new
machine: `ws-sync --new-device` clones it.

**Read the project ids from this file**, never from a list written down elsewhere — a hardcoded
list is wrong the moment a project is added or renamed.

**A marker cannot travel if the workspace root is not a git repo.** Multi-repo projects normally
have a plain folder as their root, so `.agent-sync.yaml` is not committed anywhere and nothing
carries it to the next machine. For those, run `agent-sync link <id>` by hand on each device,
with that exact id. Record which projects this applies to in the project's own docs, not here.

## agent-sync commands worth knowing

| Command | Does |
|---|---|
| `agent-sync sync` | pull, apply, push — the daily loop for skills and MCP |
| `agent-sync status [--why]` | what is deployed where, and which rule decided it |
| `agent-sync save` | validate, apply, commit, push — after editing the library |
| `agent-sync doctor` | check agents, git, store health |
| `agent-sync link` / `unlink` | register this directory as a project on this device |

`agent-sync` deliberately refuses to carry secret *values* — the library holds
`${secret:name}` references only. That is why `ws-env` exists.

## The secrets store

```
~/.agent-secrets/
  .sops.yaml      which age key may decrypt which path (FIRST match wins)
  manifest.tsv    every encrypted file -> its type and its destination
  .githooks/pre-commit   refuses to commit anything without sops ciphertext
  <project>/     one folder per project, named by its agent-sync id
  [personal/]    optional, and decrypted only with the passphrase key
```

`manifest.tsv` is tab-separated — `src`, `type`, `project`, `dest` — deliberately **not** YAML,
because the consumer is a bash loop and neither `yq` nor `jq` can be assumed on every machine:

```
northwind/api.local.env	dotenv	northwind	northwind-api/.env
```

A fuller one, covering `json` and `binary` too, is in
[examples/manifest.tsv](examples/manifest.tsv).

Read it with no dependencies:

```bash
# $proj, not $1: a positional parameter inside a skill body is replaced by the caller's
# argument before an agent ever sees it. Set proj, then call ws_root with no arguments.
ws_root() { sed -n '/^projects:/,$p' "$HOME/.agent-sync/device.yaml" | sed -n "s|^  $proj: *||p" | head -1; }
grep -v '^#' "$HOME/.agent-secrets/manifest.tsv" | while IFS=$'\t' read -r src type project dest; do
  proj="$project"; root=$(ws_root); ...
done
```

- `src` — path inside the secrets store.
- `type` — `dotenv` (values encrypted, **names and comments stay readable**, so a diff shows
  *which* variable changed without revealing it), `json`, or `binary` (whole file opaque; used
  for SSH keys, CSVs and any config whose bytes must come back exactly).
- `dest` — path **relative to the workspace root**, resolved per device via `device.yaml`.

### Keys

| Key | Path | Decrypts | Used by |
|---|---|---|---|
| agent | `~/.config/sops/age/keys.txt` (mode 600) | every project folder | agents, unattended |
| personal | `~/.config/sops/age/personal.age` (passphrase) | `personal/` only | you, interactively |

Point sops at the agent key with `SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"`.

**Be honest about what this protects.** The agent key is a plaintext file owned by you, so
anything running as him can read it — key separation is a guardrail against accidents and
against a leaked agent key, **not a sandbox**. The real boundary on `personal/` is that its key
needs a passphrase he types, so an agent cannot use it while running unattended. Never claim
more than that.

**`personal/` is not active until** that passphrase key exists and its public key is filled
into `.sops.yaml`. Until then, say so rather than writing anything into `personal/`.

### Encrypting correctly

sops resolves `.sops.yaml` relative to the **input file**, so encrypting a file that lives
outside the store silently fails with "no creation rules". Always stage the plaintext inside
the store first:

```bash
cp "<plaintext>" "$HOME/.agent-secrets/<proj>/.staging-<name>"
( cd "$HOME/.agent-secrets" && sops -e --input-type <it> --output-type <ot> "<proj>/.staging-<name>" ) > "$HOME/.agent-secrets/<proj>/<name>"
rm -f "$HOME/.agent-secrets/<proj>/.staging-<name>"
```

Then **verify before trusting it**: decrypt and compare, for dotenv by `KEY=sha256(value)` pairs
plus comment count, for binary by a whole-file hash. Never compare by printing.

Note: sops dotenv mode drops **blank lines** (nothing else). Cosmetic; do not treat it as loss.

## Cartridges

A project's own facts live in `<docs_home>/reference.md` — Markdown with a YAML frontmatter
block (repos, tracker, git flow, environments, house rules, `machine:` overrides).

**`ws-env` and `ws-sync` must work without any cartridge**, from `device.yaml` and
`manifest.tsv` alone. Cartridges are enrichment. This is the degrade-never-fail rule, and it
is why credentials sync works today, before any project has been migrated.

**`shared_stores:` declares a place the project's work reaches that is not one of its repos** — a
library a tool owns, a shared fixture store. A top-level list of `{id, path, publish, note}`, with
`path` written `$HOME`-relative because a cartridge is committed and read on every machine. It is
there for one reason: a worktree is a checkout of a repo in `repos:`, so it isolates nothing
outside them, and `ws-fanout`'s gate runs **one track per declared store per batch**. `ws-fanout`
is the only reader; `ws-setup` asks the question and writes the key, with **none** as its
recommendation. A project that declares nothing has a gate that can see no further than `repos:`,
which is what the silence costs — not an error (R1).

## Tracks, the journal and the artifact lifecycle

The state model the loop skills share — track directories, `tracks/current`, the journal format
and the harvest-then-delete rule — is in [tracks.md](tracks.md). Read it before `ws-start`,
`ws-plan`, `ws-verify`, `ws-ship`, `ws-wrap` or `ws-debug`.

## Trackers

One adapter per tracker kind, in [trackers/](trackers/), each answering the same four questions
(list, claim, mark, note) so no skill knows the kind:

| `tracker.kind` | Adapter | Suits |
|---|---|---|
| `roadmap-files` | `trackers/roadmap-files.md` | a solo build with phases; a real claim lock |
| `github-projects` | `trackers/github-projects.md` | a team, or anything already using issues |
| `trello` | `trackers/trello.md` | a board someone else owns |
| `tasks-file` | `trackers/tasks-file.md` | `standard` projects — one person, one area, no phases; a real claim lock |
| anything else | ask the four questions, then write a new adapter | — |

**Only `roadmap-files` and `tasks-file` give a real lock** (a pushed commit that can be
rejected). GitHub Projects and Trello do not: re-read the item after claiming and stop if
someone else got there.

## Review packs

Three tiers. Tier 1 is universal, tier 2 is shared by stack, tier 3 is per project.

```
ws-shared/review/tier1-universal.md    every change, always
ws-shared/stacks/security-baseline.md  every change, always — objective, OWASP Top 10:2025
ws-shared/review/documentation.md      every change, always — where writing belongs
ws-shared/review/ai-slop.md            every change an agent wrote
ws-shared/stacks/<name>.md             selected by the repo's `stack:` tags
<docs_home>/risks/common.md            per project (tier 3)
<docs_home>/risks/<repo>.md
```

Stack tag → pack. A tag with no pack is fine: tiers 1 and 3 still apply (degrade, never fail).
**Deduplicate**: several tags map to one pack (`nestjs` and `typeorm` both select
`nestjs-typeorm.md`), and a pack is read once per review, not once per tag.

| Tag | Pack |
|---|---|
| *(none — always on)* | `security-baseline.md` |
| `nestjs`, `typeorm` | `nestjs-typeorm.md` |
| `hexagonal` | `hexagonal-nest.md` |
| `nextjs-app-router` | `nextjs-app-router.md` |
| `vite`, `react-router-spa` | `vite-react-spa.md` |
| `fastapi`, `sqlalchemy` | `fastapi-sqlalchemy.md` |
| `flask`, `pymongo` | `flask-mongo.md` |
| `terraform`, `aws` | `terraform-aws.md` |
| `vercel-serverless` | `vercel-serverless.md` |
| `migrations` | `migrations-sql.md` |
| `money` | `money.md` |
| `llm-agent` | `llm-agent.md` |

**Objective vs house.** `security-baseline.md` and `tier1-universal.md` are objective: breaking
them causes a vulnerability or a defect. A project's own practices docs hold the house rules and
the stack-specific traps, which are a mix of objective and deliberate preference — a review
reports a preference as a preference, never as a law, and never blocks on taste.

**Packs grow by use.** When `ws-review` confirms a finding whose class is not written down
anywhere, it proposes one line — to the stack pack if other projects on that stack would
benefit, to the project's `risks/` if not. That is the only maintenance these files get, and it
is deliberate.

## Cross-platform rules

| Concern | Rule |
|---|---|
| Shell | Git Bash on Windows. Do not port skills to PowerShell |
| Paths | Always from `device.yaml`. Never `~/Development/...` in a command |
| `chmod 600` | A **no-op on Windows**. Say so rather than implying env files are protected there |
| Line endings | `tr -d '\r'` when reading an env file. The secrets store pins LF via `.gitattributes` |
| Symlinks | Do not create them. Windows git checks a symlink out as a text file containing the path, silently. Use a deployed **copy** with a generated-by header |
| Python venv | `bin/` on macOS, `Scripts/` on Windows |
| **zsh word splitting** | If your default shell is **zsh**, it does **not** split an unquoted `$var` into words the way bash does. `for t in $tags` iterates **once** under zsh and silently does the wrong thing. `for p in $(cmd)` is fine (zsh splits command substitution). Prefer `while IFS=… read -r` over `for … in $var`, or declare `bash` explicitly |
| **bash word splitting on a path with a space** | The mirror image of the row above, and the one that actually bites: under **bash** a workspace path like `~/My Projects/app` splits into `~/My` and `Projects/app`, so `for r in <repos>` iterates **fragments**. Every `git -C` then fails on a path that does not exist, and the loop still prints a row per fragment and exits **0** — a dirty repo reports `0 changed`, a refresh refreshes nothing, a review diff comes back empty. Read repo paths line by line: `while IFS= read -r r` fed from a heredoc, and quote `"$r"` at every use. zsh hides it, bash shows it, and the report looks the same either way |
| **a path placeholder in a template** | The same splitting, arriving through the *template* rather than through a loop, and this is the one you will write without noticing. A fenced block saying `git -C <repo>` is filled by substituting a path, so a workspace at `~/My Projects/app` produces `git -C /Users/x/My Projects/app` — two arguments. **Carry the quotes in the template**: `git -C "<repo>"`, `cat "<state_dir>/tracks/current"`, `state_dir="<state_dir>"`. It does *not* always fail loudly, which is why it is worth a row of its own: inside `$( )` the row still prints `0 changed` at exit 0; behind the `2>/dev/null` that is there for "the file is absent" it reads as *no current track*; and an unquoted **assignment** is worst of all — bash reads `state_dir=/x/My Projects/.p` as a prefix assignment for the command `Projects/.p`, so the variable ends up **empty** and `rm -rf "$state_dir/tracks/$id"` becomes `rm -rf "/tracks/$id"` at the filesystem root, exits 0, and the verification that follows checks the same wrong path and reports it clean. That last one is the only shape that is **not** silent — the assignment line prints `bash: Projects/.p: No such file or directory` and exits 127 — so it is loud and *then* falsely reassuring, which is easier to miss than silence because an error you have already read scrolls past before the success line arrives. Some placeholders take **no** quotes and must not get them: `<paths…>`, which is several words on purpose; `-R <owner>/<repo>`, a GitHub slug rather than a path; and a **bare id** — `<id>` or `<project>` on its own — which cannot hold a space (`<project>` is constrained by `device.yaml`'s own parser to `[a-z0-9-]`; a track id is constrained by the pack's convention, not by a parser). An id composed *into* a path is a path and takes the quotes: `git -C "<project>-docs"`, `"<state_dir>/tracks/<id>/"` |

## House rules for every ws-* skill

- **Never print a secret value.** Refer to variables by name. Report counts and names only.
- **Never discard work.** Uncommitted changes, stale branches, divergence: report them and ask.
  Losing months-old work on the other laptop is the worst available outcome.
- **Show it, then wait for a yes** before any commit, push, overwrite or delete.
- **No AI attribution** in any commit or PR: no `Co-Authored-By`, no "Generated with".
- **Never write an agent's own settings or permission files.** Not `.claude/settings.json`, not
  `settings.local.json`, not a `permissions.allow` list, in any project. Permission level is the
  user's own control — switched per task in the agent itself — and a committed allowlist both
  overrides that choice and rots. A skill that wants fewer prompts is solving the wrong problem.
- Verify every command you report as done. Mark anything you could not check.
