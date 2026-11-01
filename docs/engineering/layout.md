# What lives where in this repo

**A map: what each path is, whether it is authored here or a received copy, and which check looks
at it.** Read it before you write a file here, so the file lands in the right place and in the
right copy.

**What is not on this page.** How to *work* on this project — the loop, the claim flow, the rules
that override an agent's defaults — is the root [`AGENTS.md`](../../AGENTS.md) and the cartridge
at [`agent/reference.md`](../agent/reference.md); this page restates neither. Which copy of the
pack is authoritative, and the publish mechanism that moves bytes into `skills/`, is
[sync-direction.md](./sync-direction.md). Cartridge keys are
[the schema page](../integration/cartridge-schema.md).

## The repo in one table

**Received copy** means the bytes here were produced by copying from the private working copy of
the pack. Editing them here does not change the pack, and the next publish overwrites the edit.

| Path | What it is | Provenance | Checked by |
|---|---|---|---|
| `README.md` | what the pack is, for a reader arriving cold | authored here | names, links |
| `AGENTS.md` | the agent-facing workspace brief at the repo root | **generated** here, from `docs/agent/workspace/AGENTS.md` — edit the source | names, links |
| `CLAUDE.md` | a pointer at `AGENTS.md`, so one file serves both | authored here | names, links |
| `LICENSE` | the licence | authored here | **excluded from the name scan** — the copyright holder's name belongs there |
| `CONTRIBUTING.md` | how to work in a fork, starting with the hook command; why `skills/` is not editable here | authored here | names, links |
| `SECURITY.md` | what the guard protects, the four limits on it, and the two reporting routes | authored here | names, links |
| `CODE_OF_CONDUCT.md` | Contributor Covenant 2.1, with the contact method filled in and a scope note added above *Our Pledge* — the Covenant's own text and structure are otherwise unchanged. Scoped to the issue tracker, since no pull request is accepted | authored here | names, links |
| `.github/workflows/check.yml` | runs `bash scripts/check.sh` in CI on every PR into `main` and every push to `main` | authored here | names only — section 3 reads `.md` files, so a link in a workflow is never resolved |
| `docs/` | everything on this page's docs-tree table | authored here | names, links |
| `skills/` | the pack itself: the `ws-*` skills and the shared reference material they read | **received copy** | names, frontmatter, links, parity |
| `scripts/check.sh` | the whole verification suite for this repo | authored here | **excluded from the name scan** — it holds the exclusion logic |
| `scripts/leak-patterns.txt` | the private-name patterns the scan uses | authored here | **excluded from the name scan** — it *is* the list |
| `scripts/publish.sh` | the guarded copy that lands a publish here | authored here | names |
| `.githooks/pre-commit` | runs the name scan over staged content | authored here | **excluded from the name scan** |
| `.gitignore` | keeps workspace state and the journal out of history | authored here | names |
| `.worksite/` | track directories, journal, scratch | local only — **not committed** | nothing |

**The `skills/` consequence.** Because it is a received copy, a new tracker adapter or a new
review pack is a new file in the *working* copy, never a file added here. The procedures are
[trackers.md](./trackers.md) and [stacks.md](./stacks.md).

## The docs tree here

The pack's shared reference holds the generic docs structure and the living/immutable property
for each folder. This is that structure as it actually stands in this repo.

| Folder | What belongs in it here | Kind | Stale means |
|---|---|---|---|
| [`product/`](../product/overview.md) | what the pack is, the design moves and why | living, slow | drift |
| `engineering/` (this folder) | how the pack is built and composed: this page, [trackers.md](./trackers.md), [stacks.md](./stacks.md), [sync-direction.md](./sync-direction.md) | **living, fast** | **confidently wrong** — changes in the same PR as what it describes |
| [`integration/`](../integration/cartridge-schema.md) | the contracts, key by key — the cartridge schema | living, contract | another reader builds against a shape that is not there |
| [`decisions/`](../decisions/0001-library-is-the-source-of-truth.md) | ADRs, `NNNN-<slug>.md` | **immutable** | never edited; superseded by a newer ADR |
| [`roadmap/`](../roadmap/) | phases and tasks — this project's tracker | living | the plan is wrong, and the loop reads it |
| [`runbooks/`](../runbooks/purge-a-leak-from-history.md) | a recurring operational procedure | living | **dangerous** — someone follows it |
| [`records/`](../records/2026-11-01-documentation-pack-validation.md) | dated point-in-time reports: validations, audits, experiments | **immutable, dated** | cannot be stale — it records a moment |
| [`agent/`](../agent/reference.md) | the cartridge, plus [`risks/`](../agent/risks/common.md), `workspace/` and [`worklog/`](../agent/worklog/p3.1.md) | living | skills read a wrong fact, or read nothing |
| [`STATUS.md`](../STATUS.md) | where the work is right now | living | the first thing anyone reads is wrong |

