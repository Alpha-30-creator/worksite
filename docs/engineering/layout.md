# What lives where in this repo

**A map: what each path is, whether it is authored here or a received copy, and which check looks
at it.** Read it before you write a file here, so the file lands in the right place and in the
right copy.

**What is not on this page.** How to *work* on this project — the loop, the claim flow, the rules
that override an agent's defaults — is the root [`AGENTS.md`](../../AGENTS.md) and the cartridge
at [`agent/reference.md`](../agent/reference.md); this page restates neither. *Why* the library
owns the skills, and why a publish is a copy rather than a merge, is
[ADR 0001](../decisions/0001-library-is-the-source-of-truth.md) and
[ADR 0002](../decisions/0002-publishing-is-a-guarded-copy-from-the-library.md). Cartridge keys are
[the schema page](../integration/cartridge-schema.md).

## The repo in one table

**Received copy** means the bytes here were produced by copying from the private working copy of
the pack. Editing them here does not change the pack, and the next publish overwrites the edit.

| Path | What it is | Provenance | Checked by |
|---|---|---|---|
| `README.md` | what the pack is, for a reader arriving cold | authored here | names, links |
| `INSTALL.md` | the install path, addressed to an agent | authored here | names, links |
| `AGENTS.md` | the agent-facing workspace brief at the repo root | **generated** here, from `docs/agent/workspace/AGENTS.md` — edit the source | names, links |
| `CLAUDE.md` | a pointer at `AGENTS.md`, so one file serves both | authored here | names, links |
| `LICENSE` | the licence | authored here | **excluded from the name scan** — the copyright holder's name belongs there |
| `CONTRIBUTING.md` | how to work in a fork, starting with the hook command; why `skills/` is not editable here | authored here | names, links |
| `SECURITY.md` | what the guard protects, its five automated run sites, the four limits on it, and the two reporting routes | authored here | names, links |
| `CODE_OF_CONDUCT.md` | Contributor Covenant 2.1, with the contact method filled in and a scope note added above *Our Pledge* — the Covenant's own text and structure are otherwise unchanged. Scoped to the issue tracker, since no pull request is accepted | authored here | names, links |
| `.github/workflows/check.yml` | runs `bash scripts/check.sh` in CI on every PR into `main` and every push to `main` | authored here | names only — section 3 reads `.md` files, so a link in a workflow is never resolved |
| `docs/` | everything on this page's docs-tree table | authored here | names, links |
| `skills/` | the pack itself: the `ws-*` skills, the shared reference material they read, and `ws-refine/audit.sh` — the one executable file the pack ships | **received copy** | names, frontmatter, links, parity |
| `scripts/check.sh` | the whole verification suite for this repo | authored here | **excluded from the name scan** — it holds the exclusion logic |
| `scripts/leak-patterns.txt` | the private-name patterns the scan uses, **and its `!` allowlist entries** — this file alone is the whole definition of coverage | authored here | **excluded from the name scan** — it *is* the list |
| `scripts/object-store-baseline.txt` | the unreachable objects known to carry a pattern, with the measurement and the decision not to prune | authored here | names, links — it holds hashes and prose, never a private name |
| `scripts/publish.sh` | the guarded copy that lands a publish here. It classifies every file in a skill directory: Markdown silently, reference data and the executable files named in its `PACK_EXEC` list **with the list printed**, anything else refused | authored here | names |
| `.githooks/pre-commit` | runs the name scan over staged content | authored here | **excluded from the name scan** |
| `.gitignore` | keeps workspace state and the journal out of history | authored here | names |
| `.worksite/` | track directories, journal, scratch | local only — **not committed** | **section 5**, which asserts the ignore rule rather than trusting it |

**The `skills/` consequence.** Because it is a received copy, a new tracker adapter or a new
review pack is a new file in the *working* copy, never a file added here. The procedures are
[trackers.md](./trackers.md) and [stacks.md](./stacks.md).

## Where `skills/` comes from

