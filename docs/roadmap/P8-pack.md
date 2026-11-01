# P8 — Pack improvements

**Goal:** fix what dogfooding and daily use have exposed in the pack itself.

**These are independent of publishing.** Every task here improves the author's own setup across
every project today, whether or not worksite ever ships. P8 can run before P2, and p8.2 probably
should.

## [x] p8.1 — Make every skill model-invocable · 2026-11-01 · @Alpha-30-creator

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
  - [x] all thirteen descriptions rewritten. **Not one of them said what the skill ends with** —
        the audit confirmed zero before, thirteen after. Each now states its end state (`ws-plan`
        "ends with an approved plan, never with code written"), and ten carry an explicit
        disclaimer naming the sibling that owns the adjacent case
  - [x] twelve collision-prone phrases checked, each now claimed by exactly one skill: "a workflow
        step felt wrong" → `ws-refine`, "too big or unclear" → `ws-task`, "fails for an unknown
        reason" → `ws-debug`, "whether something actually works" → `ws-verify`, "asked for a code
        review" → `ws-review`, and so on
  - [x] `ws-env`'s description named the author — a direct breach of the generic-means-generic
        rule added hours earlier in this same session, caught by checking rather than by reading.
        Now generic
  - [x] `ws-env` gains a gate: when it was **not** explicitly asked for, it runs `status` only —
        read-only, names and counts — and offers `pull`, `push` and `run` rather than performing
        them. Auto-decrypting credentials onto disk during an unrelated task is the one real
        hazard in making these automatic
  - [x] `ws-fanout` triggers only on explicit parallel intent, since it spawns up to five
        subagents and the cost is the user's
  - [x] `ws-ship` triggers only on explicit ship intent (description narrowed; the existing
        verify-passed and review-clean gates already read as refusals)
  - [~] **desk-verified, not live-verified.** The collision matrix proves each phrase is claimed
        by one description, and all thirteen reached all three agents (checked per agent, applying
        p8.9's lesson rather than trusting the library-only audit). What it does **not** prove is
        real trigger behaviour: that needs requests phrased naturally across sessions, and the
        author of the descriptions is the worst possible judge of whether they fire correctly.
        Observable in ordinary use from here
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

## [x] p8.2 — Teach review and planning where documentation belongs · 2026-11-01 · @Alpha-30-creator

- **Repos:** worksite (pack)
- **Acceptance:**
  - [x] check 7 split in two: *restates the code* stays a `Note`; *is really a document* is now
        **Should fix**; *contradicts the code* is **Must fix**
  - [x] **the severity table rewritten — this was the whole defect.** The `Note` row read
        "naming, comments, a simpler alternative. Never blocks", so every comment finding was
        unactionable by construction. The word "comments" is gone from that row
  - [x] new always-on pack `ws-shared/review/documentation.md`, wired into `ws-review`'s *always*
        column and listed in `ws-shared/reference.md`
  - [x] five detectors, each quotable rather than a matter of taste: time-relative claim, dated
        measurement, rejected alternative, system-fact-not-line-fact, self-duplication
  - [x] counter-rules stated as loudly as the detectors — structured API documentation belongs in
        the code, usage blocks stay, a durable one-line *why* stays, and a **missing** docstring
        on an exported public symbol is a finding in the other direction
  - [x] per-language table: Python, TS/JS, Go, SQL migrations, shell, config
  - [x] destinations named, so a finding is actionable: `engineering/`, an ADR in `decisions/`, a
        record in `records/`
  - [x] `ws-plan` step 11 changed from a list of destinations into a decision, carried as an
        acceptance criterion so `ws-verify` checks the writing shipped
  - [x] validated against three real specimens — see
        [records](../records/2026-11-01-documentation-pack-validation.md). The pass condition was
        **discrimination**: flag both offenders, leave a usage block alone, and not touch two
        exemplary docstrings. All three correct
  - [x] deployed to all three agents, `ws-refine` graph audit clean
  - [ ] **asserted, not verified:** the Go and Rust rows of the language table. No specimen
        existed in these projects to test against
  - [ ] **observable later:** whether step 11 actually changes planning behaviour. That needs a
        real task planned after this change, not an inspection
- **Notes:** the survey is what made this work. Planned from two files it would have become "write
  shorter comments", which the evidence disproves — the same two repos hold the two worst
  offenders *and* 682 exemplary docstrings, so any length or density rule would have destroyed the
  good ones and missed the actual defect.

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

## [ ] p8.5 — ws-fanout cannot isolate work that lives outside the project's repos

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** found by invoking `ws-fanout` on this project. Its safety gate offers exactly two
  options when `worktrees: false` — turn worktrees on, or fan out across **provably different
  repos** — and forbids inventing a third. Neither fits here, for a reason the gate does not
  model: most of worksite's open work edits the **agent-sync library**, which is not in the
  cartridge's `repos:` at all. So `worktrees: true` would isolate checkouts of this repo and do
  nothing whatsoever for the files actually being changed.
- **The sharper half:** `agent-sync save` is a single global operation — it validates, deploys to
  three agents, then commits and pushes the **whole** library. Two tracks editing the library
  cannot save independently: whichever saves first publishes the other's half-finished edits to
  every agent and pushes them. That is not a file collision, so worktrees would not catch it, and
  the shared-resource table in `ws-fanout` has no row for it.
- **Acceptance:**
  - [ ] `ws-fanout`'s gate gains a shared-store case: when a track edits anything outside the
        cartridge's `repos:`, worktrees do not isolate it and at most **one** such track may run
        per batch
  - [ ] the shared-resource table gains a row for a global deploy or publish command
  - [ ] the cartridge schema gets a way to declare a shared external store, so the gate can
        reason about it instead of a skill hardcoding the knowledge
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** the second finding produced by using the pack on itself, after p8.3. Both are the
  same shape — a rule that is right for the projects it was written against and silent for a
  project of a different shape.

## [x] p8.6 — worktrees defaulted to false · 2026-11-01 · @Alpha-30-creator

- **Repos:** worksite (pack)
- **Why:** `ws-setup`'s cartridge template shipped `worktrees: false  # opt-in`, so every project
  it generated started without isolation — while `ws-fanout`'s own gate treats `false` as the
  dangerous case that forces a refusal. The pack's default contradicted the pack's preference.
- **Acceptance:**
  - [x] template default is now `worktrees: true`, with an accurate comment: false only where the
        per-worktree dependency install is genuinely prohibitive
  - [x] no existing project is affected — their cartridges carry explicit values, so this changes
        new cartridges only. R5 holds without needing a flag
  - [x] this project's own cartridge flipped to `true`
- **Notes:** flipping it here does **not** make `ws-fanout` usable on worksite — see p8.5. Worth
  saying, so the two findings are not mistaken for one.

## [x] p8.7 — settings.json: the pack is not the cause · 2026-11-01 · @Alpha-30-creator

- **Repos:** worksite (pack)
- **Investigated** because agent settings files carrying permission allowlists kept appearing
  across the author's projects, and `ws-setup` was the suspect. **It is not.** No `ws-*` skill
  mentions `settings.json`, `settings.local.json` or a permissions list anywhere. Two unrelated
  causes:
  - **`settings.local.json`** — written by the agent itself whenever "always allow" is chosen.
    Globally gitignored via the user's own git ignore file, so it never reaches a repo. These
    reappear regardless of anything the pack does; they are a local cache of approvals, not
    configuration.
  - **One committed `.claude/settings.json`**, tracked in a frontend repo. A curated allowlist of
    the shape an automated "reduce permission prompts" tool produces — not this pack.
- **Acceptance:**
  - [x] confirmed by grep across all fourteen skills: zero references
  - [x] a defensive house rule added to `ws-shared`, so no future skill starts doing it: never
        write an agent's settings or permission files, in any project. Permission level is the
        user's own control, switched per task; a committed allowlist overrides that choice and
        rots
  - [ ] **remains to do:** delete the one committed `.claude/settings.json` from the frontend repo
        that carries it. That is a change to a product repo, so it ships through that project's
        own tracker — `ws-setup`'s rule is that setup never touches a repo's own files
- **Notes:** the useful half of this finding is the correction. Changing `ws-setup` would have
  fixed nothing; the house rule is prevention, not a cure.

## [ ] p8.8 — The journal mirror leaks the device name into a public docs home

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** found by the leak guard refusing a real commit. `tracks.md` defines the journal entry
  header as `<stage> · <date> · <device> · <handle>`, and mirrors the journal to
  `<docs_home>/journal/<track-id>.md` so a track can be resumed on another machine. When
  `docs_home` is **public**, that publishes the device name on every stage boundary — and a
  device name is commonly the owner's own name, which is exactly what the guard exists to stop.
- **The general shape:** `artifacts: workspace-state` plus a public `docs_home` is an unsafe
  combination, and nothing in the pack notices. The mirror is also the wrong thing to publish on
  its own merits: it is internal, ephemeral session state that `ws-ship` deletes, and it is noise
  to anyone reading the repo.
- **Acceptance:**
  - [ ] the cartridge schema gains a way to say the docs home is public — or `ws-setup` asks —
        and the loop skills do not mirror the journal when it is
  - [ ] `tracks.md` states the local-only consequence where it describes the mirror, next to the
        existing note about `lite` projects with no `docs_home`
  - [ ] the journal header uses a device **alias** rather than the raw device id, so a device
        named after its owner cannot reach a public repo through any other path
  - [ ] `ws-setup` warns when it generates a cartridge whose `docs_home` is inside a public repo
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** third finding from using the pack on itself, and the first one caught by a guard
  rather than by reading. Mitigated here by gitignoring the mirror, which costs this project
  cross-machine resume — acceptable for a solo repo, not a fix.

## [ ] p8.9 — The graph audit cannot see whether a referenced file reached each agent

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** found while shipping p8.2. `ws-refine`'s audit reported **clean** at the same moment
  `ws-review` on one agent referenced `review/documentation.md` and that file was **not present in
  that agent's deployment**. The audit resolves links *within the library*, where everything was
  correct; it never asks whether the deployed copy each agent actually reads contains the file.
- **Why it matters more than it sounds:** `ws-refine` already states the principle — "a broken
  link is silent at runtime; the agent reads nothing and carries on as if the rulebook said
  nothing". This is that exact failure, one layer below where the audit looks. A review would have
  run with the new pack silently absent and reported itself complete.
- **The trigger:** a deployment that was skipped because the artifact was `conflicted`, which
  `agent-sync save` reports but the audit does not read.
- **Acceptance:**
  - [ ] the audit checks the **deployed** copies, not only the library: for every file a skill
        references, confirm it exists under each agent this project deploys to
  - [ ] the audit fails loudly when `agent-sync status` shows any `ws-*` artifact conflicted or
        pending, rather than auditing a library that was never deployed
  - [ ] it reports per agent, since a file can reach two of three
  - [ ] changed through `ws-refine`
- **Notes:** fourth finding from using the pack on itself, and the second found by a check rather
  than by reading. Also worth noting as a cause: a manual `cp` into a deployed copy — done earlier
  in this session to resolve a conflict — is what made `agent-sync` treat the artifact as
  hand-edited and skip it thereafter. The real fix for that was deleting the deployed copy and
  letting it redeploy clean, which also re-recorded the hash correctly.

## [x] p8.10 — Cleanup exists on exactly one path, and nothing ever sweeps · 2026-11-01 · @Alpha-30-creator

- **Repos:** worksite (pack)
- **Depends on:** —
- **The rule is not missing.** `ws-ship` section 5 is thorough: it removes `tracks/<id>`,
  `tracks/current`, the journal mirror, and the worktree with `worktree remove` plus `prune`
  rather than a bare folder delete. So the observed symptom — task files surviving a completed
  task, especially under fanout — is not an absent rule. It is five ways the rule never runs.

- **Gap 1 — the fanout hand-off has no channel for the track id.** This is the structural one and
  it explains why fanout is where it shows. `ws-ship` learns which track it is on by reading
  `tracks/current`. `ws-fanout` forbids the lead from writing it — "Do not write `tracks/current`"
  in step 3, and "Never `tracks/current` from the lead" in its Rules — correctly, because the lead
  holds several tracks and none is current. But step 8 then says "Ship with `ws-ship`, one track at
  a time" **without saying how `ws-ship` is told which track**. So section 5's
  `rm -rf <state_dir>/tracks/<id>` has no `<id>` to substitute, and the cleanup silently does
  nothing or is skipped. The fix: `ws-ship` must accept an explicit track id, and `ws-fanout` must
  pass it.

- **Gap 2 — cleanup is late, and unverified.** It sits in section 5 of 6, after commit, PR and
  merge. Any question or failure earlier ends the session before it. And nothing checks that the
  deletion happened — a skipped `rm -rf` is silent, while the pack demands evidence for everything
  else ("verify every command you report as done").

- **Gap 3 — N tracks, one lead, no reconciliation.** A fanout batch leaves two to five track
  directories. Shipping "one at a time" means five separate cleanups, and nothing at the end asks
  whether any track directory remains for a task that is no longer open.

- **Gap 4 — cleanup exists only on the ship path.** A track that is claimed and then dropped, a
  batch abandoned, a task marked `[-]` by `ws-task` — none has a cleanup path at all. `ws-wrap`
  keeps the track deliberately and correctly, so "paused" is not the hole; **"ended without
  shipping" is**, and it has no owner.

- **Gap 5 — worktree removal is per repo, written as one line.** `ws-start` creates a worktree
  **per repo the task touches**; `ws-ship` shows a single `worktree remove`. A multi-repo track
  under-removes, and an abandoned one removes nothing, leaving git metadata behind that makes the
  next `worktree add` fail.

- **Acceptance:**
  - [x] `ws-ship` takes the track id explicitly, falling back to `tracks/current` only when no id
        is given; `ws-fanout` step 8 passes it per track. Written as a four-step resolution — id
        in the invocation → `current` → sole track dir, confirmed → ask — that **echoes what it
        resolved** and binds one `$id` for all eight `<id>` substitutions in the file
  - [x] cleanup is verified, not assumed: after deleting, confirm the path is gone and say so.
        One block, **silent on success** (`clean: track <id> removed`) and loud on failure
        (`NOT REMOVED: …` naming each survivor), plus a closing one-line ship report. The
        verification is only trustworthy because of two fixes the review round forced: the id
        guard, and newline-separated repo iteration (see Notes)
  - [x] worktree removal loops over every repo the track touched, and `worktree prune` runs once
        — **once per repo**, written as a second loop, because a single global prune leaves every
        other repo's metadata stale, which is the bug
  - [x] a cleanup path for a track that ends **without** shipping — dropped, abandoned, or a task
        marked `[-]` — owned by `ws-task` for a drop and `ws-fanout` for an abandoned batch. The
        drop path harvests a three-line worklog stub **before** retiring, so a dropped track's
        `rejected:` lines survive it
  - [x] a sweep that actually looks: `ws-start` or `ws-sync` reports track directories whose task
        is no longer open, and stale worktrees, and offers to remove them. **Reports and asks** —
        never discards, per the house rule. Hosted in `ws-start` steps 2/3, where the board fetch
        already has the ids; prints only when non-empty, one grouped question for the
        clearly-finished, never offers a track that is claimed or holds work
  - [x] `ws-fanout` step 8 reconciles at the end of a batch: no track directory left for a task
        that is closed, and one line per track saying shipped, wrapped or retired
  - [ ] changed through `ws-refine`, with its graph audit — **not done in the build**: the library
        edits are deployed once by the lead after review, so the audit runs there, per agent
- **Notes:** fifth finding from using the pack, and the first reported from the author's own use
  rather than found by a check. The shape is familiar by now: the rule is right, and the path that
  would execute it does not exist. Gap 1 alone is a small change and worth doing first.

  Two corrections the build made to the diagnosis, both deliberate:

  - **Gap 1 is not fanout-specific.** `ws-wrap` clears `tracks/current` on all three of its paths
    while keeping the track, so a track wrapped on Monday and shipped on Tuesday reaches `ws-ship`
    with no id source either; a compacted or restarted session is a third case. The resolution
    order in `ws-ship` is written for the general case, not the fanout one, and names the three.
  - **Gap 2's "cleanup is late" half was not fixed by reordering, on purpose.** Cleanup was
    already section 5 and marking done was 6, so cleanup was *already* a precondition in the
    written order; moving it before the merge would destroy the only cold-resume path if the merge
    failed. The real defect was entirely the unverified half. Instead the section was split into
    **5 Harvest / 6 Retire the track / 7 Mark it done**, with the tracker transition gated on
    retirement's verified line.

  **How the fix was verified the second time.** Composition and empty variables, not blocks in
  isolation: a two-repo fixture under a path containing a space, with bare remotes. Unset `$id`
  under `set -u`, empty `$id`, a worktree with an unpushed commit on a branch with **no**
  upstream, a worktree with an upstream and one unpushed commit, an uncommitted file, the
  multi-repo layout, the single-repo layout whose path ends at the id, and a neighbouring `p3.10`
  track that had to survive a `p3.1` retirement. Every block was extracted verbatim from the
  skill file and run under **bash**, not the zsh that hid the word-splitting bug.

  **The recurring shape, now six instances.** p8.3, p8.5, p8.8, p8.9, p8.10 and p8.10's own first
  build are all the same
  failure: a rule that is correct and a path that never executes it. The durable lesson, worth
  carrying into every review of this pack: **a rule with no executing path is indistinguishable
  from a missing rule — name the caller, and verify the call.** Recorded here rather than in a
  project's `risks/` because it is a pack-level pattern, not a project risk.

  **The review round, and what it caught.** The first build passed its checks and was still
  unsafe. Five blocking findings, all verified against the file text and all fixed:

  - **An `rm -rf "$state_dir/tracks/$id"` with no guard.** The retirement procedure was written as
    three fenced blocks; only the first assigned `id`, and an agent runs each fence in its own
    shell. Run alone, the removal block's target was `<state_dir>/tracks/` — every track on the
    machine, including claimed ones holding uncommitted work, which this very change exists to
    protect. Fixed by one composed block whose first line is
    `[ -n "$id" ] || { … exit 1; }`, and by saying in the section that it must be run whole.
  - **The task's own justification was false, and that is why the guard was missing.** Three
    sentences across `ws-ship` and `ws-fanout` said a missing id "silently removes nothing". It
    removes *everything*. All three now say an unresolved id is a **stop**.
  - **The "unpushed work is a refusal" check could not fire for the case it names.**
    `git log @{u}..HEAD 2>/dev/null` discards `fatal: no upstream configured`, so a branch whose
    commits exist nowhere else was indistinguishable from clean-and-pushed — and `worktree remove`
    does not refuse it either. Replaced with a separate, unsuppressed
    `rev-parse --symbolic-full-name '@{u}'` plus `rev-list --count`. **This was the p8.10 shape —
    a rule with no executing path — occurring inside the fix for p8.10**, which makes it the sixth
    instance of the pattern and the clearest evidence yet that the pattern is real.
  - **`for r in $repos` printed a false `clean`.** A workspace path containing a space splits in
    bash, every `git -C` fails on a fragment, no worktree is found, and the block reports success
    with the worktrees still present. Demonstrated: the same script prints `clean` under bash and
    `NOT REMOVED` under zsh. All four loops now read repo paths line by line. This is the mirror
    image of the zsh trap already recorded in the cartridge, and the more dangerous direction,
    because it reports success rather than failing.
  - **Variables consumed but never assigned** (`$wt`, `$wt_for_r`), and `| head` masking git's
    exit status throughout. Both gone: one composed block, explicit assignments, no `head`.

  Also fixed: a self-contradiction in the shared section (a step-5 survivor cannot "stop and ask",
  being found after removal), the orphan-worktree report that had no enumerating pass (it now has
  its own reverse pass: worktree ids minus track directories), and a sweep example whose table
  asserted `done`/`dropped` on a tracker that cannot prove either.

  One defect found while testing the written commands rather than reading them: matching a
  worktree by `grep` on the track id is wrong twice over — the dot in `p3.1` is a regex wildcard
  that matches a `p3.10` worktree, and `grep -F "/<id>/"` then misses the **single-repo** layout
  where the worktree path ends at the id with no `/<repo>` after it. Both give a wrong answer with
  no error. The procedure compares whole `/`-separated segments instead.

  The retirement sequence is written **once**, as *Retiring a track* in `ws-shared/tracks.md`;
  `ws-ship`, `ws-task`, `ws-fanout` and `ws-start` reference it by path rather than carrying four
  copies that would drift.

## [ ] p8.11 — `ws-wrap` clears `tracks/current` and says nothing about the id

- **Repos:** worksite (pack)
- **Depends on:** p8.10
- **Why:** found while building p8.10, and it is the non-fanout half of that task's gap 1.
  `ws-wrap` step 3 clears `tracks/current` on **all three** paths — keep, hand over and release —
  while deliberately keeping the track directory. So the next `ws-ship` on that track has no
  `current` to read. p8.10 made `ws-ship` resolve that case gracefully (it asks rather than
  cleaning up nothing), but `ws-wrap` still hands the user a track with no statement of how to
  ship it, and `ws-wrap` was outside p8.10's owned files.
- **Acceptance:**
  - [ ] `ws-wrap`'s Keep / Hand over / Release table says, once: a later `ws-ship` must be given
        the track id in the invocation, because `current` has been cleared
  - [ ] the resume note it writes carries the id in a form that can be pasted into `/ws-ship`
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** one sentence and a line in a template. Small, and it closes the last channel where a
  track is left with no id source.

## [ ] p8.12 — The tracker adapters cannot answer "what is the status of id X?"

- **Repos:** worksite (pack)
- **Depends on:** p8.10
- **Why:** `ws-start`'s stale sweep (p8.10) decides whether a track is finished by a set
  difference: an id **absent** from the adapter's open + claimed + blocked lists is treated as
  closed. That is exact for `roadmap-files` and `tasks-file`, which grep the status markers
  explicitly. It is **not** exact for `github-projects` and `trello`, whose list is
  status-filtered — `github-projects` defaults to the project's to-do equivalent — so an item
  merely moved to another status is absent too, and absence cannot distinguish done from dropped
  from "moved somewhere else" from "never existed". The sweep ships with that limitation stated in
  its own text and the question phrased as the weaker signal it is, which is correct but is
  wording standing in for a capability.
- **Acceptance:**
  - [ ] a fifth adapter question — `status <id>` — answered by all four adapters, returning the
        item's current state or "not found", distinguishing done from dropped
  - [ ] `ws-start`'s sweep prefers it where the adapter answers it, and keeps the set-difference
        approximation (with its stated caveat) only as the fallback
  - [ ] `ws-shared/trackers/README.md`'s four questions become five, and the adapter contract in
        the cartridge schema says so
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** deliberately **not** built with p8.10 — the adapters were outside that track's owned
  files, and keeping the sweep to data the skill had already fetched is what kept p8.10 inside its
  own file set. This is the follow-up that turns an approximation into a contract.

## [x] p8.10 — decision record: the show-and-wait carve-out was rejected · 2026-11-01

The build carved out `ws-ship` on the happy path: it would **state** what it was removing and
remove it, without a second yes, on the argument that the user had already said ship, the harvest
was committed, and one more prompt at the very end is where a session dies with the track still
on disk. The review flagged it as a flat contradiction with the house rule in `ws-shared`'s
reference — *show it, then wait for a yes before any commit, push, overwrite or delete* — and
noted that an agent reading both would resolve it either way.

**Decided by the user: it asks.** One confirmation before deleting track state, every caller, no
exception. Removed from all three places it was stated.

The reasoning behind the carve-out was real but points the wrong way: a track left on disk is
**visible and recoverable**, and the stale sweep this very task added now finds it. Session state
deleted without an answer is neither. Prefer the cheap failure.

Recorded here because the ADR folder is for decisions about the system's architecture and this is
a decision about its safety rules — but if a second safety-rule change comes up, it earns an ADR.

## [ ] p8.13 — `for r in <repos>` survives in three skills, including one that warns against it

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** p8.10 fixed the word-splitting loop inside the retirement block and documented why —
  a workspace path containing a space word-splits under `for`, every `git -C` fails, and the
  verification prints `clean` while the worktree is still there. **It reports success, which is
  why it is worse than a crash.** The fix did not reach the rest of the pack:
  - `ws-start` line 24 still has `for r in <repos>` while **line 102 of the same file warns
    against exactly that**. The clearest instance, and the one that proves the point.
  - `ws-plan` line 21 and `ws-review` line 86 have it too; neither was in p8.10's owned files.
  - `ws-sync` line 45 uses `for r in "$root"/*/`, which is glob-based and quoted — **not** a
    finding. Worth stating so nobody "fixes" it.
- **Acceptance:**
  - [ ] all three sites read repo paths line by line, as the retirement block does
  - [ ] each tested by execution under **bash**, against a fixture whose path contains a space —
        not by reading. Two rounds of review on p8.10 showed that reading these loops does not
        find the bug
  - [ ] the mirror-image warning added to the cross-platform table in `ws-shared`'s reference,
        which today documents only the zsh under-splitting trap and not this one
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** the **seventh** instance of the pack's recurring shape — a rule that exists with no
  path that executes it. Found by the lead's own grep after the review, which had declared it
  skimmed `ws-start` outside the diff hunks. A coverage gap honestly declared, not a miss.

## [ ] p8.14 — Nothing ever enumerates the track root, so a forgotten worktree is invisible

- **Repos:** worksite (pack)
- **Depends on:** p8.10
- **Why:** p8.10 added two sweep passes and both ask **git** what exists. Pass 1 walks
  `<state_dir>/tracks/` and asks `git worktree list` per repo. Pass 2 walks `git worktree list`
  and subtracts the track directories. Neither ever reads the **track root directory itself**, so
  a directory under `<project>-tracks/` that git has forgotten is enumerated by nothing. Pass 2's
  stated purpose is "the residue of a folder deleted by hand" — but git still *lists* such a
  worktree until it is pruned, which is what pass 2 catches. The reverse case, git pruned and the
  folder still on disk, has no pass at all.
- **Confirmed, not hypothetical:** on one of the author's own projects,
  `<project>-tracks/<id>/<repo>/dist` — 9.6M — with the task shipped and harvested four days
  earlier, its track directory gone, and all three repos' `worktree list` showing only their
  primary checkout. Both passes report nothing stale. It had survived every `ws-start` since.
- **The mechanism is now established — found by shipping the p3.1/p3.2/p6.1 batch.** `ws-start`
  creates the worktree at `<root>/<id>/<repo>`, so it creates the parent `<id>/` as a side effect.
  `git worktree remove` removes `<repo>`, which is the worktree; **nothing removes the parent.**
  Retiring all three tracks of that batch left `<root>/p3.1`, `<root>/p3.2` and `<root>/p6.1` on
  disk as empty shells, with git knowing of no worktrees and `.worksite/tracks/` empty — so both
  sweep passes reported nothing stale while three directories sat there. Benign while empty; that
  same shell is what a later build fills with gitignored output, which is the 9.6M case above. So
  the fix is two parts: the third pass below, and retirement removing the parent it leaves empty.
- **One candidate is ruled out, recorded so nobody re-derives it.** Tested: a clean
  `git worktree remove` deletes gitignored content along with the worktree, and refuses only on
  untracked files that are **not** ignored — so the documented removal path does not itself leave
  build output behind.
- **Acceptance:**
  - [ ] a third pass: list the entries of the track root, subtract both the live worktree ids and
        the track directories, and report what is left as a disk-only orphan, with its size —
        size is what makes it worth acting on
  - [ ] *Retiring a track* removes the parent `<id>/` directory when removing its last worktree
        leaves it empty — the cheaper half of this fix, and it stops the residue being created at
        all rather than only reporting it afterwards
  - [ ] a pass that cannot resolve the track root says so, rather than finding nothing silently.
        It depends on p8.15 for a root it can name
  - [ ] same asking rules as the other two passes: shown, never removed without a yes. A directory
        that still contains a working `.git` is **not** a disk-only orphan and is not offered
  - [ ] the sweep's own text states which of the three passes finds which residue, so the next
        person extending it can tell whether a case is covered
  - [ ] proven against fixtures, by execution: a worktree removed with `--force`, and one
        `rm -rf`'d then pruned. Reading the passes is what missed this
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** the **eighth** instance of the recurring shape, with a twist worth naming: here the
  rule and its executing path both exist, and the path cannot see the state. Asking git about
  residue git has forgotten is the precise failure. Second finding produced by explaining the
  pack's own layout rather than by running a check.

## [ ] p8.15 — The worktree root is a relative path with no defined base

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** `ws-start` creates worktrees with
  `git -C <repo> worktree add "../<project>-tracks/$id/<repo>"`. `git -C` changes directory first,
  so `../` is relative to **the repo**, which in a multi-repo workspace means
  `<workspace>/<project>-tracks/`. On one of the author's multi-repo projects the root is actually
  a **sibling of the workspace** — what you get resolving `../` from the workspace root instead.
  The literal appears in seven places across `ws-start` and `ws-shared/tracks.md`, and no line in
  the pack says what it is relative to, so both readings are defensible and two agents on one
  project can create two roots.
- **Why it stayed invisible:** every consumer re-derives paths from `git worktree list`, which
  returns absolute paths, so retirement and both sweep passes work under either reading. What
  breaks is anything needing the root as a **place**: the `- Worktrees:` line in `task.md`, whose
  reader is a cold session with no cwd; the `root="<project>-tracks"` segment match in the sweep's
  awk, which matches that name under any parent and so cannot tell two roots apart; and p8.14's
  disk pass, which cannot list a directory it cannot name.
- **Acceptance:**
  - [ ] the worktree root becomes a cartridge key with a stated default, resolved to an absolute
        path once per session — one definition, not seven literals
  - [ ] `task.md`'s `- Worktrees:` line records absolute paths
  - [ ] every site that writes or names the root reads the resolved value
  - [ ] `ws-setup` writes the key, and states where the root lands in the **single-repo** case,
        where it is necessarily outside the workspace and cannot be otherwise
  - [ ] a project with an existing root under the other reading is detected and reported, rather
        than a second root being created beside it
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** **not** the usual shape, and recorded for that reason. This is an under-specified
  value rather than a rule with no executor — the pack never decided the thing, and git's absolute
  paths hid the consequence. The defects dogfooding finds are not all one kind.

## [ ] p8.16 — Inside a git repo, the state dir rests on one gitignore line nothing re-asserts

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** state is normally uncommittable **by construction** — the workspace root is not a git
  repo, so there is nothing to commit it to. In the **single-repo layout**, which the pack
  supports, the root *is* the repo and that structural guarantee is replaced by a line in
  `.gitignore`. `ws-setup` adds it once at setup; nothing ever checks it is still there. So the
  pack's strongest safety property degrades, on a supported layout, to someone remembering —
  the exact pattern `ws-shared/tracks.md` rejects when it argues for the journal.
- **What it costs if the line goes:** `<state_dir>/tracks/<id>/` holds `task.md`, `plan.md`,
  `journal.md` and `verify/`. The journal format embeds the device name (p8.8), so on a public
  repo this is a leak, not untidiness. **This repo is that case**, and its cartridge says *"Do not
  remove that line"* in bold — a bold reminder standing in for a check the pack would demand
  anywhere else.
- **Acceptance:**
  - [ ] when `state_dir` is inside a git repo, something asserts the ignore rule instead of
        trusting it. `git check-ignore -q <state_dir>` is the whole test
  - [ ] it runs where it is seen before damage: the project's own `verify` where there is one,
        `ws-start` otherwise
  - [ ] `ws-setup` states the fragility when it generates this layout, rather than adding the line
        silently
  - [ ] `scripts/check.sh` in this repo gains it, as the first consumer
  - [ ] proven by deleting the line and watching the check fail — not by reading it
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** smallest of the three and the only one with a one-line test. The cartridge's bold
  warning **is** the finding: the pack already knew the risk and wrote a reminder instead of a
  check.

## [ ] p8.17 — `docs_home` doubles in four sites, and `ws-fanout` silently takes the unsafe branch

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** 27 sites across 13 skills read `docs_home` as the agent directory itself — so it ends
  `/agent`. Four read `<docs_home>/agent/...`, so it does not: `ws-fanout`:32, :136, :192 and
  `ws-shared/tracks.md`:108, which contradicts **itself** against `tracks.md`:72. p3.1's schema page
  states the dominant form and names the contradiction; this task fixes the four.
- **It is live, not theoretical, and the failure direction is the bad one.** On this project's own
  `docs_home: docs/agent`, `ws-fanout`:32 greps `docs/agent/agent/reference.md`, which does not
  exist. The grep finds nothing, so the isolation gate reads `worktrees` as **absent** and takes the
  `false` branch — the one that shares a single working tree between parallel builders. It was only
  harmless on the p3.1/p3.2/p6.1 batch because the lead read the cartridge directly instead of
  through that grep.
- **Acceptance:**
  - [ ] the four sites read the dominant form; `tracks.md` no longer contradicts itself
  - [ ] `ws-fanout`'s isolation gate distinguishes "`worktrees` is absent or false" from "the
        cartridge could not be read at all", and the second is a **stop**, not the `false` branch.
        A gate that cannot find its input must not silently choose the unsafe answer
  - [ ] p3.1's gap 13 updated or closed to match what the pack then does
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** found by p3.1's blind reader, which wrote `docs_home: docs/agent` from the page and
  produced a path that resolves nowhere. The documentation task surfaced a pack defect, which is the
  argument for writing schemas down.

## [ ] p8.18 — Two rules in `tracks.md` rest on wrong premises

- **Repos:** worksite (pack)
- **Depends on:** p8.10
- **Why:** both were found by *using* the retirement path, not by reading it, and both state a
  reason that is not true.
- **The no-upstream refusal tests a proxy.** *Retiring a track* refuses a worktree whose branch has
  no upstream, on the stated grounds that "those commits exist nowhere else". p6.1's library branch
  was merged locally into `main` and pushed via `main`, so it had no upstream of its own while both
  its commits were reachable from `origin/main`. The guard therefore refuses safe work, and the
  operator's only escape is to override a safety check — which is how a check becomes routinely
  bypassed. The property it wants is reachability from any remote-tracking ref.
- **The `in-repo` mirror exemption rests on a false premise.** `tracks.md`:76 exempts
  `artifacts: in-repo` projects from the journal mirror because "the task branch already carries the
  files". p3.1 established that `in-repo` relocates **the plan, and only the plan** — the journal
  stays ephemeral workspace state and is deleted at ship whatever `artifacts` says. So the branch
  carries the plan, not the journal, and an `in-repo` project is exempted from the mirror while
  having no way at all to carry its journal between machines.
- **Acceptance:**
  - [ ] the refusal tests whether HEAD is reachable from a remote-tracking ref, and still refuses
        when it is not; the message says which ref proved it
  - [ ] the `in-repo` exemption is either corrected (mirror the journal anyway) or kept with the
        real consequence stated — an `in-repo` project's journal does not travel
  - [ ] every caller of *Retiring a track* still reads one definition, not a copy
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** the second item is a **cross-track** finding: p3.2 quoted the pack faithfully and p3.1
  documented the mechanism faithfully, and only the two together show the pack wrong. Neither
  reviewer could have seen it from one track.

## [ ] p8.19 — The cartridge cannot hold what the pack already asks for

- **Repos:** worksite (pack)
- **Depends on:** p3.1
- **Why:** p3.1's ledger found five things the pack reads, collects or names with **no key to land
  in**. Each one is a question an agent asks every time, or a value nobody can record.
- `ws-setup`:58-59 interviews for a one-line project description and a rule-skill prefix, and
  neither has a key. `ws-fanout`:192 then briefs builders to read `<prefix>-<area>` skills — so the
  prefix is load-bearing for a skill that cannot look it up.
- `merge_style` is read at `ws-ship`:85 and written by no template, so **every project is in the
  missing case** and the fallback is the key's only behaviour.
- `repos[].role` enumerates six values at `ws-setup`:60-61 and is consumed nowhere.
- Collaborators live in `<state_dir>/me`, which is local and uncommitted, so "two people work on
  this project" is unrecordable — confirmed by a blind reader who had to put it in prose.
- **Acceptance:**
  - [ ] each of the five is resolved **in one direction and stated**: given a key, or removed, or
        documented as deliberately out of scope with the reason. No silent third option
  - [ ] `merge_style` specifically: added to `ws-setup`'s template with a value set, or `ws-ship`
        stops naming it — a key that only ever falls back is worse than no key
  - [ ] p3.1's affected gap rows updated or closed to match
  - [ ] changed through `ws-refine`, with its graph audit

## [ ] p8.20 — Keys that exist but cannot express the ordinary shape

- **Repos:** worksite (pack)
- **Depends on:** p3.1
- **Why:** distinct from p8.19 and worse. These keys exist and their documented contract **excludes
  the values a writer most wants to set**, so an author invents schema and is never told it was
  ignored.
- **`tracker.lists` holds two lists and only two** — open and in progress. A three-list Trello board
  is the ordinary shape, and the adapter asks where a finished card goes **every task, forever**,
  with no way to pre-answer it. A blind reader invented `done:` relying on unknown-keys-are-ignored
  and expected it to do nothing. Called the sharpest authoring gap on the schema page.
- **`tracker.statuses` has no documented shape** — the page declares it schema-less.
- **`house_rules.owned_by` is `me | company`**, which does not cover a small team that collectively
  authors its own rules; and an absent or `TODO:` value degrades to `me`, the **permissive** branch,
  so `ws-refine` proposes rule changes it may not be entitled to, with no error and no prompt.
- **There is no way to say "this command exists, do not run it"** — `null` means the repo does not
  have it, which is a different claim.
- **Acceptance:**
  - [ ] `tracker.lists` accepts the finished-card list, or the trello adapter states in its own text
        that it cannot and will ask every time
  - [ ] `owned_by` covers the small-team case, and its permissive degrade is either reversed or
        warned about where it is read
  - [ ] a documented way to express a command that exists and must not be run, or a stated decision
        that the pack will not model it
  - [ ] `tracker.statuses` gets a shape or is removed
  - [ ] changed through `ws-refine`, with its graph audit

## [ ] p8.21 — `machine:` has no merge semantics and no reader

- **Repos:** worksite (pack)
- **Depends on:** p3.1
- **Why:** the key is named and keyed off `device.yaml`'s `device:` id
  (`ws-shared/reference.md`:77, 188), but **no skill is documented as applying a device block over
  the top-level keys**. p3.1 refused to invent a merge rule and documented the only dependable use
  as a free-text `note:`. So the cartridge advertises per-device configuration and delivers a
  comment field.
- **Acceptance:**
  - [ ] decided either way and written down: `machine:` merges over the top-level keys, with the
        rule stated and a skill that applies it — or it carries notes only, and says so where it is
        documented so nobody writes `machine.<device>.repos[].dir` and gets silence
  - [ ] if it merges: which keys may be overridden, and what happens to a list or a map
  - [ ] p3.1's gap updated or closed
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** a blind reader's brief asked for a per-device repo path and the schema page **stopped it
  writing one**, correctly, because workspace paths resolve from `device.yaml`. That is the page
  working; the key still promises more than it does.

## [ ] p8.22 — `lite` and the tracker: two files disagree

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** `ws-setup`:54 says a `lite` profile gets no tracker; `ws-shared/trackers/tasks-file.md`:3
  calls itself the `lite` default. An outright contradiction, found by p3.1's ledger. The schema page
  resolves it in favour of "a tracker key on a `lite` cartridge is read exactly like any other" and
  records the disagreement as a gap.
- **Acceptance:**
  - [ ] one of the two sentences changes; the pack says one thing about `lite` and trackers
  - [ ] p3.1's gap updated or closed
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** small, and the kind of thing that costs an agent a wrong decision rather than an error.
