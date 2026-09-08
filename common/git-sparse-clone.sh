#!/usr/bin/env bash
# git-sparse-clone — blobless partial clone + cone-mode sparse-checkout.
# Downloads commits and trees but fetches file blobs on demand (--filter=blob:none),
# and checks out only the named top-level dirs. Gives you a small, fast fresh clone
# of a big monorepo instead of the full ~5+ GB working tree and full history blobs.
#
# Usage:
#   git sparse-clone <url> <dest> <dir> [dir...]
#   git sparse-clone --treeless <url> <dest> <dir> [dir...]   # filter trees too (leanest, slower history ops)
#
# Example:
#   git sparse-clone git@github.com:apex-fintech-solutions/source.git source accounts trading
set -euo pipefail

die() { printf 'git sparse-clone: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
git sparse-clone — blobless partial clone with sparse-checkout (small fresh clone)

  git sparse-clone <url> <dest> <dir> [dir...]
  git sparse-clone --treeless <url> <dest> <dir> [dir...]

  <url>   repo to clone (e.g. git@github.com:apex-fintech-solutions/source.git)
  <dest>  target directory (must not exist)
  <dir>   one or more top-level dirs to check out (cone mode)

Options:
  --treeless   use --filter=tree:0 (leanest clone; trees fetched on demand —
               cheaper disk, but history/blame ops fetch more later)

Example:
  git sparse-clone git@github.com:apex-fintech-solutions/source.git source accounts trading
EOF
}

filter="blob:none"
case "${1:-}" in
  ""|-h|--help) usage; exit 0 ;;
  --treeless) filter="tree:0"; shift ;;
  --blobless) filter="blob:none"; shift ;;
esac

url="${1:-}"; shift || true
dest="${1:-}"; shift || true
[ -n "$url" ]  || die "missing <url>"
[ -n "$dest" ] || die "missing <dest>"
[ $# -ge 1 ]   || die "name at least one directory to check out (e.g. accounts trading)"
[ -e "$dest" ] && die "destination already exists: $dest"

# Partial clone (no blobs yet) without materializing the working tree.
git clone --filter="$filter" --no-checkout "$url" "$dest"
# Narrow to the named dirs, then materialize just those (fetches only their blobs).
git -C "$dest" sparse-checkout set --cone "$@"
git -C "$dest" checkout

echo
echo "✓ sparse blobless clone ready: $dest"
echo "  filter:      --filter=$filter"
echo "  checked out: $* (+ repo-root files)"
echo "  history is present; file blobs are fetched on demand as you read them"
echo
echo "Add dirs later:        git -C \"$dest\" sparse-checkout set --cone <dirs>"
echo "Make sparse worktrees: cd \"$dest\" && git wt <branch> <dir>...   (git wt --deps for Bazel deps)"
echo
echo "Note: Bazel needs every package a target depends on present on disk. Dep"
echo "      resolution (git wt --deps) needs those BUILD files checked out, so run"
echo "      it from a full/wide checkout, or widen the cone before building cross-domain."