```
  agent-sync library                 this repo                      your agents
  (private, the working copy)        (public, a published artifact)
  ~/.agent-sync/store/skills/   ──→  skills/                   ──→  Claude, Codex, Cursor
          ▲                                                              ▲
          │ ws-refine edits here                                         │ agent-sync save
          └──────────────────────────────────────────────────────────────┘
```

**One direction only.** The library is edited; this repo receives. Nothing is ever edited here
and carried back. Which copy is authoritative, and the two alternatives rejected, are
[ADR 0001](../decisions/0001-library-is-the-source-of-truth.md).

### How a publish actually works

`ws-refine` ends by reading `~/.agent-sync/publish.targets` — one absolute workspace path per
line — and running each target's own `scripts/publish.sh`. No such file means no targets, and
nothing to publish. The target's path is never written into a skill: this repo's own location is
one of the private names the guard looks for, so a hardcoded target would be caught by the very
check it runs.

[`scripts/publish.sh`](../../scripts/publish.sh) then:

1. **refuses up front** on a missing library, a library with no `ws-*` skills, a symlink or an
   unexpected file inside a skill directory, a tree that is not on `main`, a dirty tree, a
   missing pre-commit hook, a `check.sh` that is already failing here, or a skill published here
   that the library no longer has (`--prune` is how a deletion is meant, and `--prune-many` is
   how a large one is);
2. assembles the candidate — the library's `skills/ws-*`, selected **by glob, never by a list** —
   inside a throwaway `git clone` of this repo, and runs
   [`scripts/check.sh`](../../scripts/check.sh) **there**. So a leak is refused before a single
   byte is written here: no commit, no staged change, no new file;
3. asserts the copy is plain, with `diff -rq` of library against candidate having to be silent —
   publishing is a copy, never a transformation, turned into an assertion;
4. writes this tree and stages it, then **runs the guard and the assertion again on that staged
   tree** — the bytes actually about to be committed, which until then nothing had checked — and
   commits (the pre-commit hook runs the same guard once more on those bytes) and pushes.
   Nothing to copy means "nothing to publish" and a clean exit. Any failure between the first
   write and the commit restores this repo to the HEAD and the clean tree it was found with.

Publish commits land on `main` directly rather than through a pull request. That carve-out, its
residual risk and the mechanism's rejected alternatives are
[ADR 0002](../decisions/0002-publishing-is-a-guarded-copy-from-the-library.md).

### How the graph audit composes

`ws-refine` ends with a graph audit, and every pack change is required to run it — so it is the
one check whose own correctness is load-bearing for all the others. It is **a script**,
`ws-refine/audit.sh`, run whole by path: the later parts read counts the earlier parts established,
and part of it produces a verdict that has not been earned.

**It is a file for a reason, and the reason is the audit's own subject matter.** Until 2026-11-03
it was a fenced block inside `ws-refine/SKILL.md`, and a skill's body has the caller's argument
substituted into its positional parameters on the way to the agent. Its awk programs use `$0` as
a field reference, so invoked with any argument — the normal way — the delivered copy arrived with
`if($0!="---")` rewritten and would not parse. Part 3 then produced a spurious finding for every
skill, and **part 3b reported no findings at all while its scanner had never run**, its own count
already incremented. A clean verdict over a scan that did not happen, in the part added to catch
that exact shape (p8.37). Nothing substitutes into a file run by path, so the file is the fix; it
also lets part 3b stop excluding `$0`, which is what catches the next instance rather than this
one. It is run as `bash <path>` so no execute bit has to survive a copy or a publish, and it is
the **library** copy, which is one absolute path on every agent and the copy the audit is about.

It reads three things, from three places, and the distinction matters because two of them are not
in this repo:

| It reads | From | Which copy that is |
|---|---|---|
| the pack's own Markdown — frontmatter, skill references, links, `What next?` sections | `~/.agent-sync/store/skills/` | the **library**: the working copy, which is what the audit is *about* |
| whether each referenced file reached each agent | the deployed trees, one per agent | the **deployed copies**, written by `agent-sync save` |
| whether anything is unapplied | `agent-sync status --json` → `operations[]` | neither copy — the deployment's own state |

