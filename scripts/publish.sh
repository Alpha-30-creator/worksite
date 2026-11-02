#!/usr/bin/env bash
# worksite publish: copy the generic ws-* skills out of the agent-sync library into this
# repo, prove they carry no known private name, then commit and push.
#
#   scripts/publish.sh                  publish from the default library
#   scripts/publish.sh --from <dir>     publish from another skills directory (a worktree, a fixture)
#   scripts/publish.sh --dry-run        stop before writing to this repo; print what would change
#   scripts/publish.sh --prune          allow removing a skill the source no longer has
#   scripts/publish.sh --prune-many     also allow removing more than a third of what is published
#   scripts/publish.sh --allow-extra    allow a non-Markdown file inside a skill directory
#   scripts/publish.sh --no-push        commit, but do not push (for exercising the commit path)
#
# Exit 0 = published, or nothing to publish. Non-zero = refused, and this repo is left exactly as
# it was found: same HEAD, clean index, clean working tree.
#
# Why it works this way:
#
#   * The source is the glob `ws-*` inside the library's skills/ — never the library directory
#     and never anything git-level. The library's history holds the author's private project
#     packs, and the glob keeps them out. It does so by the library's **naming convention**, not
#     by any property of the filesystem: a private pack named `ws-something` would be copied, so
#     review has to keep that convention true.
#   * The candidate is assembled in a throwaway `git clone` of this repo and checked there, so a
#     refusal happens before a single byte is written here.
#   * `scripts/check.sh` is git-aware, so a candidate has to sit inside a git repo to be scanned
#     at all. That is the second reason for the clone.
#   * The copy is asserted to be plain: `diff -rq` source against copy must be silent. If it ever
#     is not, this script transformed something and must fail — publishing is a copy.
#   * The guard and that assertion then run a SECOND time against this repo's own staged tree,
#     because the candidate and the real copy are two independent copies from a source that can
#     change in between. The bytes that get committed are the bytes that get checked.
#   * From the first write to this repo until the commit succeeds, any failure restores the repo
#     to the HEAD and the clean tree it was found with, and says so.
#
# What a green run does NOT mean: the scan bounds the patterns listed in
# scripts/leak-patterns.txt. A private name nobody has added to that file passes it, and a secret
# is not a name at all. Green means "no known pattern", never "no private data".
set -uo pipefail

TARGET="$(cd "$(dirname "$0")/.." && pwd)"
FROM="$HOME/.agent-sync/store/skills"
DRY=0
PRUNE=0
PRUNE_MANY=0
ALLOW_EXTRA=0
PUSH=1
BRANCH="main"
WROTE=0
PRE_HEAD=""

say() { printf '%s\n' "$*"; }
die() { printf 'publish: refused — %s\n' "$*" >&2; exit 1; }

# Restore this repo to what it was found with. A no-op unless a write has happened and no commit
# has landed yet. Preflight refused a dirty tree, so there is nothing of anyone else's to lose.
restore_target() {
  [ "$WROTE" -eq 1 ] || return 0
  WROTE=0
  git -C "$TARGET" reset -q --hard "$PRE_HEAD" >/dev/null 2>&1
  git -C "$TARGET" clean -qfd -- skills >/dev/null 2>&1
  local h st
  h="$(git -C "$TARGET" rev-parse HEAD 2>/dev/null)"
  st="$(git -C "$TARGET" status --porcelain 2>/dev/null)"
  if [ "$h" = "$PRE_HEAD" ] && [ -z "$st" ]; then
    say "publish: this repo was restored — HEAD $(git -C "$TARGET" rev-parse --short HEAD), index clean, tree clean, nothing committed."
  else
    say "publish: WARNING — could not fully restore this repo. Expected HEAD $PRE_HEAD and a clean"
    say "tree; got $h and [$st]. Reset it by hand before publishing again."
  fi
  return 0
}

# Fail after a write: put the repo back first, then refuse.
die_restore() { restore_target; die "$*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --from) [ $# -ge 2 ] || die "--from needs a directory"; FROM="$2"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --prune) PRUNE=1; shift ;;
    --prune-many) PRUNE=1; PRUNE_MANY=1; shift ;;
    --allow-extra) ALLOW_EXTRA=1; shift ;;
    --no-push) PUSH=0; shift ;;
    -h|--help) sed -n '2,/^# Exit 0/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument '$1'" ;;
  esac
done

