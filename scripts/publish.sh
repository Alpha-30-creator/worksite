#!/usr/bin/env bash
# worksite publish: copy the generic ws-* skills out of the agent-sync library into this
# repo, prove they carry no known private name, then commit and push.
#
#   scripts/publish.sh                  publish from the default library
#   scripts/publish.sh --from <dir>     publish from another skills directory (a worktree, a fixture)
#   scripts/publish.sh --dry-run        stop before writing to this repo; print what would change
#   scripts/publish.sh --prune          allow removing a skill the source no longer has
#   scripts/publish.sh --no-push        commit, but do not push (for exercising the commit path)
#
# Exit 0 = published, or nothing to publish. Non-zero = refused, and this repo is untouched.
#
# Why it works this way:
#
#   * The source is the glob `ws-*` inside the library's skills/ — never the library directory
#     and never anything git-level. The library's history holds the author's private project
#     packs; the glob is what keeps them out, and it needs no list to be kept up to date.
#   * The candidate is assembled in a throwaway `git clone` of this repo and checked there. A
#     refusal therefore happens before a single byte is written here, which is what makes
#     "fails loudly and changes nothing" true rather than hoped for.
#   * `scripts/check.sh` is git-aware, so the candidate has to sit inside a git repo to be
#     scanned at all. That is the second reason for the clone.
#   * The copy is asserted to be plain: `diff -rq` source against candidate must be silent. If
#     it ever is not, this script transformed something and must fail — publishing is a copy.
#
# What a green run does NOT mean: the scan bounds the patterns listed in
# scripts/leak-patterns.txt. A private name nobody has added to that file passes it. Green means
# "no known pattern", never "no private data".
set -uo pipefail

TARGET="$(cd "$(dirname "$0")/.." && pwd)"
FROM="$HOME/.agent-sync/store/skills"
DRY=0
PRUNE=0
PUSH=1
BRANCH="main"

die() { printf 'publish: refused — %s\n' "$*" >&2; exit 1; }
say() { printf '%s\n' "$*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --from) [ $# -ge 2 ] || die "--from needs a directory"; FROM="$2"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --prune) PRUNE=1; shift ;;
    --no-push) PUSH=0; shift ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument '$1'" ;;
  esac
done

# ------------------------------------------------------------------ 1. preflight
# Every one of these refuses before anything is copied anywhere.

[ -d "$FROM" ] || die "no skills directory at $FROM. Nothing to publish from."

SRC=()
for d in "$FROM"/ws-*/; do [ -d "$d" ] && SRC+=("${d%/}"); done
[ "${#SRC[@]}" -gt 0 ] || die "$FROM holds no ws-* skill directories."

git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 || die "$TARGET is not a git repository."

cur="$(git -C "$TARGET" rev-parse --abbrev-ref HEAD 2>/dev/null)"
[ "$cur" = "$BRANCH" ] || die "this repo is on '$cur', not '$BRANCH'. A publish commits to $BRANCH."

[ -z "$(git -C "$TARGET" status --porcelain)" ] \
  || die "this repo's working tree is dirty. A publish must not sweep up an unrelated edit."

[ -x "$TARGET/scripts/check.sh" ] || [ -f "$TARGET/scripts/check.sh" ] \
  || die "no scripts/check.sh here. The guard is not optional, so there is nothing to publish into."

if ! ( cd "$TARGET" && bash scripts/check.sh >/dev/null 2>&1 ); then
  say "publish: refused — scripts/check.sh is already failing on this repo as it stands."
  say "Fix that first; publishing on top of a red tree hides which change broke it. Its output:"
  ( cd "$TARGET" && bash scripts/check.sh ) || true
  exit 1
fi

# Orphans: published here, absent from the source. Deleting a skill needs an explicit yes, so a
# mechanical copy must never be the thing that performs it.
ORPHANS=()
for d in "$TARGET"/skills/ws-*/; do
  [ -d "$d" ] || continue
  n="$(basename "$d")"
  [ -d "$FROM/$n" ] || ORPHANS+=("$n")
done
if [ "${#ORPHANS[@]}" -gt 0 ] && [ "$PRUNE" -eq 0 ]; then
  say "publish: refused — published here but absent from $FROM:"
  for n in "${ORPHANS[@]}"; do say "  $n"; done
  say "Removing a published skill is a deletion, not a copy. Re-run with --prune to mean it."
  exit 1