**Nothing in the audit reads this repo.** `skills/` here is a received copy
([ADR 0001](../decisions/0001-library-is-the-source-of-truth.md)) and auditing it would answer
about files no agent loads — which is exactly the failure the first two parts exist to refuse.

Two **gates** decide whether a verdict is available at all, then five checks run, then a verdict
line names its own counts:

1. **Is it deployed?** Any `agent-sync` operation on a `skill/ws-*` ref aborts the audit —
   `conflicted` by name, anything else as pending. Run before `agent-sync save` this gate
   **always** aborts, because the library has moved and the deployed copies have not. That is
   correct: the run that certifies a change is the one *after* the save.
2. **Is this the library?** The resolved working directory is compared against the store path
   `agent-sync` itself reports — not against the string the block just used to `cd`, which would be
   a comparison of a value with itself. Then a readable `ws-shared/SKILL.md` as a marker and a floor
   of ten readable `ws-*/SKILL.md`, which catch the right directory holding the wrong contents.
3. **Frontmatter**, **forward coverage** (every skill named **anywhere in the pack** exists — it
   greps whole `SKILL.md` files, not only `What next?` sections, which is wider than the heading
   on it suggests and is the safe direction), and **links**,
   now over all of the pack's Markdown rather than only each `SKILL.md`, each link resolved against
   the directory of the file that holds it. Its character class includes `_` and `A-Z` because
   without them a `new_device.md`- or `README.md`-shaped target is invisible to the check rather
   than reported by it — a silent pass inside the check that exists to find silent passes.
4. **Reverse coverage** — every exit the *prose* offers is listed in that skill's `What next?`.
5. **The deployed check, per agent**, printed even when clean — and the block then **asserts that
   line was printed** before the verdict counts it. That assertion is not decoration: the check
   runs inside a command substitution, so its own failure cannot end the block, and without the
   assertion a dead check left the verdict printing `0 missing under an agent` at exit 0. A zero
   from a check that did not run is the defect this whole block exists to kill, and it was found
   in review *inside the fix*.

**Every count in the verdict is earned, and that is the point of the design rather than a detail.**
Parts 3 to 6 each do their work in a plain loop and end without an `exit`, so a part that read
nothing leaves its findings variable empty — which is the same text as "no findings". So each part
carries a **denominator** into the verdict and the block asserts it before printing: how many
`SKILL.md` were parsed, how many skill names were resolved, how many files and links were read, and
how many skills were both *checked* and *actually scanned*. A denominator of zero, or a mismatch
between two parts' counts, aborts instead of certifying. Three consequences worth knowing:

- **`0 findings` and `0 read` are now different outputs.** Before this, a `grep` writing
  `Permission denied` to stderr still produced `0 missing skill` in the verdict.
- **A `ws-*` directory whose `SKILL.md` cannot be read is reported, not dropped.** Directories that
  *exist* and directories that are *readable* are counted separately and the difference is a
  finding, because noticing the gap by knowing today's count by heart is exactly the bookkeeping
  the preflight's floor refuses to be.
- **`set -e` is deliberately not used, and would be actively harmful.** A clean part ends on
  `[ -n "$x" ] && printf …`, which returns **non-zero precisely when there are no findings**, so
  under `set -e` the script would abort exactly when the audit is clean. Positive counts are the
  only route. This is written down because it is the first thing anyone will reach for.

**One failure mode this design caught in its own author's work**, recorded because it is the
argument for it: part 3 was first written using a variable name that part 1 already held the
`agent-sync` JSON in. Part 3 clobbered it, part 7 silently received nothing — and the completion
sentinel added one revision earlier is what surfaced it, rather than a verdict reading `0 missing
under an agent`.

**What it does not cover**, so the absence is not read as coverage:

