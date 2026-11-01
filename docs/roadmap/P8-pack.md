# P8 — Pack defects

**Goal:** fix the defects dogfooding has exposed in the pack itself — specifically the ones where
something **reports success while doing the wrong thing**: a gate that reads silence as a pass, a
loop that prints `clean` with the work still there, a key that is read and never written. Not
improvements. A change that would merely be nicer does not belong here; it belongs in the pack's
own backlog or nowhere.

**Retitled and trimmed 2026-11-02** by the owner after an independent audit: 23 open tasks here
became seven, the rest merged, dropped, or replaced by one sentence in
[`records/known-limitations.md`](../records/known-limitations.md). Every dropped body is kept —
the reasoning is the value and it cost real sessions to find.

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
  - [~] **kept partial 2026-11-02: this is a boundary, not work**, and it is recorded as the last
        of the eleven entries in [`records/known-limitations.md`](../records/known-limitations.md)
        — the pack's gates are desk-verified, not live-verified. Original text follows.
        **Desk-verified, not live-verified.** The collision matrix proves each phrase is claimed
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
  - [~] **kept partial 2026-11-02:** asserted, not verified — the Go and Rust rows of the
        language table. No specimen existed in these projects to test against, and none has
        appeared since, so this is a stated boundary of the pack rather than an open item: the
        rows are usable and unproven
  - [~] **kept partial 2026-11-02:** observable later — whether step 11 actually changes planning
        behaviour. That needs a real task planned after this change, not an inspection, which is
        the desk-verified-not-live-verified boundary in
        [`records/known-limitations.md`](../records/known-limitations.md)
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

## [-] p8.4 — Prove the pack copes with setups it was not written against — absorbed into p7.1 and p8.24

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. Its two cheapest cases — run with no cartridge, and run
against a tracker kind with no adapter — are now criteria of **p7.1**, which stands up the
throwaway project they need. The class the rest of it was really testing, a check that cannot
tell "read it, the answer is no" from "could not read it", is **p8.24**.

## [x] p8.5 — ws-fanout cannot isolate work that lives outside the project's repos · 2026-11-02 · @Alpha-30-creator · https://github.com/Alpha-30-creator/worksite/pull/9

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
  - [x] `ws-fanout`'s gate gains a shared-store case: when a track edits anything outside the
        cartridge's `repos:`, worktrees do not isolate it and at most **one** such track may run
        per batch
  - [x] the shared-resource table gains a row for a global deploy or publish command
  - [x] the cartridge schema gets a way to declare a shared external store, so the gate can
        reason about it instead of a skill hardcoding the knowledge
  - [x] changed through `ws-refine`, with its graph audit
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
  - [ ] **remains to do, and deliberately not tracked here (noted 2026-11-02):** delete the one
        committed `.claude/settings.json` from the frontend repo that carries it. That is a change
        to a product repo, so it ships through that project's own tracker — `ws-setup`'s rule is
        that setup never touches a repo's own files. **This criterion stays unticked on purpose**:
        it is real outstanding work, it is out of this repo's scope, and it belongs on that
        project's own tracker, where it must be filed so it is not lost. Nothing in this repo will
        ever tick it, and no agent settings file is written here to close it
- **Notes:** the useful half of this finding is the correction. Changing `ws-setup` would have
  fixed nothing; the house rule is prevention, not a cure.

## [-] p8.8 — The journal mirror leaks the device name into a public docs home — absorbed into p8.31, the merged leak-surface task

**Dropped 2026-11-02** (reasoning in git history at `9c973ee`): the device name in the journal mirror is one of p8.31's items.

## [-] p8.9 — The graph audit cannot see whether a referenced file reached each agent — absorbed into p8.24 as its per-agent instance

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. It is the same defect as p8.24 one layer down — an audit that
reports clean about something it did not read — so it is fixed in the same change, and p8.24
carries its per-agent criteria.

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
  - [~] **kept partial 2026-11-02: deployed, audit unprovable.** The deployment is evidenced —
        `skills/ws-shared/tracks.md` carries *Retiring a track*, and that content reached this
        repo through the publish path, which copies from the library. That the graph audit itself
        reported anything meaningful is what cannot be shown, and **p8.24** is exactly why: the
        audit reports clean about a change it may never have read. Original text follows.
        Changed through `ws-refine`, with its graph audit — **not done in the build**: the library
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