fi

say "publish: ${#SRC[@]} ws-* skill(s) from $FROM"

# ---------------------------------------------------- 2. assemble the candidate in a clone
TMP="$(mktemp -d "${TMPDIR:-/tmp}/worksite-publish.XXXXXX")" || die "could not make a temp directory."
cleanup() { [ -n "${TMP:-}" ] && rm -rf "$TMP"; }
trap cleanup EXIT

CAND="$TMP/candidate"
git clone --no-hardlinks --quiet "$TARGET" "$CAND" || die "could not clone this repo to check a candidate."

apply_to() {
  # Replace dest/skills/ws-* wholesale with the source's ws-* directories.
  local dest="$1"
  mkdir -p "$dest/skills"
  for d in "$dest"/skills/ws-*/; do [ -d "$d" ] && rm -rf "$d"; done
  local s
  for s in "${SRC[@]}"; do cp -Rp "$s" "$dest/skills/"; done
}

apply_to "$CAND"

# Stage the candidate before scanning it. check.sh's working-tree mode enumerates with
# `git ls-files --cached --others`, which still lists a file that was deleted but not staged —
# so an unstaged --prune would have it try to read a path that is gone. Staging first means the
# scan sees exactly the tree being proposed.
git -C "$CAND" add -A skills >/dev/null 2>&1 || die "could not stage the candidate."

if [ -z "$(git -C "$CAND" status --porcelain)" ]; then
  say "publish: nothing to publish — this repo already matches the library."
  exit 0
fi

# ----------------------------------------------------------- 3. the guard, in the clone
say "publish: running the leak guard on the candidate"
if ! ( cd "$CAND" && bash scripts/check.sh ); then
  say ""
  say "publish: refused — the candidate does not pass scripts/check.sh."
  say "Each path above is reported inside the candidate; the file to fix is the library's copy:"
  say "  $FROM/<skill>/..."
  say "Fix it there and publish again. Never edit the published copy — it is overwritten by the"
  say "next publish, and the fix would be lost."
  say "This repo was not written to: no commit, no staged change, no new file."
  exit 1
fi

# ------------------------------------------- 4. assert the copy is plain, not a transformation
for s in "${SRC[@]}"; do
  n="$(basename "$s")"
  if ! diff -rq "$s" "$CAND/skills/$n" >/dev/null 2>&1; then
    say "publish: refused — $n differs from its source after copying:"
    diff -rq "$s" "$CAND/skills/$n" || true
    say "A publish is a plain copy. If it needs to rewrite anything, the fix belongs in the library."
    exit 1
  fi
done
say "publish: plain-copy assertion ok — candidate is byte-identical to the source"

CHANGED="$(git -C "$CAND" status --porcelain | wc -l | tr -d ' ')"

if [ "$DRY" -eq 1 ]; then
  say ""
  say "publish: --dry-run, so this repo is untouched. It would change $CHANGED path(s):"
  git -C "$CAND" --no-pager diff --cached --stat
  exit 0
fi

# --------------------------------------------------------------- 5. write it for real
apply_to "$TARGET"
git -C "$TARGET" add -A skills || die "could not stage skills/."

if git -C "$TARGET" diff --cached --quiet; then
  say "publish: nothing to publish."
  exit 0
fi

# The pre-commit hook runs scripts/check.sh --staged here: an independent second gate, on exactly
# the bytes being committed. Never --no-verify.
MSG="chore(skills): publish ${#SRC[@]} ws-* skills from the library"
git -C "$TARGET" commit -q -m "$MSG" || die "the commit was rejected. Nothing was published."
say "publish: committed — $(git -C "$TARGET" rev-parse --short HEAD) $MSG"

if [ "$PUSH" -eq 1 ]; then
  git -C "$TARGET" push origin "$BRANCH" || die "the push failed. The commit is local; retry when the remote is reachable."
  say "publish: pushed to origin/$BRANCH"
else
  say "publish: --no-push, so the commit is local only."
fi

say "publish: done. The scan bounds the patterns in scripts/leak-patterns.txt, not privacy."
