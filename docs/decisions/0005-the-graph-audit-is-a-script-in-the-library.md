# 0005 — The graph audit is a script in the library, run by path

**Date:** 2026-11-03
**Status:** accepted
**Supersedes:** the rejected option *"Making the audit a script in the repo instead of an inline
block"* in [ADR 0004](0004-a-check-must-state-what-it-read.md), and part of the rejected option
*"A script shipped inside the library, travelling with the skill"* in
[ADR 0002](0002-publishing-is-a-guarded-copy-from-the-library.md) — see **What this overturns**.
**Builds on:** [ADR 0001](0001-library-is-the-source-of-truth.md),
[ADR 0002](0002-publishing-is-a-guarded-copy-from-the-library.md),
[ADR 0004](0004-a-check-must-state-what-it-read.md)

## Context

`ws-refine` ends by requiring a graph audit, and every pack change carries "changed through
`ws-refine`, with its graph audit" as an acceptance criterion. ADR 0004 is about that audit being
the one check whose own correctness is load-bearing for all the others.

Until 2026-11-03 it was a fenced bash block inside `ws-refine/SKILL.md`. **A skill's body has the
caller's argument substituted into its positional parameters on the way to the agent** — the
mechanism p7.1 measured and p8.35 fixed in two other skills. The audit's awk programs use `$0` as
a field reference, so invoked as `/ws-refine <anything>`, which is how every task in this project
invokes it, the delivered copy arrived with `if($0!="---")` rewritten to
`if(<a word from the argument>!="---")`. awk cannot parse that.

The two halves failed differently, and the asymmetry is the point:

- **Part 3** died loudly enough to survive: every skill got a spurious `FRONTMATTER` finding, and
  fourteen findings get investigated.
- **Part 3b** died silently. Its scanner produced nothing, its findings variable stayed empty, and
  the part reported **no findings** — while its per-file counter had already been incremented
  *before* the scan, so part 8's floor and its cross-check against part 3 both passed. A clean
  verdict over a scan that never happened, in the part added to catch exactly that shape.

**And the audit could not see this about itself.** Part 3b excluded `$0` deliberately, because a
fenced awk program uses it as a field reference. That exclusion was correct and it is what made
the blind spot structural rather than an oversight.

## Decision

**The audit is `ws-refine/audit.sh` in the library, run by path:**

```bash
bash "$HOME/.agent-sync/store/skills/ws-refine/audit.sh"
```

Nothing substitutes into a file read or run by path — the property reference pages already rely
on. Four details are decisions rather than style:

1. **In the library, not in this repo.** The audit's subject *is* the library. One absolute path
   resolves on every agent, so the skill needs no base-directory inference and there is never a
   question of which copy certified a change.
2. **`bash <path>`, never executed directly.** No execute bit has to survive a copy, a publish or
   a filesystem that does not carry one. (Measured: the deployed copies are `0644`.)
3. **Published with the pack**, by exact name through `publish.sh`'s `PACK_EXEC` list rather than
   by extension — so a second `.sh` appearing in a skill directory is still refused.
4. **The judgement stays in the skill.** What an *agent* must honour — that a verdict without its
   counts is not a verdict, that an `UNLISTED EXIT` is read and judged, that a finding in a file
   your change does not own is reported and not edited, which run certifies what, and what the
   seven checks are about — remains in `ws-refine/SKILL.md`. Only the shell moved.

Part 3b additionally **scans the whole file** now, prose and frontmatter included, and no longer
excludes `$0`. The substitution does not read Markdown, so every occurrence in a delivered body is
rewritten — which the fix's own first reviewer proved by invoking the skill and finding the
sentence *defining the rule* delivered with the caller's argument in place of its example.

## What this overturns, precisely

ADRs are immutable here, so this section says what is no longer true rather than editing them.

