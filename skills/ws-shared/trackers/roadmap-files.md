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

**Read-first, because an empty result here has two meanings and they are not the same answer.**
A `grep` that finds nothing prints nothing; so does a `grep` over a path that does not exist, and
so does one over a directory holding no roadmap files. All three look identical on stdout, and the
permissive reading — "nothing is open" — is the one that makes `ws-start` show an empty board or
claim a task somebody else already holds. So the board is established readable *before* anything
is read out of it, and each query carries an explicit negative.

```bash
docs="<docs>"; board="$docs/<path>"      # quoted throughout: a workspace path may contain a space
git -C "$docs" fetch -q && git -C "$docs" pull --ff-only -q \
  || echo "COULD NOT REFRESH $docs — what follows may be stale; say so before claiming anything"
[ -d "$board" ] && [ -r "$board" ] && [ -x "$board" ] \
  || { echo "UNREADABLE: $board — the board is UNKNOWN, not empty"; exit 1; }
n=0; for f in "$board"/P*.md; do [ -r "$f" ] && n=$((n+1)); done
[ "$n" -gt 0 ] || { echo "READ $board, and it holds no readable P*.md —"\
  "wrong tracker.path, or never pulled. UNKNOWN, not empty"; exit 1; }
echo "read $n roadmap file(s) under $board"
[ -r "$docs"/STATUS.md ] && cat "$docs"/STATUS.md \
  || echo "NO READABLE STATUS.md under $docs — the summary is UNKNOWN; the per-file rows below"\
     "are the only board you have"
grep -rn "^#.*\[\(~\|r\)\]" "$board"/P*.md || echo "read $n file(s), and nothing in progress"
grep -rn "^#.*\[ \]"        "$board"/P*.md || echo "read $n file(s), and no open task"
grep -rn "^#.*\[?\]"        "$board"/P*.md || echo "read $n file(s), and nothing blocked"
```

| What came back | What it means | What you do |
|---|---|---|
| `read N roadmap file(s)` then rows | the board, as it is | report it |
| `read N file(s), and no open task` | **read it, and the answer is no** | say the board is empty |
| `UNREADABLE: …` or `READ …, and it holds no readable P*.md` | the board is **UNKNOWN** | **Stop. Do not report an empty board and do not claim anything.** Say which path you tried, ask for the right `tracker.path`, re-run |
| `NO READABLE STATUS.md …` | the **summary** is unknown; the rows below are not | report from the rows, and say the summary was unreadable |
| `COULD NOT REFRESH …` | what you are about to read may be stale | say so **before** claiming; a claim is a push, and a stale read loses the race |

Report in-progress first (so you can see what the other person holds), then blocked, then
pickable with `id | title | repos | depends | phase target`. Avoid proposing a task that touches
the same files as someone's `[~]`.

## Claim — a push is the lock

```bash
git -C "<docs>" pull --rebase -q
# edit the task heading: [ ] -> [~] @<me> · <YYYY-MM-DD>
# edit STATUS.md: add to "In progress", remove from "Next up", bump Updated
git -C "<docs>" add "<path>"/P*.md STATUS.md
git -C "<docs>" commit -m "docs(roadmap): claim <id>"
git -C "<docs>" push origin main
```

**Push rejected → `pull --rebase`, re-check the task is still `[ ]`, then retry or pick another.**
That retry is the whole concurrency story; do not skip it. Never edit someone else's `[~]`.

## Mark

In review: `[~]` → `[r] @<me> · <PR urls>`. Done: `[r]` → `[x] <date> · @<me> · <PR urls>`,
and move the STATUS.md row out of "In progress". Same pull → edit → commit → push, same retry.

## Note

A `- Where it stopped (<date> @<me>): …` line under the task, plus one line in the STATUS.md
"In progress" row.