# ------------------------------------------------------------------ 1. preflight
# Every one of these refuses before anything is copied anywhere.

[ -d "$FROM" ] || die "no skills directory at $FROM. Nothing to publish from."

SRC=()
for d in "$FROM"/ws-*/; do
  [ -d "$d" ] || continue
  d="${d%/}"
  [ -L "$d" ] && die "$d is a symlink. A published skill must be a real directory."
  SRC+=("$d")
done
[ "${#SRC[@]}" -gt 0 ] || die "$FROM holds no ws-* skill directories."

# A symlink inside a skill directory is the one thing the clone scan cannot see: check.sh's
# working-tree mode reads content with `cat`, which follows the link and never sees the link's
# own path string, while git commits a blob whose content IS that path. So an absolute filesystem
# path would reach a public repo with the pattern file never consulted. Refuse it here instead.
for s in "${SRC[@]}"; do
  links="$(find "$s" -type l 2>/dev/null)"
  if [ -n "$links" ]; then
    say "publish: refused — symlink(s) inside $(basename "$s"):" >&2
    printf '%s\n' "$links" | sed 's|^|  |' >&2
    die "a symlink publishes a filesystem path as file content, and the guard cannot read it. Replace it with the real file."
  fi
done

# Everything inside a skill directory is published, and the guard is a list of private NAMES,
# not a secret scanner: an .env, an editor backup, a .DS_Store or a stray agent artifact would
# sail straight through it into a public repo. So the contents are classified here.
#
#   .md                                 the pack itself — published silently
#   the data extensions below           the pack's own reference data — published, and LISTED
#                                       on every run, because a secret can wear any extension
#   a path named in PACK_EXEC below     the pack's own executable files — published, and LISTED,
#                                       by EXACT relative path and never by extension
#   a dotfile or dot-directory          REFUSED
#   anything else                       REFUSED
#
# A refusal is lifted only by --allow-extra, which then names every file it let through. The
# listing is the point: these files are few and the list is short enough to read each time.
EXTRA=""
DATA=""
EXEC=""
# Executable files the pack legitimately ships, by EXACT relative path. Deliberately not a
# `*.sh` glob: a stray install script or a credential-bearing helper dropped into the library
# would then publish itself, which is the whole failure this classification exists to prevent.
# Adding a file here is a decision, and it is made once, in the open, in this list.
#
# ws-refine/audit.sh is a file rather than a fenced block in its SKILL.md because a skill's body
# has the caller's argument substituted into its positional parameters on delivery, which broke
# the awk programs inside it (p8.37). Nothing substitutes into a file run by path.
PACK_EXEC="ws-refine/audit.sh"
for s in "${SRC[@]}"; do
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    # Classify the path RELATIVE to the source. The source itself lives under a dot-directory
    # (`~/.agent-sync/…`), so testing the absolute path for a dot segment would condemn every
    # file in the library.
    rel="${f#"$FROM"/}"
    case "$rel" in
      .*|*/.*) EXTRA="$EXTRA$rel
" ;;
      *.md) ;;
      *.tsv|*.csv|*.yaml|*.yml|*.json|*.txt) DATA="$DATA$rel
" ;;
      *)
        # A whole-field match against the list, so "ws-refine/audit.sh.bak" is NOT forgiven.
        if printf '%s\n' "$PACK_EXEC" | grep -qxF -- "$rel"; then
          EXEC="$EXEC$rel
"
        else
          EXTRA="$EXTRA$rel
"
        fi ;;
    esac
  done < <(find "$s" ! -type d 2>/dev/null)
done
if [ -n "$EXTRA" ]; then
  if [ "$ALLOW_EXTRA" -eq 0 ]; then
    say "publish: refused — a skill directory holds files that are neither pack Markdown nor" >&2
    say "known reference data. Everything in it is published, so each of these would go public:" >&2
    printf '%s' "$EXTRA" | sed 's|^|  |' >&2
    die "remove them from the library, or pass --allow-extra if every one of them is meant to be public."
  fi
  say "publish: --allow-extra, so these WILL be published although they are not pack files:"
  printf '%s' "$EXTRA" | sed 's|^|  |'
fi

git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 || die "$TARGET is not a git repository."

cur="$(git -C "$TARGET" rev-parse --abbrev-ref HEAD 2>/dev/null)"
[ "$cur" = "$BRANCH" ] || die "this repo is on '$cur', not '$BRANCH'. A publish commits to $BRANCH."

