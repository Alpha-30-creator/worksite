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

## [~] p2.2 — Translate the fourteen skills, do not strip them @Alpha-30-creator · 2026-11-01

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
  - [ ] `skills/` holds all fourteen directories, `ws-shared` included with its `review/`,
        `stacks/` and `trackers/` subtrees
  - [ ] **project-specific detail is re-filed, not deleted.** Anything true of one project moves
        into that project's own `risks/` file, which is where the pack's design already says it
        belongs. It becomes private and better-placed; today a trap about one backend sits in a
        pack four unrelated repos load
  - [ ] **the examples get a consistent fictional cast** — one small invented world (a two-repo
        SaaS, a Python AI service) reused across every pack, so examples stay concrete instead of
        being blurred into vagueness. A reader who does not know the author's projects currently
        learns nothing from "serves `api-repo`"; they will learn something from this
  - [ ] every pack read against one question, pass or fail recorded per pack: **is this advice
        still actionable for someone who has never seen the original repo?** Any item answering
        no is rewritten or moved — not shipped
  - [ ] the result reviewed with `ws-review`, which is the pack reviewing its own translation
  - [ ] `scripts/check.sh` reports zero hits, zero frontmatter errors, zero broken links
  - [ ] the author's deployed library ends up holding **this** content, not the old content —
        otherwise publishing becomes a transformation and ADR 0001 is broken
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
