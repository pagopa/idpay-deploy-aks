#!/usr/bin/env bash
set -euo pipefail

# Script to clean Helm projects by removing `Chart.lock` files and `chart`/`charts` directories.
# Usage: ./clean-helm-artifacts.sh [starting_path]
#  - If omitted, the starting path defaults to the current directory.
#  - Example: ./clean-helm-artifacts.sh ./deployments/helm-project
# The script validates the path, prints what it removes, and stops at the first error.

# Removes Helm dependency artifacts (Chart.lock files and chart/charts directories)
# starting from the provided directory (default: current working directory).

TARGET_ROOT="${1:-$PWD}"

if [[ ! -d "$TARGET_ROOT" ]]; then
  echo "Provided path '$TARGET_ROOT' is not a directory." >&2
  exit 1
fi

# Resolve to an absolute path for clearer logging
TARGET_ROOT="$(cd "$TARGET_ROOT" && pwd)"

echo "🧹 Removing Chart.lock files under '$TARGET_ROOT'..."
find "$TARGET_ROOT" -type f -name 'Chart.lock' -print -delete

echo "🗂️ Scanning for chart directories under '$TARGET_ROOT'..."
if ! find "$TARGET_ROOT" -type d \( -name 'chart' -o -name 'charts' \) -print -quit | grep -q .; then
  echo "✅ No chart directories found."
else
  find "$TARGET_ROOT" -type d \( -name 'chart' -o -name 'charts' \) -print0 \
    | while IFS= read -r -d '' dir; do
        echo "🚮 Deleting directory: $dir"
        rm -rf "$dir"
      done
fi

echo "✨ Cleanup complete."
