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
  the guard twice (in a throwaway clone, then in the pre-commit hook), but both runs read the same
  `scripts/leak-patterns.txt`, so a new private name passes both. A green publish means "no known
  pattern", never "no private data"; the content still needs a human read before it is published.
- A publish doing anything other than copying — a path rewrite, a substitution, a "fix" applied on
  the way out. `publish.sh` asserts `diff -rq` library-against-candidate is silent, so this fails
  loudly; when it does, the de-personalisation in P2 is incomplete and the fix belongs there, not
  in the publish.