[ -z "$(git -C "$TARGET" status --porcelain)" ] \
  || die "this repo's working tree is dirty. A publish must not sweep up an unrelated edit."

[ -f "$TARGET/scripts/check.sh" ] \
  || die "no scripts/check.sh here. The guard is not optional, so there is nothing to publish into."

# The pre-commit hook is one of this path's gates, and a hook that is not installed is silent:
# the commit simply lands unchecked. core.hooksPath is a per-clone setting, so check it rather
# than assume it.
hp="$(git -C "$TARGET" config --get core.hooksPath 2>/dev/null || true)"
if [ -n "$hp" ]; then
  case "$hp" in /*) HOOK="$hp/pre-commit" ;; *) HOOK="$TARGET/$hp/pre-commit" ;; esac
else
  HOOK="$(git -C "$TARGET" rev-parse --absolute-git-dir 2>/dev/null)/hooks/pre-commit"
fi
[ -x "$HOOK" ] || die "no executable pre-commit hook at $HOOK. Install it with: git config core.hooksPath .githooks"

if ! ( cd "$TARGET" && bash scripts/check.sh >/dev/null 2>&1 ); then
  say "publish: refused — scripts/check.sh is already failing on this repo as it stands."
  say "Fix that first; publishing on top of a red tree hides which change broke it. Its output:"
  ( cd "$TARGET" && bash scripts/check.sh ) || true
  exit 1
fi

# Orphans: published here, absent from the source. Deleting a skill needs an explicit yes, so a
# mechanical copy must never be the thing that performs it.
ORPHANS=()
PUBLISHED=0
for d in "$TARGET"/skills/ws-*/; do
  [ -d "$d" ] || continue
  PUBLISHED=$((PUBLISHED + 1))
  n="$(basename "${d%/}")"
  [ -d "$FROM/$n" ] || ORPHANS+=("$n")