## [-] p8.11 — `ws-wrap` clears `tracks/current` and says nothing about the id — the consumer is already fail-safe; filed because p8.10 shipped, not because anything misbehaves

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. p8.10 made `ws-ship` ask rather than clean up nothing, so the
missing line costs a question, not a wrong answer.

## [-] p8.12 — The tracker adapters cannot answer "what is the status of id X?" — a stated limitation with an asking gate

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. Recorded instead as a boundary in
[`records/known-limitations.md`](../records/known-limitations.md): the sweep uses set difference
and asks rather than removing.

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
- **Where the three sites are (2026-11-02):** `ws-start`, `ws-plan` and `ws-review` — and
  `ws-start` itself warns against the idiom, which is the instance that proves the point. **It is
  live on this workspace**, whose own path contains a space, so the failure is reproducible here
  rather than hypothetical.
- **Notes:** the **seventh** instance of the pack's recurring shape — a rule that exists with no
  path that executes it. Found by the lead's own grep after the review, which had declared it
  skimmed `ws-start` outside the diff hunks. A coverage gap honestly declared, not a miss.

## [-] p8.14 — Nothing ever enumerates the track root, so a forgotten worktree is invisible — its cheap half is absorbed into p8.32; the third sweep pass is dropped

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. **p8.32** takes the half that stops the residue being created
at all: retirement removes the parent `<id>/` directory it currently leaves behind. The third
sweep pass — enumerate the track root, subtract live worktrees and track directories, report
disk-only orphans with their size — is **dropped explicitly**: it reports residue that the cheap
half stops producing, and it needs a resolved root, a size calculation and its own asking gate to
do it.

## [-] p8.15 — The worktree root is a relative path with no defined base — absorbed into p8.32, the merged worktree-hygiene task

**Dropped 2026-11-02** (reasoning in git history at `9c973ee`): resolving the root once instead of seven literals is p8.32's
other half.

## [-] p8.16 — Inside a git repo, the state dir rests on one gitignore line nothing re-asserts — absorbed into p8.31, the merged leak-surface task

**Dropped 2026-11-02** (reasoning in git history at `9c973ee`): the `git check-ignore` assertion is p8.31's first item.

## [x] p8.17 — `docs_home` doubles in four sites, and `ws-fanout` silently takes the unsafe branch · 2026-11-02 · @Alpha-30-creator · https://github.com/Alpha-30-creator/worksite/pull/7

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** of 35 `<docs_home>` sites in 16 files across 12 skill directories, **31 read it as the
  agent directory itself** — so it ends `/agent`. **Four** append `/agent` and so read it as the docs
  root: `ws-fanout`:32, :136, :192 and `ws-shared/tracks.md`:108, which contradicts **itself**
  against `tracks.md`:72 and :266, and names a path neither of its own callers (`ws-ship`:100,
  `ws-task`:67) uses. p3.1's schema page states the dominant form and names the contradiction; this
  task fixes the four.
- **The count is not the argument, and an earlier draft of this task got the figures wrong** (it said
  27 against 4, across 13 skills). The question is settled without counting: `ws-setup`'s own
  template at `templates/cartridge.md`:6 writes `docs_home: <project>-docs/agent` and
  `ws-shared/examples/cartridge.md`:6 writes `northwind-docs/agent` — the **definition** of the key
  puts `/agent` in the value. `ws-shared/stacks/hexagonal-nest.md`:7 corroborates from the other
  side, reading `<docs_home>/../engineering/`, which only resolves if `docs_home` sits one level
  below the docs root.