**ADR 0004** rejected *"a script in the repo instead of an inline block"* for two reasons. The
first — that the audit must run against the library, whose path belongs to one person's setup, so
a shipped script would carry that path into every published copy — **does not apply to the shape
taken here**: `$HOME/.agent-sync/store/skills` is agent-sync's own convention, not a personal
path, and `audit.sh` contains no hardcoded `/Users` or `/home` and no pattern from
`scripts/leak-patterns.txt` (both measured). The second was that ADR 0002's rejection applied
unchanged; see below. The literal option ADR 0004 names — a script in **this repo** — remains
rejected, and for its original reason: the audit would then live apart from what it audits.

**ADR 0002** rejected *"a script shipped inside the library"* for the **publisher**, on three
counts. Two of them never applied to the audit and one now binds it:

| ADR 0002's objection | Status for `audit.sh` |
|---|---|
| it would have to guess each target's guard, baking one artifact's conventions into a generic skill | **does not apply** — the audit reads the library and `agent-sync status`, and knows nothing about any publish target |
| it would add an executable to a pack of Markdown, whose mode bit's survival cannot be verified without running the deploy | **answered** — `bash <path>` needs no mode bit, and the deploy was run: `0644` under all three agents |
| it would be published *into the repo it publishes to*, so a bug in it ships to readers as part of the pack | **applies, and is accepted** — see below |

That third objection is the real cost of this decision and it is not dismissed. `audit.sh` is
published into the public repo, so a bug in it reaches every reader of the pack. What makes that
acceptable rather than merely tolerable: the file is guarded by the same `scripts/check.sh` as
every other published byte, it is listed by name on every publish run precisely because it is
code, and the alternative was an audit that could not be run as delivered — a bug shipping to
readers *and* to the author, silently, every time.

## Alternatives rejected

**`bash "<this skill's base directory>/audit.sh"`.** The harness does print that directory. But it
differs per agent, is absent in some clients, and would have an agent audit the library using a
copy that may be one `agent-sync save` behind the library it is auditing — reintroducing the
"which copy certified this?" ambiguity ADR 0004 exists to remove.

**Rewriting the awk to avoid `$0`.** There is no whole-record alias in awk, so this means
restructuring every program around implicit-`$0` regex matches and losing `printf … NR, $0`
entirely. It would fix three tokens and leave the class: the next executable line a skill body
ships is corrupted the same way, and part 3b would still have to exclude `$0` to avoid flagging
itself.

**`publish.sh --allow-extra` for the new file.** The flag exists for exactly this and is still
wrong: it lifts the refusal for *every* file in the run, so a stray `.env` in the same publish
would pass beside the file it was meant to allow. A named list of exact paths is the narrower
answer, and adding to it is a decision made once, in the open.

**A `*.sh` glob in `PACK_EXEC`.** Same failure one level down: a credential-bearing helper dropped
into the library would publish itself.

## Consequences

- **The pack is no longer Markdown-only.** `SECURITY.md` and `CONTRIBUTING.md` now say three
  scripts, and `docs/engineering/layout.md` names the file in the repo table.
- **Part 3b is stricter than the rule it enforces used to be.** Any positional parameter anywhere
  in a `SKILL.md` is a finding, including in prose and including `$0`. That is simpler code and a
  stronger rule, and it is what catches the next instance rather than this one.
- **A new blind spot, recorded rather than closed:** that an agent runs the file instead of
  reconstructing the block is not proved. The skill says to run the path and says why, and there
  is no longer a `$0` in the body to paste — but an agent running a stale **deployed** copy of
  `audit.sh` is caught by part 1 only when the library has moved. In
  [records/known-limitations.md](../records/known-limitations.md).
- **The compile probe's property is narrower than it reads.** It catches a program that fails to
  *parse*, which is the shape delivery produced; a substitution yielding a valid-but-wrong program
  would still pass. That gap is unreachable through the delivery channel now, because nothing
  substitutes into the file — which is the actual reason the fix works.