| Blind spot | Consequence |
|---|---|
| reverse coverage is anchored on backticks **and** an offer verb | an exit offered in prose that names no skill in backticks, or through a verb outside the anchor list, is invisible. The anchor list is a sample of the pack's current idiom, not a grammar |
| **precision** is 3 candidates, 2 of them real, on the pack as it stands | roughly one false positive per pack-wide run. Each finding is read and judged, never auto-fixed, and it does not fail the audit — a comparison reads exactly like an offer and only a reader can tell them apart |
| **recall is the weaker half, and the larger number**: 33 distinct prose mentions of a sibling, 9 survive the verb filter, **12 unlisted pairs are never reported** | the check narrows the pack to a line or two worth reading. It is **not** a coverage guarantee in either direction. The figures and the misses are [the dated record](../records/2026-11-02-reverse-coverage-precision.md) |
| **fenced code blocks are excluded from the scan** | the check is about what the *prose* offers, and a comment inside a shell block is not prose — it tripped on one in the audit's own text. The cost is one-directional: an exit offered **only** inside a fenced example is missed |
| reverse coverage only looks at `SKILL.md` files | shared reference material sends readers to skills by name and has no `What next?`. Skills without one are **counted and the count printed**, not silently skipped |
| the identity assertion fires first on any wrong directory | the marker and the floor can only ever fire on the real library path, so testing them needs identity satisfied by construction |
| a skill whose entire body before `What next?` is fenced code | reported as `NO PROSE EXTRACTED` and **aborts**, because it is indistinguishable from a file whose frontmatter never closed. Legitimate-but-pathological input therefore stops the audit rather than being waved through |
| it depends on `agent-sync` being runnable | on a machine with no deployment the audit **aborts** rather than running a narrower version of itself |
| that an agent *obeys* `AUDIT ABORTED` is not proved | the shell makes the abort unavoidable within the script; the claim is only that a clean verdict is unreachable without the counts being printed |
| part 3b's compile probe catches a program that fails to **parse**, not one that is valid and wrong | a substitution yielding, say, a renamed-but-valid variable would still produce a clean scan. Measured. So the property is "cannot report zero after a scanner that **failed**", not "cannot report zero without having scanned" — and the reason the fix works is that the gap is now unreachable, because nothing substitutes into a file |
| that an agent runs **the file** rather than reconstructing the block is not proved either | the skill says to run the path and says why, and the `$0` the block needed is gone from the skill body — so there is nothing left there to paste. An agent that runs a stale **deployed** copy of `audit.sh` is the remaining case, and part 1 catches it only when the library has moved |

Why a verdict has to state its subject at all, the alternative that was tried and disproved, and
why `ok`, `exitCode` and `targets[]` are not read from `agent-sync status`, are
[ADR 0004](../decisions/0004-a-check-must-state-what-it-read.md). The measured precision behind the
reverse check is [a dated record](../records/2026-11-02-reverse-coverage-precision.md).

## The docs tree here

The pack's shared reference holds the generic docs structure and the living/immutable property
for each folder. This is that structure as it actually stands in this repo.

| Folder | What belongs in it here | Kind | Stale means |
|---|---|---|---|
| [`product/`](../product/overview.md) | what the pack is, the design moves and why | living, slow | drift |
| `engineering/` (this folder) | how the pack is built and composed: this page, [trackers.md](./trackers.md), [stacks.md](./stacks.md) | **living, fast** | **confidently wrong** — changes in the same PR as what it describes |
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
why the publish path keeps its own three runs of the guard — a preflight on this repo, a throwaway
clone of the candidate, then this repo's staged tree — rather than relying on this one. The
hook therefore remains the only guard on a clone where nobody ran
`git config core.hooksPath .githooks`.

Each numbered section, and the gap it leaves:

