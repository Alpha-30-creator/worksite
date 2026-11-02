# Runbook: purge a leaked string from git history

**When:** something private reached the public repo and `origin/main` has already been fixed, but
the string still sits in earlier commits. Fixing the tip does not help — git keeps every version,
which is the whole reason this repo is public from its first commit rather than flipped later.

**This is destructive and it rewrites published history.** Every rule below exists because of a
way it goes wrong.

## Preconditions — check all four, do not skip

1. **No builder is mid-flight.** `git worktree list` plus `git status --porcelain` in each
   worktree, and `git -C ~/.agent-sync/store status --porcelain` if a track is editing the
   library. Rewriting under an active builder orphans its base commit and can destroy uncommitted
   work. The house rule is absolute: never discard work.
2. **All worktrees removed.** They are pinned to commits the rewrite replaces. Remove them
   properly (`git worktree remove`, then `prune`) — deleting the folder leaves git believing it
   exists.
3. **Enumerate what is actually there**, per commit. Do not guess which commits are affected:

   ```bash
   for c in $(git rev-list --reverse main); do
     n=$(git grep -ihcE '<pattern>' "$c" -- 'skills/' 2>/dev/null | awk -F: '{s+=$NF} END{print s+0}')
     printf '%s %s hits:%s\n' "$(git log -1 --format=%h "$c")" "$(git log -1 --format=%s "$c" | cut -c1-55)" "$n"
   done
   ```

   Note the **first** affected commit. Commits before it keep their hashes, so only rewrite from
   there — the earlier history survives untouched.
4. **Test on a throwaway clone first.** Never rehearse on the real repo.

## Procedure

```bash
git clone --no-local --branch main <repo> /tmp/purge-test     # --no-local forces real objects
cd /tmp/purge-test
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --tree-filter '<scrub script>' -- <first>~1..HEAD
```

`git-filter-repo` is the modern tool and is better, but it is not installed here and
`filter-branch` is adequate for a repo of this size. The scrub script runs `sed` over the affected
paths; replace the **longest** form of each string first (a full URL before the bare `owner/repo`
inside it), or the short rule eats the long one.

## Verify — all four, before touching the real repo

| Check | Pass condition |
|---|---|
| leaks gone | zero hits across **every** commit, not just HEAD |
| **nothing else changed** | `git rev-parse HEAD^{tree}` equals the real repo's — identical tree hash means history changed and current state did not |
| history preserved | commit count unchanged; it is a rewrite, not a squash |
| still valid | `bash scripts/check.sh` passes on the rewritten tree |

The tree-hash equality is the one that matters most. It proves the rewrite is lossless.

## Then

```bash
git push --force-with-lease origin main
```

`--force-with-lease`, not `--force`: it refuses if the remote moved since you last fetched.

Afterwards: recreate any worktrees you removed, from the new tip. Anyone who had cloned the repo
still holds the old objects — for this repo that was nobody, which is worth confirming rather
than assuming.

## The unreachable case — residue, not a leak

Everything above is about a name that reached a **commit**. There is a second, quieter case, and
it is the common one: `git add` writes a blob into `.git/objects` **before** any hook can refuse
the commit, so a commit the guard **refused** still leaves its content in the object store. The
object is unreachable — no commit points at it — and that distinction is the whole of the
difference:

| | reachable | unreachable |
|---|---|---|
| pushed to the remote? | yes | **never** — git sends only what the ref graph reaches |
| in a fresh clone? | yes | **no** |
| remedy | the procedure above: rewrite, force-with-lease, confirm who else holds the old objects | declare it, or remove it locally — there is nothing published to undo |

So an unreachable object carrying a private name is **local residue on one machine**, not a leak,
and it needs none of the destructive procedure above. It still gets asserted rather than assumed:
section 6 of `scripts/check.sh` reads the unreachable objects and fails on any hit not declared
in [`scripts/object-store-baseline.txt`](../../scripts/object-store-baseline.txt).

**Do not clear residue with `git gc --prune=now`.** A workspace running the loop has live
worktrees sharing one object store, and their unreachable objects are wanted — a bare prune
destroys work in progress that is not residue at all. On this repo the decision taken on
2026-11-02 was to **leave the measured residue in place and assert it**; the baseline file carries
that decision and the reason. Revisit it only when no worktree is live, and then by the procedure
above rather than by a prune.

## What this does not fix

**The leak reached the remote because a check did not catch it.** Purging history is cleanup, not
a fix. Add the missed class to `scripts/leak-patterns.txt` in the same session, and note that a
name-matching scan bounds only the classes someone thought of: full names were covered,
abbreviations and repo URLs were not, and both got through.
