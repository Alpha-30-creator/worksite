# P8 — Pack improvements

**Goal:** fix what dogfooding and daily use have exposed in the pack itself.

**These are independent of publishing.** Every task here improves the author's own setup across
every project today, whether or not worksite ever ships. P8 can run before P2, and p8.2 probably
should.

## [~] p8.1 — Make every skill model-invocable @Alpha-30-creator · 2026-11-01

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** all fourteen skills carry `disable-model-invocation: true`, so the loop runs only when
  the user remembers to type the command. The pack's own journal rule is that anything depending
  on someone remembering is not there when it matters — and that applies to the loop itself.
- **Acceptance:**
  - [x] `disable-model-invocation` removed from the **thirteen workflow skills**, deployed to
        all three agents. `ws-shared` keeps the flag: it is a reference pack read by path, not
        invoked, so making it invocable would add a competitor to the trigger space with nothing
        behind it. `ws-refine` now says so, or the next agent strips it again
  - [ ] descriptions tuned so they do not compete: `ws-plan`, `ws-task` and `ws-refine` all
        plausibly match "this is wrong", and today only the typed command disambiguates them.
        Each description names what it ends with, not just when to use it
  - [x] `ws-env` gains a gate: when it was **not** explicitly asked for, it runs `status` only —
        read-only, names and counts — and offers `pull`, `push` and `run` rather than performing
        them. Auto-decrypting credentials onto disk during an unrelated task is the one real
        hazard in making these automatic
  - [x] `ws-fanout` triggers only on explicit parallel intent, since it spawns up to five
        subagents and the cost is the user's
  - [x] `ws-ship` triggers only on explicit ship intent (description narrowed; the existing
        verify-passed and review-clean gates already read as refusals)
  - [ ] tested by phrasing a request for each skill naturally, without the command, and checking
        the right one loads and the wrong ones do not
  - [x] `ws-refine` no longer **mandates** the flag — its frontmatter rule required
        `disable-model-invocation: true` on every workflow skill, so without this the next skill
        it wrote would have re-added it. Replaced with the rule that a description must say what
        the skill *ends with*, plus a rule that expensive or outward-facing skills narrow their
        own trigger
  - [x] `ws-refine` gained **generic means generic, permanently**: no generic skill, review pack
        or tracker adapter may name a real project, repo, person, device or path — because the
        library publishes to the public repo as a plain copy, so a private name breaks publishing
        rather than merely reading badly
  - [x] `ws-refine` gained the third clause on which copy to edit: the public repo is a published
        artifact, never edited directly
- **Notes:** this is not a one-line flip in fourteen files. Removing the flag is five minutes;
  making fourteen descriptions trigger correctly and not collide is the actual work.

## [ ] p8.2 — Teach review and planning where documentation belongs

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** code in the author's projects carries comments far longer and more detailed than they
  should be — explanations of architecture and rationale sitting in source files, where they rot
  and where nobody not reading that exact file will ever find them. Review never catches it, and
  the cause is specific: **`tier1-universal.md` check 7 does cover comments, but the severity
  table files comments under `Note`, which "never blocks".** The rule exists and is declawed.
  Check 9 only fires when a change alters how something is built, run, used or released, so a
  thirty-line design essay in a source file trips nothing at all.
- **Acceptance:**
  - [ ] check 7 split in two: *a comment restating the code* stays a `Note`; *a comment that is
        really a document* becomes **Should fix**, because it hides knowledge and goes stale
  - [ ] a new always-on pack `ws-shared/review/documentation.md`, drawing the line explicitly:
        **structured API documentation belongs in the code** (Python docstrings, TSDoc/JSDoc on
        exported symbols, Go doc comments on exported identifiers — tooling reads these and the
        reader is at the call site); **narrative belongs in the docs** (why the subsystem is
        shaped this way, what was rejected, how the pieces fit)
  - [ ] the pack is language-aware: a per-language table of what is idiomatic in code versus
        what is misplaced. "Fewer comments" is the wrong rule — a missing docstring on a public
        Python function is a finding in the other direction
  - [ ] destinations named, so a finding is actionable rather than a complaint: `engineering/`
        for how it is built, `decisions/` for an ADR when a choice was made and alternatives
        rejected, `integration/` when the comment is really describing a contract
  - [ ] a comment that contradicts the code is **Must fix**, not a Note — it is a lie about
        behaviour and worse than no comment
  - [ ] `ws-plan` step 11 ("Docs impact") changes from a list of destinations into a decision:
        name the narrative this change produces and where it will live, and carry it as an
        acceptance criterion so `ws-verify` checks it actually shipped
  - [ ] validated against a real recent diff from one of the author's projects: the new rules
        must flag the over-detailed comments that exist today, and must not flag legitimate
        docstrings
- **Notes:** the highest-value task on any phase, because it improves every project immediately
  and compounds. Severity is the crux — a rule filed under "never blocks" produces no change in
  behaviour, which is exactly what has happened so far.

## [ ] p8.3 — Close the ws-setup profile gap

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** `ws-setup`'s mode table sends "an empty or near-empty folder" to **new** and offers
  **lite** only for "one repo, throwaway or experimental". A long-lived single-repo project is
  neither, so it falls through to the full profile with nobody being asked — which is how this
  repo acquired fifteen placeholder files for content that does not exist. The skill does say
  "offer lite whenever it fits"; nothing makes that happen.
- **Acceptance:**
  - [ ] profile is chosen by a question the user actually answers, not inferred from folder shape
  - [ ] a third profile, or an explicit rule, for the long-lived single-repo case: tracker and
        cartridge yes, the full docs tree no
  - [ ] the generator creates a docs folder **when there is something to put in it**, matching
        the pack's own living-docs rule, instead of seeding empty folders with READMEs
  - [ ] changed through `ws-refine`, with the graph audit it requires
- **Notes:** found by using the pack on itself. Worth recording as the first such finding.

## [ ] p8.4 — Prove the pack copes with setups it was not written against

- **Repos:** worksite (pack)
- **Depends on:** p8.1
- **Why:** every stack pack, tracker adapter and house rule was written against a handful of the
  author's own projects. The degrade-never-fail rule is asserted everywhere and tested nowhere.
- **Acceptance:**
  - [ ] the loop run on a repo whose stack has **no** pack at all — tiers 1 and 3 must still
        produce a usable review, and the missing pack must be reported, not silently skipped
  - [ ] run with **no cartridge**: `ws-review` must ask its three questions and continue;
        `ws-env` and `ws-sync` must work from the device file alone
  - [ ] run against a tracker kind with no adapter — the four questions must get asked and a new
        adapter written, with no skill edited
  - [ ] run on a repo with no test runner, and on one with no git remote
  - [ ] run on a monorepo, which the `repos:` list assumes does not exist
  - [ ] each gap found becomes a fix or a stated limitation in the docs. A gap recorded as a note
        to self does not count
- **Notes:** distinct from p7.1. That one asks whether a stranger can install it; this asks
  whether the pack is honest about the projects it claims to handle.