**Deliberately absent**, so their absence is not read as an oversight: `design/`, because a repo
of Markdown has no UI; and `agent/rules/`, because this project's "code" is the pack and the
refinement skill already governs editing it. `agent/journal/` exists on a working machine and is
kept out of history on purpose.

## What the checks actually cover

`verify` for this repo is `bash scripts/check.sh`. There is no typecheck, lint, test or build
here, by design. The script runs over the working tree, or with `--staged` over staged content
only — which is how [the pre-commit hook](../../.githooks/pre-commit) invokes it.

It also runs in CI. [`.github/workflows/check.yml`](../../.github/workflows/check.yml) invokes
`bash scripts/check.sh` with no arguments — so the broader working-tree mode, over a fresh
checkout — on every pull request into `main` and on every push to `main`. The push trigger is not
optional: publish commits land on `main` directly
([ADR 0002](../decisions/0002-publishing-is-a-guarded-copy-from-the-library.md)), so a PR-only
workflow would leave the publish path unchecked. **CI running the suite is not CI blocking a
merge**: requiring the `check` job is a branch-protection setting on `main` rather than a file in
this tree, and it is not yet set. And **the push-to-`main` run cannot block anything even once it
is** — the commit has already landed when that run starts, so it reports after the fact, which is
why the publish path keeps its own three runs of the guard rather than relying on this one. The
hook therefore remains the only guard on a clone where nobody ran
`git config core.hooksPath .githooks`.

Each numbered section, and the gap it leaves:

| Section | What it looks at | Its blind spot |
|---|---|---|
| **1. private names** | every tracked **and untracked** file, matched case-insensitively against [`scripts/leak-patterns.txt`](../../scripts/leak-patterns.txt), minus the excluded files named in the table above, **and minus one string allowlisted inline in the script itself** — the pack's own public npm scope, which is a real install command | **only the listed patterns.** A private-looking name nobody has added to that file passes every run, and a secret is not a name at all. Green means "no known pattern", never "no private data". The excluded files are not scanned at all, and the inline allowlist is not in the pattern file, so auditing coverage means reading both. |
| **2. skill frontmatter** | each skill directory under `skills/`: that a `SKILL.md` exists, opens with frontmatter, has a `name` matching its directory, and has a non-empty `description` | **nothing about the body.** A skill whose description is accurate and whose instructions are wrong passes. Shared material that is not a `SKILL.md` is not examined. The whole section is skipped when `skills/` is absent. |
| **3. relative links** | every `.md` in that same file list; resolves every inline link target against the containing file's directory and **fails** on a missing target | **the fragment is stripped, so an anchor is never verified**, and a line number never was. Templated targets containing `<` or `>` are skipped by design. A sample link inside a fenced code block is resolved like any other, so an illustrative path has to exist or be templated. Links in files that are not `.md` are not read. |
| **4. library parity** | compares the published `ws-*` directories here against the private working copy on this machine | **informational, never a failure**, and skipped entirely on a machine with no local working copy — which is the normal case for a reader. "Working copy ahead of the repo" is a legitimate mid-change state. |

The sharper consequence of section 3: in `--staged` mode the link targets are resolved against
the **working tree**, not the staged tree, so a link to a file that is present locally and not
staged passes the hook and breaks on a fresh clone.

## Where your writing goes

| What you produced | Where it belongs |
|---|---|
| a fact about how the system is built or composed | `engineering/` |
| a choice made between alternatives, with the rejected ones | `decisions/`, as a new ADR |
| a per-key account of a contract someone builds against | `integration/` |
| a dated measurement, validation or audit | `records/` |
| a procedure that will be run again | `runbooks/` |
| what a shipped task left behind | `agent/worklog/` |
| a risk class worth catching in this project again | `agent/risks/` |
| a change to what the work *is* | `roadmap/`, and `STATUS.md` |

A risk class worth catching in **other** projects is not a docs commit at all — it is a pack
change, and [stacks.md](./stacks.md) says where it goes.

## Not committed

[`.gitignore`](../../.gitignore) keeps two things out of history: `.worksite/`, the workspace
state directory, and `docs/agent/journal/`, the journal mirror, whose format embeds a device name
in a repo that is public. **Do not remove either line.** The state directory is normally
uncommittable because a workspace root is not usually a git repo; here the workspace root *is*
the repo, so that ignore line is the only thing protecting it.

## Where to go next

- [`AGENTS.md`](../../AGENTS.md) and the cartridge at [`agent/reference.md`](../agent/reference.md)
  — how to work here
- [sync-direction.md](./sync-direction.md) — which copy of the pack is the real one
- [trackers.md](./trackers.md) and [stacks.md](./stacks.md) — extending the pack
- [the cartridge schema](../integration/cartridge-schema.md) — the keys, one by one
- [the concepts page](../product/overview.md) — what the pack is and why it is shaped this way
