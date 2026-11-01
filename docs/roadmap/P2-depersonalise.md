# P2 — The pack in the repo, generic

**Goal:** all fourteen skill directories live here and mention no private project, repo, person
or path. The author's own facts become examples a stranger can read.

## [x] p2.1 — Apply the source-of-truth decision · 2026-11-01 · @Alpha-30-creator

- **Repos:** worksite
- **Depends on:** —
- **Decided** in [ADR 0001](../decisions/0001-library-is-the-source-of-truth.md): the library
  stays the working copy, this repo is a published artifact, and publishing is a step inside
  `ws-refine`. The remaining work is applying it.
- **Acceptance:**
  - [x] an ADR naming the choice and what was rejected and why
  - [x] `ws-refine`'s "edit the library, never a deployed copy" instruction gained its third
        clause: the public repo is a published artifact, never edited directly, and a fix goes in
        the library so the publish carries it
  - [x] the sync direction written up in
        [`engineering/sync-direction.md`](../engineering/sync-direction.md), including the
        load-bearing property — publishing is a plain copy, never a transformation — and the two
        consequences: drift is prevented by automation rather than architecture, and the leak
        guard must run on the publish path
  - [ ] the publish step itself is **p6.1**, and depends on p2.2 being finished — until the
        library holds the generic content, publishing would be a transformation rather than a
        copy, which ADR 0001 rules out

## [x] p2.2 — Translate the fourteen skills, do not strip them · 2026-11-01 · @Alpha-30-creator

- **Repos:** worksite (pack)
- **Depends on:** p2.1
- **The rule:** nothing is deleted for being specific. **Specificity is the quality.** A private
  name appears in one of three ways, and each has its own treatment:

  | Kind | Example | Treatment | Effect on quality |
  |---|---|---|---|
  | **Bookkeeping** | "Serves `api-repo`, `be-repo`" | replace with what *selects* the pack — the `stack:` tags | **better** — the list was already rotting; a renamed repo made it wrong |
  | **Pointer into private docs** | "read §3 of the backend practices doc" | replace with the *mechanism*: read the repo's own practices doc, named by the cartridge | **better** — stops hardcoding one path, works for everyone |
  | **Real worked detail** | "this service has no test suite, so run it and keep transcripts" | re-file or re-cast, below | **unchanged** |

- **Acceptance:**
  - [x] `skills/` holds all fourteen directories, `ws-shared` included with its `review/`,
        `stacks/`, `trackers/` and the new `examples/` subtrees — 46 files
  - [x] **project-specific detail re-filed, not deleted — and it turned out there was nothing to
        move.** The one fact scheduled for re-filing was *already* in that project's own
        `risks/`, in a richer form recording a later exception. The shared pack's copy had gone
        stale while the correctly-filed one stayed current, which is the sharpest possible
        argument for the rule
  - [x] **a consistent fictional cast** — northwind (two repos plus docs), kestrel (one repo,
        LangGraph) and atlas (a company's conventions, schools as its tenant), covering every
        tracker adapter. Each has a currency, a framework and a domain, because a finding proved
        that an example without them leaves rules unanchored
  - [x] every pack read against the question, pass or fail recorded per pack. 13 pass outright,
        2 partial, 2 failed on a single line each — all four fixed before shipping
  - [x] reviewed independently, in a context that had not done the translation. **8 findings, all
        8 verified against the files, none overturned.** Three were rules this session wrote
        hours earlier being broken by this session
  - [~] `scripts/check.sh` zero on all three sections, and **section 2 ran for the first time
        ever**. **But the claim "zero private names" was false twice, and both misses reached the
        public repo** — found later the same day while verifying a planner's report, not by the
        scan:
        - **Abbreviations.** The two- and three-letter initials of four private project names
          survived in `ws-setup`, as the example prefixes for rule skills. The patterns matched
          full names only. (Not quoted here — the guard now blocks them, which is why this
          amendment had to be reworded before it would commit.)
        - **Private remote URLs**, which is the worse of the two. The pack instructed anyone
          installing it to `git clone` the author's **private** secrets repo, plus the private
          library and notes repos. Not merely a name: a broken instruction for a stranger, and it
          advertised the store's existence and path.
        Both fixed; the guard now covers abbreviations and org names. The lesson is that a
        name-matching scan cannot bound a claim of "no private data" — it bounds only the classes
        someone thought of
  - [x] the library holds **this** content: verified `identical across all 14` by per-directory
        diff, so publishing stays a plain copy and ADR 0001 holds
- **Notes:** around 130 occurrences across 23 files; the large majority is the first kind and is
  pure find-and-replace. The third kind is the real work and the only place quality can be lost.
  Budget a day, not an afternoon. The library improves on its own merits, independently of
  publishing — which is the point of ADR 0001.

## [ ] p2.3 — Turn the author's own facts into examples

- **Repos:** worksite
- **Depends on:** p2.2
- **Acceptance:**
  - [ ] `examples/device.yaml` — the agent-sync device file, with invented project ids
  - [ ] `examples/cartridge.md` — a filled-in cartridge for a plausible two-repo project
  - [ ] `examples/manifest.tsv` — the secrets manifest, with invented destinations
  - [ ] `ws-shared/reference.md` keeps the rules and loses the author's device, stores and
        project list, pointing at `examples/` instead
  - [ ] the two private store URLs appear nowhere; the docs explain that each user creates
        their own and how
