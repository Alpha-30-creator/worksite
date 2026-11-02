# 0004 — A self-checking check may certify only what it has stated it read

**Date:** 2026-11-02
**Status:** accepted
**Supersedes:** —
**Builds on:** [ADR 0001](0001-library-is-the-source-of-truth.md), [ADR 0002](0002-publishing-is-a-guarded-copy-from-the-library.md)

## Context

`ws-refine` ends with a graph audit, and every change to the pack is required to run it. That
makes it the one check whose own correctness is load-bearing for all the others: a pack change is
certified by this block and by nothing else.

Until 2026-11-02 the block opened with a bare `cd ~/.agent-sync/store/skills` whose result was
never read, and the three loops that followed were the whole audit. Measured rather than reasoned
about, that shape failed two ways, and **both of them read as success**:

- **With the `cd` failed**, the loops ran over an unexpanded `ws-*/` glob. Stdout carried two
  findings — `NAME MISMATCH: ws-* ->` and `DESCRIPTION PROBLEM: ws-* (0)` — and stderr four
  `sed`/`grep` errors. Both findings are meaningless, and two meaningless findings read as noise
  to dismiss rather than as *I audited nothing*. The task body first said the block "prints
  nothing" and was then corrected to "one line"; both were wrong, and the measured count of two is
  recorded in `7ab718a`.
- **With the `cd` failed and the shell left in the repo's `skills/`** — which is where an agent
  working on a published copy of the pack plausibly already is — the same block enumerated all
  fourteen published skills, resolved every link, and reported **clean, exit 0**. It audited the
  **published artifact** while believing it had audited the library. That is
  [ADR 0001](0001-library-is-the-source-of-truth.md)'s entire failure mode, signed off green, by
  the check that exists to prevent it.

The second is the sharper one and it is not hypothetical: it was reproduced twice independently,
once from the fixture trail and once by hand, before this ADR was written.

The general shape, written down once as entry 15 of the pack's universal review checks — in the
**library** copy of `tier1-universal.md`, which is the one agents load. The
[received copy in this repo](../../skills/ws-shared/review/tier1-universal.md) ends at entry 14
until a publish carries the change across, and keeping those two copies distinct is what
[ADR 0001](0001-library-is-the-source-of-truth.md) is for. The shape: where a check greps, globs,
parses or queries for a condition, a missing input, an unreadable one, an empty glob and a failed
call all return the same nothing as a real negative — and the branch that nothing falls to is the
permissive one.

## Decision

**A check may certify only what it has stated it read, and the statement is part of the output.**

Concretely, for the graph audit:

0. **Every count in the verdict is earned, not defaulted.** Each part carries a denominator — how
   many files it parsed, how many names it resolved, how many it both checked and actually scanned
   — and the verdict is unreachable unless each is positive and consistent with its neighbours.
   This is the general form of the decision; the rest are instances of it. The reason it has to be
   mechanical is that a part which read nothing leaves its findings variable **empty**, and empty
   is the same text as "no findings".
1. **It states its subject before its verdict.** The block prints `auditing N skills under <path>`
   and one `deployed check:` line per agent, and the skill's prose carries the half no shell can
   enforce: **a verdict without those counts is not a verdict.** An audit that printed neither has
   not run, whatever else it printed — including findings, and including nothing at all.
2. **Identity, not a count.** The subject is asserted to be the library by comparing the resolved
   working directory against the store path `agent-sync` itself reports, not against the string the
   block just used to `cd`. Comparing that string with itself is a tautology that passes wherever
   the `cd` landed.
3. **A marker and a floor, because identity is not sufficient either.** Identity catches the wrong
   directory; a readable `ws-shared/SKILL.md` and a floor of ten readable `ws-*/SKILL.md` catch the
   *right* directory holding the *wrong* contents — a gutted or half-deleted store, which identity
   passes. The floor is "the pack, not a fragment" and deliberately not today's exact count, which
   would turn the audit into bookkeeping and fail it on any intended addition.
4. **Readable, not merely present.** The count tests `-r`, not `-f`, so a mode-`000` `SKILL.md` is
   excluded from the count rather than silently counted as audited.
5. **It refuses to audit a library that was never deployed.** The state of a `ws-*` artifact is
   read from `agent-sync status --json` → `operations[]` filtered to refs beginning `skill/ws-`,
   and `reason` is the state. Any such operation aborts the audit.
6. **The pre-deploy abort is correct behaviour, not a defect to work around.** Between an edit and
   `agent-sync save` the artifacts are necessarily `outdated`, so the audit aborts. The run that
   certifies a change is the one *after* the save, which is also the only one that can answer the
   per-agent question truthfully. Running it twice is the design.

## Rejected

**`cd … || exit`, and nothing more.** The obvious fix, what the task's own wording asked for, and
the one this decision exists to refuse. It catches the case where the library is absent and misses
the case that actually happens: a `cd` that fails and leaves the shell somewhere that *looks* like
the pack. Measured, from the repo's `skills/`, the old block found fourteen skills, resolved every
link and reported clean — a plausible count, a clean verdict, and the wrong directory. A guard that
only catches the empty case certifies the published artifact and calls it the library. **This is
the alternative that was tried and disproved, and it is recorded here because a pull request keeps
no rejected alternative.**

