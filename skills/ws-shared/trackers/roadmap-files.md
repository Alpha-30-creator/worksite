# Tracker: roadmap files

Work is phases → tasks in Markdown in the docs repo.
Cartridge keys: `tracker.path`, `tracker.status_file`, `tracker.markers`, `tracker.claim`.

## Markers

| Marker | Means |
|---|---|
| `[ ]` | open |
| `[~] @<me> · <date>` | claimed / in progress |
| `[r] @<me> · <PR urls>` | PR open |
| `[x] <date> · @<me> · <PR urls>` | done and merged |
| `[-] <reason>` | dropped |
| `[?]` | blocked on a decision |

**Pickable** = `[ ]` and every task in its `Depends on:` is `[x]`. Exception: a task whose
depends line says "(contract)" may start once the dependency's contract doc is merged.

## List

```bash
git -C <docs> fetch -q && git -C <docs> pull --ff-only -q
cat <docs>/STATUS.md
grep -rn "^#.*\[\(~\|r\)\]" <docs>/<path>/P*.md     # in progress, and whose
grep -rn "^#.*\[ \]"        <docs>/<path>/P*.md     # open
grep -rn "^#.*\[?\]"        <docs>/<path>/P*.md     # blocked
```

Report in-progress first (so you can see what the other person holds), then blocked, then
pickable with `id | title | repos | depends | phase target`. Avoid proposing a task that touches
the same files as someone's `[~]`.

## Claim — a push is the lock

```bash
git -C <docs> pull --rebase -q
# edit the task heading: [ ] -> [~] @<me> · <YYYY-MM-DD>
# edit STATUS.md: add to "In progress", remove from "Next up", bump Updated
git -C <docs> add <path>/P*.md STATUS.md
git -C <docs> commit -m "docs(roadmap): claim <id>"
git -C <docs> push origin main
```

**Push rejected → `pull --rebase`, re-check the task is still `[ ]`, then retry or pick another.**
That retry is the whole concurrency story; do not skip it. Never edit someone else's `[~]`.

## Mark

In review: `[~]` → `[r] @<me> · <PR urls>`. Done: `[r]` → `[x] <date> · @<me> · <PR urls>`,
and move the STATUS.md row out of "In progress". Same pull → edit → commit → push, same retry.

## Note

A `- Where it stopped (<date> @<me>): …` line under the task, plus one line in the STATUS.md
"In progress" row.
