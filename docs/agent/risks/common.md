# worksite review risks

Tier 3: risks specific to this project. Universal checks live in the pack's
`ws-shared/review/tier1-universal.md`, objective security in
`ws-shared/stacks/security-baseline.md`, and stack risks in `ws-shared/stacks/`.

**This file grows by use.** `ws-review` proposes a line here whenever it confirms a finding
whose class is not written down yet. Each entry says **what to look for**, not what one past bug
was.

## Risks

- A private project, repo, person, device or path name reaching a committed file — the guard in
  `scripts/check.sh` only covers the patterns listed in `scripts/leak-patterns.txt`, so a new
  private name is invisible to it until someone adds it.
- A new allowlist entry in `check.sh` widened further than the one case that needed it, silently
  un-guarding a pattern everywhere.
- A skill edited in this repo while the agent is loading the same skill from the author's
  library — the change appears to do nothing, or the opposite of nothing. The library is the
  working copy and this repo is a published artifact ([ADR 0001](../../decisions/0001-library-is-the-source-of-truth.md)).
- An instruction written in the author's own voice — a possessive first name, "my laptop", "my
  machines" — surviving the strip because it names no project. The leak scan catches names, not
  voice, so this one needs a human read.
- A skill's relative link to `ws-shared/` broken by moving the pack under `skills/` — section 3
  of `check.sh` catches it only for files that are tracked.
- A doc asserting a capability the pack does not have yet, because the README was written from
  the plan rather than from the tree. Every README claim is checkable against the repo.
- A publish that lands a private name the pattern file does not know — `scripts/publish.sh` runs
  the guard three times (in a throwaway clone, on the staged tree, then in the pre-commit hook),
  but every run reads the same `scripts/leak-patterns.txt`, so a new private name passes all of
  them. A green publish means "no known pattern", never "no private data"; the content still
  needs a human read before it is published.
- Anything that is not a pack file sitting inside a skill directory — an `.env`, a credential
  file, an editor backup, a `.DS_Store`, a symlink. All of it is published, and the guard is a
  name list rather than a secret scanner, so it would go public unread. A symlink is the sharper
  case: the working-tree scan follows it and never sees the path string that git actually commits.
- A check that is claimed to run but is not installed — the pre-commit hook is a per-clone
  `core.hooksPath` setting, so "the guard runs again at commit time" is false on any checkout
  where nobody ran `git config core.hooksPath .githooks`. A gate worth claiming is worth
  asserting.
- A publish doing anything other than copying — a path rewrite, a substitution, a "fix" applied on
  the way out. `publish.sh` asserts `diff -rq` library-against-candidate is silent, so this fails
  loudly; when it does, the de-personalisation in P2 is incomplete and the fix belongs there, not
  in the publish.
- A doc citing `skills/` by `file:line`, **or claiming what a check covers** — line numbers drift
  the moment a skill gains a line, including citations nobody edited that sat two lines below an
  insertion; and `scripts/check.sh` resolves relative links but never line numbers and never its own
  coverage, so both read exactly like a right one. Re-derive every number against the commit the doc names. Found on
  p3.1, where three of six wrong numbers originated in the source ledger and were transcribed
  faithfully onto the page.
- An **absolute** asserted where the tree has an asymmetry — the mirror image of the entry above.
  "Nothing else depends on X", "the other four Y", "file trackers give a lock": each was true of the
  common case and false at an edge the pack documents elsewhere. Grep the subject of the claim rather
  than a proxy for it, and treat a number appearing twice in one file as a claim about arithmetic.
- A sentence describing what a check covers that is true of **one mode** of that check and reads as
  true of all of them. `scripts/check.sh` enumerates the whole working tree with no arguments and
  only staged additions with `--staged`, and it runs in four places, two of them staged — so
  "section 1 reads tracked and untracked files" is right about one run and wrong about two. Four of
  the five findings on p4.3 were this shape. Name the mode in the clause, not in a later paragraph.
- A paragraph written to manage citation drift that is **itself incomplete**, which reads exactly
  like a complete one. p8.5 deferred re-deriving the numbers its own insertions moved, named
  `ws-fanout`, `ws-shared/tracks.md` and `ws-shared/reference.md`, and omitted `ws-setup` — the file
  it had edited most invasively, with sixteen citations on the page. A deferral is a coverage claim;
  grep the set it enumerates against the files the change actually touched.
- A doc attributing a configuration-driven path to the wrong half of a mechanism. `publish.sh`'s
  destination is the repo it sits in; the configured target list belongs to `ws-refine`. The guard
  checks for leaked names, never for a true-sounding claim about which component holds the private
  path.