- **It is live, not theoretical, and the failure direction is the bad one.** On this project's own
  `docs_home: docs/agent`, `ws-fanout`:32 greps `docs/agent/agent/reference.md`, which does not
  exist. The grep finds nothing, so the isolation gate reads `worktrees` as **absent** and takes the
  `false` branch — the one that shares a single working tree between parallel builders. It was only
  harmless on the p3.1/p3.2/p6.1 batch because the lead read the cartridge directly instead of
  through that grep.
- **Acceptance:**
  - [x] the four sites read the dominant form; `tracks.md` no longer contradicts itself
  - [x] `ws-fanout`'s isolation gate distinguishes "`worktrees` is absent or false" from "the
        cartridge could not be read at all", and the second is a **stop**, not the `false` branch.
        A gate that cannot find its input must not silently choose the unsafe answer
  - [x] p3.1's gap 13 updated or closed to match what the pack then does
  - [x] changed through `ws-refine`, with its graph audit
- **Notes:** found by p3.1's blind reader, which wrote `docs_home: docs/agent` from the page and
  produced a path that resolves nowhere. The documentation task surfaced a pack defect, which is the
  argument for writing schemas down.

## [-] p8.18 — Two rules in `tracks.md` rest on wrong premises — both are recorded as boundaries in the limitations record instead

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. Not named either way in the approved target shape; dropped
rather than left open because both of its items are among the eleven sentences in
[`records/known-limitations.md`](../records/known-limitations.md) — the no-upstream refusal is
deliberately conservative, and an `in-repo` project's journal does not travel. Each refuses or
costs something knowingly, neither reports success while doing the wrong thing, so neither is a
defect by this phase's new goal line.

## [-] p8.19 — The cartridge cannot hold what the pack already asks for — absorbed into p8.33, the merged cartridge-honesty task

**Dropped 2026-11-02** (reasoning in git history at `9c973ee`): `merge_style` and the rule-skill prefix are p8.33's first two items.

## [-] p8.20 — Keys that exist but cannot express the ordinary shape — absorbed into p8.33, the merged cartridge-honesty task

**Dropped 2026-11-02** (reasoning in git history at `9c973ee`): `owned_by`'s permissive degrade and the `lite` disagreement carry over; the rest is recorded as a boundary.

## [-] p8.21 — `machine:` has no merge semantics and no reader — absorbed into p8.33, the merged cartridge-honesty task

**Dropped 2026-11-02** (reasoning in git history at `9c973ee`): `machine:` being notes-only is stated in the schema by p8.33.

## [-] p8.22 — `lite` and the tracker: two files disagree — absorbed into p8.33, the merged cartridge-honesty task

**Dropped 2026-11-02** (reasoning in git history at `9c973ee`): the `lite` contradiction is p8.33's last item.