done
if [ "${#ORPHANS[@]}" -gt 0 ]; then
  if [ "$PRUNE" -eq 0 ]; then
    say "publish: refused — published here but absent from $FROM:" >&2
    for n in "${ORPHANS[@]}"; do say "  $n" >&2; done
    die "removing a published skill is a deletion, not a copy. Re-run with --prune to mean it."
  fi
  # --prune is one flag away from a typo in --from wiping the pack. Name the deletions, and make
  # a large one need a second, separate yes.
  say "publish: --prune, so these ${#ORPHANS[@]} published skill(s) WILL BE DELETED:"
  for n in "${ORPHANS[@]}"; do say "  $n"; done
  if [ $((${#ORPHANS[@]} * 3)) -gt "$PUBLISHED" ] && [ "$PRUNE_MANY" -eq 0 ]; then
    say "publish: refused — that is ${#ORPHANS[@]} of $PUBLISHED published skills, more than a third." >&2
    say "A wrong --from looks exactly like this. Check the source, then pass --prune-many too." >&2
    exit 1
  fi
fi

say "publish: ${#SRC[@]} ws-* skill(s) from $FROM"
for s in "${SRC[@]}"; do
  printf '  %-14s %s file(s)\n' "$(basename "$s")" "$(find "$s" -type f | wc -l | tr -d ' ')"
done
if [ -n "$DATA" ]; then
  say "publish: reference data files included in this publish — read the list, the guard cannot:"
  printf '%s' "$DATA" | sed 's|^|  |'
fi
if [ -n "$EXEC" ]; then
  say "publish: executable pack files in this publish — code, so read the diff and not just the name:"
  printf '%s' "$EXEC" | sed 's|^|  |'
fi

# ---------------------------------------------------- 2. assemble the candidate in a clone
TMP="$(mktemp -d "${TMPDIR:-/tmp}/worksite-publish.XXXXXX")" || die "could not make a temp directory."
cleanup() {
  restore_target
  [ -n "${TMP:-}" ] && rm -rf "$TMP"
  return 0
}
trap cleanup EXIT

CAND="$TMP/candidate"
git clone --no-hardlinks --quiet "$TARGET" "$CAND" || die "could not clone this repo to check a candidate."

apply_to() {
  # Replace dest/skills/ws-* wholesale with the source's ws-* directories.
  local dest="$1"
  mkdir -p "$dest/skills" || return 1
  local d s
  for d in "$dest"/skills/ws-*/; do
    [ -d "$d" ] || continue
    rm -rf "$d" || return 1
  done
  for s in "${SRC[@]}"; do cp -Rp "$s" "$dest/skills/" || return 1; done
  return 0
}

assert_plain_copy() { # assert_plain_copy <dest> — the copy must be byte-identical to the source
  local dest="$1" s n
  for s in "${SRC[@]}"; do
    n="$(basename "$s")"
    if ! diff -rq "$s" "$dest/skills/$n" >/dev/null 2>&1; then
      say "publish: $n differs from its source after copying:"
      diff -rq "$s" "$dest/skills/$n" || true
      return 1
    fi
  done
  return 0
}

apply_to "$CAND" || die "could not assemble the candidate."

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
# --no-object-store: section 6 reads the UNREACHABLE objects in .git/objects, and this is a
# throwaway clone. A local clone copies the whole object store but not the reflogs, and git fsck
# treats reflog entries as roots — so everything the source's reflog was holding arrives here
# unreachable. Measured 2026-11-03: the source reports 29 unreachable blobs and 0 undeclared,
# this clone reports 46 blobs / 105 trees / 51 commits, including a pre-p2.2 skill version that
# is reachable in main's history and correctly ignored there. Gating the publish on that is
# gating it on the author's reflog rather than on the bytes being published (p8.38).
#
# The target repo's own object store is NOT let off: the preflight above and the --staged run
# below both run the full six sections against it, as do the pre-commit hook and CI. And the
# skip announces itself — check.sh prints which section it did not run and why, and its closing
# line says so too, so a publish log can never read as a clean six-section pass.
if ! ( cd "$CAND" && bash scripts/check.sh --no-object-store ); then
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
if ! assert_plain_copy "$CAND"; then
  die "a publish is a plain copy. If it needs to rewrite anything, the fix belongs in the library."
fi
say "publish: plain-copy assertion ok — candidate is byte-identical to the source"

CHANGED="$(git -C "$CAND" status --porcelain | wc -l | tr -d ' ')"

if [ "$DRY" -eq 1 ]; then
  say ""
  say "publish: --dry-run, so this repo is untouched. It would change $CHANGED path(s):"
  git -C "$CAND" --no-pager diff --cached --stat
  exit 0
fi

# --------------------------------------------------------------- 5. write it for real
# From here until the commit lands, every failure path goes through die_restore.
PRE_HEAD="$(git -C "$TARGET" rev-parse HEAD)" || die "could not read this repo's HEAD."
WROTE=1
apply_to "$TARGET" || die_restore "could not copy the skills into this repo."
git -C "$TARGET" add -A skills || die_restore "could not stage skills/."

if git -C "$TARGET" diff --cached --quiet; then
  restore_target
  say "publish: nothing to publish."
  exit 0
fi

# The candidate and this copy are two independent copies from a source that can change in
# between, and nothing has yet checked what is actually about to be committed. So the guard and
# the plain-copy assertion both run again, here, against the staged tree. --staged mode reads
# blobs with `git show`, which also sees a symlink's own path rather than following it.
say "publish: re-running the guard on the staged tree — the bytes that will be committed"
if ! ( cd "$TARGET" && bash scripts/check.sh --staged ); then
  say ""
  say "publish: the staged tree does not pass scripts/check.sh --staged."
  die_restore "the fix belongs in the library at $FROM, never in the published copy."
fi
if ! assert_plain_copy "$TARGET"; then
  die_restore "a publish is a plain copy. If it needs to rewrite anything, the fix belongs in the library."
fi
say "publish: staged tree ok — guarded and byte-identical to the source"

# The pre-commit hook runs scripts/check.sh --staged once more here, on exactly the bytes being
# committed, independently of this script. Never --no-verify.
MSG="chore(skills): publish ${#SRC[@]} ws-* skills from the library"
git -C "$TARGET" commit -q -m "$MSG" || die_restore "the commit was rejected."
WROTE=0
say "publish: committed — $(git -C "$TARGET" rev-parse --short HEAD) $MSG"

if [ "$PUSH" -eq 1 ]; then
  git -C "$TARGET" push origin "$BRANCH" \
    || die "the push failed. The commit is local and still here; retry when the remote is reachable."
  say "publish: pushed to origin/$BRANCH"
else
  say "publish: --no-push, so the commit is local only."
fi

say "publish: done. The scan bounds the patterns in scripts/leak-patterns.txt, not privacy."
