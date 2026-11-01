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
  library — the change appears to do nothing, or the opposite of nothing. See p2.1.
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
- A doc citing `skills/` by `file:line` — the numbers drift the moment a skill gains a line, and
  `scripts/check.sh` resolves relative links but never line numbers, so a wrong citation reads
  exactly like a right one. Re-derive every number against the commit the doc names. Found on
  p3.1, where three of six wrong numbers originated in the source ledger and were transcribed
  faithfully onto the page.