## [-] p8.23 — The pack's rule numbers are cited everywhere and defined nowhere, and `R3` means two things — label and citation hygiene, and the citation practice itself is being removed, which ends the class

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`.

## [~] p8.24 — Gates that read an empty result as a pass, and the graph audit has two of them · @Alpha-30-creator · 2026-11-02

- **Repos:** worksite (pack)
- **Depends on:** p8.17
- **Absorbed 2026-11-02: p8.9**, as this task's per-agent instance. p8.9 is the same defect one
  layer down — the audit resolves links inside the library and reports clean about a deployment
  it never read — so it is the same change, not a second one. Its criteria are below.
- **This is the first task in P8, and the reason is not its size.** Every other change to the
  pack is required to end with the graph audit, and until the audit proves it read something,
  every one of those changes is certified by a check that may not have run.
- **Why:** p8.17 fixed one instance of a class and named three more. The class: **a check whose
  silence reads as a pass.** Where a skill greps, parses or queries for a condition, an empty result
  from a missing file, an unreadable file or a failed call is indistinguishable from a real negative
  answer — and the branch it falls to is the permissive one.
- **`ws-refine`'s own graph audit has it twice**, which makes it the sharpest and the first to fix,
  because it is the block every pack change is required to run:
  - its block opens by `cd`-ing into the library; if the `cd` fails or the glob does not expand,
    every loop runs zero times and prints nothing, so it **reports a clean audit of a change it
    never audited**, defeating the skill's own line that an unaudited change is not finished;
  - its coverage is **forward only** — it verifies that every skill *named* in a `What next?` exists,
    with no reverse check that every exit the *prose* offers is listed. p8.17 added a `ws-setup`
    exit and the audit stayed clean. **The audit cannot catch the kind of gap the change introduced.**
- **The other two:** `ws-shared/trackers/roadmap-files.md`:25-27, where an empty list means "nothing
  open" or "wrong path / never pulled" — so `ws-start` shows an empty board, or claims a task someone
  else holds; and `ws-setup`:22-24, where an empty `find` means "no cartridge" or "could not
  descend", picking **new** over **upgrade**. The second is mitigated by its show-and-wait gate.
- **Acceptance:**
  - [ ] the graph audit establishes it actually read something before reporting clean, and gains the
        reverse check: every skill a `What next?` section's prose sends the agent to is listed
  - [ ] the two adapter/setup sites distinguish "read it, the answer is no" from "could not read it"
  - [ ] the class is written down once, in `ws-shared/review/tier1-universal.md`, as a universal
        rather than per-site: **a gate whose input is unreadable must not fall to the unsafe
        default** — establish that the input was read before branching on what it said
  - [ ] *(from p8.9)* the audit checks the **deployed** copies, not only the library: for every
        file a skill references, confirm it exists under each agent this project deploys to, and
        report **per agent**, since a file can reach two of three
  - [ ] *(from p8.9)* the audit fails loudly when `agent-sync status` shows any `ws-*` artifact
        conflicted or pending, rather than auditing a library that was never deployed
  - [ ] changed through `ws-refine`, with its graph audit — **after** that audit is the thing fixed
- **Notes:** one task and three sub-items deliberately, decided when p8.17 was planned. The graph
  audit first, because until it is fixed every other pack change is certified by a check that may
  not have run. p8.9's own trigger is worth keeping: a deployment skipped because the artifact was
  `conflicted`, which `agent-sync save` reports and the audit does not read — and the cause of
  that conflict was a manual `cp` into a deployed copy.

## [ ] p8.25 — Shipping a task does not refresh the cartridge rows it invalidates

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** p3.5 found the project cartridge — the first file every agent reads — stale in **nine**
  places after five tasks shipped around it. `ws-ship`'s harvest writes a worklog entry and updates
  the docs the change touched, and never looks at the cartridge, so every row naming a task id or a
  phase rots silently. The cartridge is the highest-leverage file in a project and the only one with
  no owner.
- **The test is not the obvious one, and that is the finding.** "Is this statement still true?" misses
  most of it: two of p3.5's nine defects were **tense and completeness** while every clause stayed
  technically accurate — a row describing an empty directory that held eight files, and a list that
  read as exhaustive after two directories were added. Both survived a deliberate full re-read
  looking for false statements. The check wants to be **"does this row still read correctly"**.
- **Acceptance:**
  - [ ] `ws-ship` names the cartridge among the docs a shipped task may invalidate, with the rows
        most likely to rot called out — anything naming a task id, a phase, or a path that does not
        exist yet
  - [ ] the prompt asks whether each such row still *reads* correctly, not merely whether it is
        accurate, with the tense-and-completeness failure named
  - [ ] a project's cartridge prefers a link to a decision record over a task id where one exists,
        since a closed task survives only as long as its roadmap entry
  - [ ] changed through `ws-refine`, with its graph audit
- **Kept open 2026-11-02** as the thirteenth task, past the twelve the trim targeted: it defends
  the first file every agent reads, and this session hit it three times in one day.
- **Notes:** *rejected* while planning p3.5: adding a "last reviewed" date to the cartridge. It would
  have caught all nine, and it is a claim nobody enforces — the pack's own argument against anything
  depending on memory. This is the version with an executing path.

## [-] p8.26 — Three things the guard does not cover, and nothing says so — its two real items are absorbed into p8.31; the §3 fence case is recorded as a limitation

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. **p8.31** takes the `disable-model-invocation` check and §1's
inline allowlist. The §3 fence case is documented rather than fixed, in
[`records/known-limitations.md`](../records/known-limitations.md).

## [-] p8.27 — `ws-start` never writes the `- Stores:` line the gate reads — the consumer is already fail-safe; filed because p8.5 shipped, not because anything misbehaves

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. The gate's three pre-claim inputs stand on their own and
anything they cannot settle is `unknown`, which is a drop — the safe answer, reached by having no
evidence rather than by reading it, which is a cost in elegance and not in correctness.

## [-] p8.28 — The schema page's sixteen `ws-setup` citations moved, and the page says so instead of being right — label and citation hygiene, and the citation practice itself is being removed, which ends the class

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. Its own closing question — whether the page should cite line
numbers at all — is the answer: it should not, and
[`records/known-limitations.md`](../records/known-limitations.md) records that a `file:line`
citation is advisory and the quote is the durable half.

## [-] p8.29 — `ws-fanout`'s description no longer says what it refuses — label and citation hygiene, and the citation practice itself is being removed, which ends the class

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. Flagged twice and deliberately not taken twice, which is the
third signal that it is not worth a track.

## [ ] p8.30 — Two skills give opposite instructions about pushing the library

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why:** `ws-refine` ends by running `agent-sync save`, which validates, deploys to every agent
  and pushes the whole library. `ws-fanout` tells every subagent it briefs to commit and **never**
  push. A library track inside a fanout batch is therefore instructed both ways, and nothing in
  either file acknowledges the other. It is not theoretical: it came up in the p8.5/p4.3 batch, and
  the lead resolved it by hand — the builder edited library files and stopped, the lead ran `save`
  and the graph audit before review. That resolution is nowhere in the pack.
- **Acceptance:**
  - [ ] one of the two skills states the rule for a library change run by a subagent, and the other
        points at it — not two independent answers
  - [ ] the rule covers who runs the graph audit, since the audit cannot see per-agent deployment
        until `save` has run (p8.9)
  - [ ] `ws-fanout`'s builder-brief bullet and `ws-refine`'s closing step agree in writing
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** the generic version of p8.5. p8.5 taught the gate that a shared store exists; this
  teaches the two skills who is allowed to publish one.

## [ ] p8.31 — The leak surface has three uncovered edges and nothing asserts any of them

- **Repos:** worksite (pack), worksite
- **Depends on:** —
- **Merged 2026-11-02** from **p8.16** (the `git check-ignore` assertion), **p8.8** (the device
  name in the journal mirror) and the two real items of **p8.26**. One task because all four are
  the same question — what stops a private name reaching a public commit, and what asserts that
  the stop is still there — and because they touch the same two files. The bodies of the three
  absorbed tasks are kept above; this is the shipping unit.
- **Acceptance:**
  - [ ] when `state_dir` is inside a git repo, something asserts the ignore rule instead of
        trusting it. `git check-ignore -q <state_dir>` is the whole test; it runs where it is
        seen before damage — the project's own `verify` where there is one, `ws-start` otherwise
        — and `scripts/check.sh` in this repo gains it as the first consumer *(from p8.16)*
  - [ ] proven by deleting the ignore line and watching the check fail, not by reading it
        *(from p8.16)*
  - [ ] the journal entry header carries a device **alias** rather than the raw device id, so a
        device named after its owner cannot reach a public repo through the mirror or through any
        other path *(from p8.8)*
  - [ ] `tracks.md` states the consequence where it describes the mirror, next to the existing
        note about `lite` projects with no `docs_home` *(from p8.8)*
  - [ ] a check that `ws-shared` still carries `disable-model-invocation: true` — if it ever
        loses the flag the pack silently becomes fourteen invocable skills, and the README, the
        concepts page and the cartridge all become wrong about the count in the same moment
        *(from p8.26)*
  - [ ] §1's inline allowlisted string is visible where coverage is **defined**, not only in the
        script body, so an auditor reading the pattern file alone sees the whole of it
        *(from p8.26)*
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** p8.16's observation is the argument for the whole task: the cartridge already said
  *"Do not remove that line"* in bold — the pack knew the risk and wrote a reminder instead of a
  check. **Deliberately not included:** the cartridge key for "this docs home is public", and
  `ws-setup` warning when it generates one. Both are schema work with no behaviour yet behind
  them, and the alias makes the leak harmless whatever the key says.

## [ ] p8.32 — A retired track leaves its parent directory behind, and the root it lives under is undefined

- **Repos:** worksite (pack)
- **Depends on:** —
- **Merged 2026-11-02** from **p8.14**'s cheap half and **p8.15**. One task because the fix to the
  first needs the second: removing the parent `<id>/` directory means naming it, and the root has
  no defined base. p8.14's third sweep pass is **dropped explicitly** — see its body above.
- **Acceptance:**
  - [ ] *Retiring a track* removes the parent `<id>/` directory when removing its last worktree
        leaves it empty, so the residue is never created rather than reported afterwards. A
        directory that still contains a working `.git` is not touched *(from p8.14)*
  - [ ] the worktree root becomes a cartridge key with a stated default, resolved to an absolute
        path once per session — one definition, not the seven literals across `ws-start` and
        `ws-shared/tracks.md` *(from p8.15)*
  - [ ] `task.md`'s `- Worktrees:` line records absolute paths, since its reader is a cold
        session with no cwd *(from p8.15)*
  - [ ] `ws-setup` writes the key, and states where the root lands in the **single-repo** case,
        where it is necessarily outside the workspace *(from p8.15)*
  - [ ] a project with an existing root under the other reading of `../` is detected and
        reported, rather than a second root being created beside it *(from p8.15)*
  - [ ] proven by execution against a fixture, not by reading: retire a track and confirm the
        parent is gone, and confirm the resolved root is the same absolute path from a repo
        directory and from the workspace root
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** 9.6M of orphaned build output on a real project, invisible to both sweep passes, is
  what this costs when the shell left behind is later filled.

## [ ] p8.33 — The cartridge promises five things it does not deliver

- **Repos:** worksite (pack)
- **Depends on:** p3.1
- **Merged 2026-11-02** from **p8.19**, **p8.20**, **p8.21** and **p8.22**, keeping only the items
  with behaviour behind them. The four bodies are kept above; what was left out was left out
  deliberately: `repos[].role`'s six unconsumed values, the unrecordable collaborator list,
  `tracker.statuses`' absent shape, `tracker.lists`' third list, and "this command exists, do not
  run it" — the last two are recorded as boundaries in
  [`records/known-limitations.md`](../records/known-limitations.md) instead, since both are
  honest asks rather than wrong answers.
- **Acceptance:**
  - [ ] `merge_style` is given a value in `ws-setup`'s cartridge template, or `ws-ship` stops
        reading it — a key whose only behaviour is its fallback is worse than no key *(p8.19)*
  - [ ] the rule-skill prefix gets a cartridge key, because `ws-fanout` briefs builders to read
        `<prefix>-<area>` skills and so is load-bearing on a value it cannot look up *(p8.19)*
  - [ ] `house_rules.owned_by`'s degrade to `me` — the **permissive** branch — is reversed, or
        warned about where it is read, so `ws-refine` cannot propose rule changes it may not be
        entitled to with no error and no prompt *(p8.20)*
  - [ ] the schema states that `machine:` carries **notes only**, so nobody writes
        `machine.<device>.repos[].dir` and gets silence *(p8.21)*
  - [ ] one of the two disagreeing `lite` sentences changes — `ws-setup`:54 says a `lite` profile
        gets no tracker, `ws-shared/trackers/tasks-file.md`:3 calls itself the `lite` default — so
        the pack says one thing *(p8.22)*
  - [ ] p3.1's affected gap rows updated or closed to match what the pack then does
  - [ ] changed through `ws-refine`, with its graph audit
- **Notes:** every item here is a place where an author writes something reasonable and is never
  told it was ignored, which is this phase's goal line applied to a data format.
