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
