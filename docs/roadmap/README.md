# Roadmap

This folder **is** the tracker (`tracker.kind: roadmap-files`). One file per phase, one `##`
heading per task. The markers and the claim protocol are in the `roadmap-files` adapter that
ships with the pack; the short version:

| Marker | Means |
|---|---|
| `[ ]` | open |
| `[~] @who · date` | claimed |
| `[r] @who · PR` | PR open |
| `[x] date · @who · PR` | done and merged |
| `[-] reason` | dropped |
| `[?]` | blocked on a decision |

**A pushed commit is the lock.** Claim by changing `[ ]` to `[~]`, updating
[../STATUS.md](../STATUS.md), and pushing. If the push is rejected, pull and check the task is
still open before retrying. Never edit someone else's `[~]`.

A task is **pickable** when it is `[ ]` and every id on its `Depends on:` line is `[x]`.
