#!/usr/bin/env bash
# Replace the first ```mermaid block in README.md with the contents of
# diagrams/network.mmd. Used by the pre-commit hook to keep them in sync.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
MMD="diagrams/network.mmd"
README="README.md"

[ -f "$MMD" ] && [ -f "$README" ] || exit 0

python3 - "$MMD" "$README" <<'PY'
import pathlib, re, sys
mmd_path, readme_path = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
mmd = mmd_path.read_text().rstrip()
readme = readme_path.read_text()
new_block = "```mermaid\n" + mmd + "\n```"
pattern = re.compile(r"```mermaid\n.*?\n```", re.DOTALL)
if not pattern.search(readme):
    sys.exit(0)
updated = pattern.sub(new_block, readme, count=1)
if updated != readme:
    readme_path.write_text(updated)
PY

if ! git diff --quiet -- "$README"; then
    git add "$README"
    echo "[pre-commit] synced README diagram from $MMD"
fi
