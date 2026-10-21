#!/usr/bin/env bash
# Usage: ./repro.sh [path/to/pnpm]   (defaults to the pnpm on PATH)
set -euo pipefail

pnpm=${1:-pnpm}
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -R "$here/package.json" "$here/pnpm-workspace.yaml" "$here/patches" "$work/"
cd "$work"

echo "pnpm $("$pnpm" --version)"
"$pnpm" install --reporter=append-only >/dev/null

inode() { ls -di "node_modules/$1" | awk '{print $1}'; }
react_before=$(inode react)
react_dom_before=$(inode react-dom)

# Any install that reaches the linker shows it; adding one unrelated,
# dependency-free package is the plainest way to get there.
"$pnpm" add is-number@7.0.0 --reporter=append-only | grep -E '^Packages:'

status=0
for pkg in react react-dom; do
  before_var="${pkg//-/_}_before"
  if [ "$(inode "$pkg")" = "${!before_var}" ]; then
    echo "ok:   node_modules/$pkg was left in place"
  else
    echo "FAIL: node_modules/$pkg was imported again"
    status=1
  fi
done
[ -f node_modules/react/PATCHED.md ] || { echo "FAIL: the patch is no longer applied to react"; status=1; }
exit $status
