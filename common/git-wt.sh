#!/usr/bin/env bash
# git-wt — create a cone-mode sparse-checkout worktree that materializes only
# the directories you name. All worktrees share the existing .git object store,
# so this NEVER re-clones the repo; sparse-checkout just keeps each worktree's
# on-disk working tree small (root files + the named dirs).
#
# With --deps it also resolves the transitive Bazel dependency packages of the
# named dirs and adds them to the cone, so `bazel build/test` works for those
# targets. (Slower: it runs `bazel query` against the full main worktree.)
#
# Usage:
#   git wt <branch> <dir> [dir...]              Sparse worktree with just <dir...>
#   git wt --deps <branch> <dir> [dir...]       ...plus transitive Bazel dep packages
#   git wt --path <p> <branch> <dir>...         Put the worktree at <p>
#   git wt --list                               List registered worktrees
#   git wt --rm <branch>                        Remove the worktree created for <branch>
#
# Default location: <repo-root>/.claude/worktrees/<branch> (with / -> -)
set -euo pipefail

die() { printf 'git wt: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
git wt — create a sparse-checkout worktree (only the dirs you name; no re-clone)

  git wt <branch> <dir> [dir...]           Sparse worktree with just <dir...>
  git wt --deps <branch> <dir> [dir...]    ...plus transitive Bazel dep packages
  git wt --path <p> <branch> <dir>...      Put the worktree at <p>
  git wt --list                            List registered worktrees
  git wt --rm <branch>                     Remove the worktree created for <branch>

Examples:
  git wt plt-1234/my-fix accounts trading cash
  git wt --deps plt-1234/my-fix accounts        # adds every dir accounts builds against
EOF
}

root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repository"
wt_base="$root/.claude/worktrees"

# Bazel launcher: use bazel/bazelisk on PATH. NOT the repo's tools/bazel — that
# is a wrapper that aborts unless it is itself invoked through bazelisk.
bazel_bin() {
  if command -v bazel >/dev/null 2>&1; then echo bazel
  elif command -v bazelisk >/dev/null 2>&1; then echo bazelisk
  else echo bazel; fi
}

# Print (one per line) the internal package dirs in the transitive Bazel closure
# of the named dirs. Runs in the full main worktree; tolerates dirs with no targets.
resolve_deps() {
  local main_wt bz targets d q
  main_wt="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
  bz="$(bazel_bin)"
  targets=""
  for d in "$@"; do targets="${targets:+$targets + }//$d/..."; done
  q="deps($targets) union buildfiles(deps($targets))"
  # --output=package prints internal pkgs bare (path/to/pkg) and external as @repo//...
  ( cd "$main_wt" && "$bz" query --keep_going --output=package "$q" 2>/dev/null ) \
    | grep -v '^@' | grep -v '^$' | sort -u || true
}

# --- parse leading options -------------------------------------------------
use_deps=0
custom_path=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --list) git worktree list; exit 0 ;;
    --rm)
      [ "${2:-}" ] || die "usage: git wt --rm <branch>"
      safe="${2//\//-}"
      git worktree remove "$wt_base/$safe"
      echo "removed $wt_base/$safe"
      exit 0 ;;
    --deps) use_deps=1; shift ;;
    --path)
      custom_path="${2:-}"
      [ -n "$custom_path" ] || die "--path needs an argument"
      shift 2 ;;
    --) shift; break ;;
    -*) die "unknown option: $1 (try --help)" ;;
    *) break ;;
  esac
done

branch="${1:-}"; shift || true
[ -n "$branch" ] || { usage; exit 1; }
[ $# -ge 1 ] || die "name at least one directory to check out (e.g. accounts trading)"

safe="${branch//\//-}"
path="${custom_path:-$wt_base/$safe}"
[ -e "$path" ] && die "path already exists: $path"

# Warn (don't fail) on dirs that aren't in the tree, so typos surface early.
for d in "$@"; do
  git -C "$root" cat-file -e "HEAD:$d" 2>/dev/null || echo "git wt: warning: '$d' not found at HEAD" >&2
done

# --- build the cone set: named dirs (+ Bazel deps if requested) ------------
cone_file="$(mktemp)"
trap 'rm -f "$cone_file"' EXIT
printf '%s\n' "$@" > "$cone_file"
ndeps=0
if [ "$use_deps" -eq 1 ]; then
  echo "git wt: resolving transitive Bazel deps for: $* (runs bazel query, can take a minute)…" >&2
  dep_file="$(mktemp)"
  resolve_deps "$@" > "$dep_file" || true
  ndeps="$(grep -cve '^$' "$dep_file" || true)"; ndeps="${ndeps:-0}"
  if [ "$ndeps" -gt 0 ]; then
    cat "$dep_file" >> "$cone_file"
    echo "git wt: added $ndeps Bazel dependency package dirs to the cone" >&2
  else
    echo "git wt: no Bazel deps resolved (no targets / bazel unavailable) — using named dirs only" >&2
  fi
  rm -f "$dep_file"
  # Bazel's module/toolchain setup files (MODULE.bazel includes, extension .bzl,
  # toolchains, patches) all live under these roots and load transitively before
  # any target. A target-deps query never sees them, so include them wholesale —
  # they're tiny (~16 MB) and identical for every target. Superset of everything
  # an iterative "load until it resolves" probe would discover.
  for s in third_party tools; do
    if git -C "$root" cat-file -e "HEAD:$s" 2>/dev/null; then echo "$s" >> "$cone_file"; fi
  done
fi
sort -u "$cone_file" -o "$cone_file"
ncone="$(grep -cve '^$' "$cone_file" || true)"; ncone="${ncone:-0}"

# Isolate sparse/checkout config per worktree so the MAIN checkout stays full.
git config extensions.worktreeConfig true

# --- create the worktree without materializing any files -------------------
if git show-ref --verify --quiet "refs/heads/$branch"; then
  git worktree add --no-checkout "$path" "$branch"
elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  git worktree add --no-checkout -b "$branch" "$path" "origin/$branch"
else
  git worktree add --no-checkout -b "$branch" "$path"
fi

# --- narrow to the cone set (via stdin: handles hundreds of dirs) ----------
git -C "$path" sparse-checkout set --cone --stdin < "$cone_file"
# Belt-and-suspenders: ensure in-cone files are written even from --no-checkout.
git -C "$path" checkout --quiet 2>/dev/null || git -C "$path" read-tree -mu HEAD

echo
echo "✓ sparse worktree ready: $path"
echo "  branch:      $branch"
if [ "$use_deps" -eq 1 ] && [ "$ndeps" -gt 0 ]; then
  echo "  cone:        $* + $ndeps Bazel dep dirs = $ncone dirs (+ repo-root files)"
else
  echo "  cone:        $* ($ncone dirs, + repo-root files)"
fi
echo "  object store shared with main repo — nothing was re-cloned"
echo
echo "Adjust dirs later:  git -C \"$path\" sparse-checkout set --cone <dirs>"
if [ "$use_deps" -ne 1 ]; then
  echo "For cross-domain Bazel builds, re-run with --deps to pull transitive dep dirs."
fi