| Section | What it looks at | Its blind spot |
|---|---|---|
| **1. private names** | every tracked **and untracked** file, matched case-insensitively against [`scripts/leak-patterns.txt`](../../scripts/leak-patterns.txt), minus the excluded files named in the table above. The allowlist lives in that same file as `!` entries, and each one is **stripped out of the line** before matching, so the rest of the line is still scanned. The patterns are compiled once before anything is read, so a file that yields a regex `grep` cannot compile **refuses** rather than passing everything | **only the listed patterns.** A private-looking name nobody has added to that file passes every run, and a secret is not a name at all. Green means "no known pattern", never "no private data". The excluded files are not scanned at all. Until 2026-11-02 the allowlist was inline in the script **and dropped the whole matching line**, so a private name sharing a line with the allowlisted npm scope passed silently, and auditing coverage meant reading both files (p8.31). |
| **2. skill frontmatter** | each skill directory under `skills/`: that a `SKILL.md` exists, opens with frontmatter, has a `name` matching its directory, and has a non-empty `description`. Also that **`ws-shared` is the only skill carrying `disable-model-invocation: true`**, which is the arithmetic the "thirteen skills plus `ws-shared`" count in the README, the concepts page and the cartridge all rest on | **nothing about the body.** A skill whose description is accurate and whose instructions are wrong passes. Shared material that is not a `SKILL.md` is not examined. The whole section is skipped when `skills/` is absent — and the flag assertion is about the **set**, so it says nothing about whether any one description is right. |
| **3. relative links** | every `.md` in that same file list; resolves every inline link target against the containing file's directory and **fails** on a missing target | **the fragment is stripped, so an anchor is never verified**, and a line number never was. Templated targets containing `<` or `>` are skipped by design. A sample link inside a fenced code block is resolved like any other, so an illustrative path has to exist or be templated. Links in files that are not `.md` are not read. |
| **4. library parity** | compares the published `ws-*` directories here against the private working copy on this machine | **informational, never a failure**, and skipped entirely on a machine with no local working copy — which is the normal case for a reader. "Working copy ahead of the repo" is a legitimate mid-change state. |
| **5. state dir is ignored** | reads `state_dir` from the cartridge and asserts `git check-ignore` matches it, so the one `.gitignore` line protecting the journal — whose entry header identifies the machine — is a check rather than the bold reminder it used to be | **the rule, not the contents.** It says nothing about whether anything inside the state dir is already tracked, and nothing about a *different* uncommittable path. An unreadable cartridge or a missing `state_dir` key is a **FAIL**, not a skip: unknown must not read as ok. The query carries a trailing slash, because a directory-only rule matches a bare path only where the directory already exists — written the obvious way this check passes on a machine that has been running tracks for weeks and fails on every fresh clone. |
| **6. object store** | the **unreachable** objects in `.git/objects`: every blob's content **and every tree's filenames** are scanned against the same patterns through the same allowlist strip, and any hit not declared in [`scripts/object-store-baseline.txt`](../../scripts/object-store-baseline.txt) **fails**. `git add` writes a blob before a hook can refuse the commit, so a *refused* commit still leaves its content behind, and sections 1–5 read the working tree or the index and never looked | **unreachable objects only, and not commit objects.** Every commit header carries the committer's name and email, so a pattern list holding the author's name matches *every* commit and no check can tell that from a leak — the count of unscanned commits is printed rather than hidden. **A reflog keeps an abandoned commit reachable**, so residue from a recent `reset` or `amend` is invisible here until the reflog expires; this is the common case and it means a green section 6 is weakest immediately after the mistake. Reachable history is not scanned by any section — section 1 reads the current tree, not past commits, and the remedy for history is [the purge runbook](../runbooks/purge-a-leak-from-history.md). A fresh clone holds no unreachable objects, so there the section reads zero and **says so** rather than printing a bare ok. It cannot tell residue from work in progress either, which is why the baseline file carries the decision not to prune rather than the section carrying a prune. |

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
- [ADR 0001](../decisions/0001-library-is-the-source-of-truth.md) — which copy of the pack is
  the real one, and why
- [trackers.md](./trackers.md) and [stacks.md](./stacks.md) — extending the pack
- [the cartridge schema](../integration/cartridge-schema.md) — the keys, one by one
- [the concepts page](../product/overview.md) — what the pack is and why it is shaped this way