**A count floor alone.** Strictly better than the above, and still insufficient for the same
reason: fourteen is a passing count. It catches an absent library and an empty directory and waves
through the published artifact, which is the realistic failure.

**Reading `ok` or `exitCode` from `agent-sync status`.** Rejected on verified output, not on taste.
`ok` is `true` while artifacts are drifted — it means "the command ran". `exitCode` counts only
`ask` operations, which makes it unusable in both directions: it is non-zero when unrelated
artifacts have drifted, so a gate keyed on it would abort every `ws-*` audit for reasons that have
nothing to do with `ws-*`; and it is `0` while an `outdated` `ws-*` write is pending, which is
exactly the state between an edit and the save. `targets[]` was rejected too: its rows carry no
state field at all, so a state read from there is empty on every row and reads as "nothing wrong".
A past change in this repo was burned by reading a `healthy` field that `doctor --json` does not
emit; these three are the same mistake with fields that do exist.

**Making the audit a script in the repo instead of an inline block.**
[ADR 0002](0002-publishing-is-a-guarded-copy-from-the-library.md) rejected exactly this for the
publish step, and that argument — an exit code in a file is not adaptable, prose is — is the
strongest case against the decision taken here. It is not taken, for two reasons that are specific
rather than stylistic. The audit must run against the **library**, whose path belongs to one
person's setup, so a script shipped inside the pack would carry that path into every published copy
of it; and ADR 0002's own rejection of "a script shipped inside the library" applies unchanged.
Recorded so the next reader does not re-propose it as new.

**Making the reverse coverage check a hard failure.** Its measured precision is two true positives
in three findings on the pack as it stands. A hard failure at that rate blocks a legitimate change
roughly once per pack-wide run, and a gate people learn to step over is worse than one that
reports. It prints `UNLISTED EXIT` and the prose requires each finding to be read and judged.

**A flag defaulting to today's behaviour**, per the pack's own rule that new behaviour arrives
behind one. Rejected because today's behaviour *is* the defect and a flag would preserve it. The
degrade-never-fail rule still holds: a readable library with everything deployed behaves exactly as
before, only louder.

## Consequences

- **The audit now has two outcomes that are not "pass" and "fail": it also has "aborted".** An
  abort is not a finding about the change; it is the audit declining to have an opinion. Anyone
  reading a report has to tell the three apart, which is why the verdict line names its counts.
- **The fix reproduced the defect three times before it stopped**, which is the strongest evidence
  this ADR is about a real pattern and not a one-off bug. First the per-agent check printed a zero
  at exit 0 when it had not run. Then review found the reverse-coverage check incrementing a
  "checked" counter off a *different* variable from the one it scanned, so a file whose frontmatter
  never closed was **actively certified** as checked while contributing nothing — worse than
  silence, because it was a false positive claim rather than an absent one. Then, while closing
  that, a new variable collided with the one holding the deployment JSON and emptied a later
  part's input. Each was found by the assertion added for the previous one. **The pattern is not
  "this check had a bug"; it is that a check composed of parts which cannot fail the whole will
  default to reassuring output at every seam.**
- **The fix reproduced the defect once, and the shape of that is the argument for this ADR.** The
  per-agent check runs inside a command substitution, so a `SystemExit` in it ends that subshell
  and not the audit. Review found that a dead check therefore left the verdict printing
  `0 missing under an agent` at exit 0 — a zero produced by a check that did not run, which is this
  task's own sentence inside this task's own fix. It is closed in shell, by asserting the check's
  output line was printed before the verdict is allowed to count it. The lesson generalises past
  this block: **a check that cannot fail the thing it reports into must assert its own output**,
  because "no findings" and "no run" are the same text otherwise.
- **The first run of the new audit over its own source happens under the new audit.** There is no
  way around that for a check living inside the thing it checks. The regress is closed by fixtures
  **independent of the library** — a failed `cd`, the published artifact, a gutted store, a
  mode-`000` skill, synthetic `conflicted` and `outdated` states, a file removed from one agent's
  tree only — and not by the live run. Stated rather than implied.
- **That an agent *obeys* an `AUDIT ABORTED` line is not proved.** The deliverable is wording plus
  shell; the shell makes the abort unavoidable within the snippet, and the claim is only that a
  clean verdict is now unreachable without the counts being printed. The same honesty
  [ADR 0002](0002-publishing-is-a-guarded-copy-from-the-library.md) applies to its own publish step.
- **The identity assertion shadows the marker and the floor on any wrong directory**, so those two
  can only ever fire on the real library path. They are not dead code — they catch a different
  failure — but any fixture for them has to satisfy identity by construction, which is a cost paid
  by whoever tests this next.
- **The audit now depends on `agent-sync` being runnable.** If it is not, the audit aborts rather
  than proceeding. That is the intended direction, and it makes the audit unavailable on a machine
  with no deployment rather than quietly narrower there.
