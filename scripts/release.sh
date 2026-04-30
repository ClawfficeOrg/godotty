#!/usr/bin/env bash
# Cut a release of godotty.
#
# Usage:
#   scripts/release.sh v0.2.0
#   scripts/release.sh --dry-run v0.2.0
#
# Steps:
#   1. Verify clean working tree on master, up to date with origin/master.
#   2. Run scripts/run_tests.sh.
#   3. Promote CHANGELOG [Unreleased] -> [vX.Y.Z] - YYYY-MM-DD; add empty Unreleased.
#   4. Commit chore(release): vX.Y.Z.
#   5. Tag (signed if GPG available, annotated otherwise).
#   6. Push master --follow-tags.
#   7. Create GitHub release via gh.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DRY_RUN=0
VERSION=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--dry-run) DRY_RUN=1; shift ;;
		v[0-9]*)   VERSION="$1"; shift ;;
		*)         echo "unknown arg: $1" >&2; exit 2 ;;
	esac
done

if [[ -z "$VERSION" ]]; then
	echo "usage: scripts/release.sh [--dry-run] vX.Y.Z" >&2
	exit 2
fi

# Validate semver (vMAJOR.MINOR.PATCH, optionally with -pre/+meta)
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
	echo "release: '$VERSION' is not a valid semver tag (vX.Y.Z)" >&2
	exit 2
fi

run() {
	if [[ "$DRY_RUN" == 1 ]]; then
		echo "[dry-run] $*"
	else
		eval "$@"
	fi
}

# 1. Clean tree, on master, up to date
if ! git diff-index --quiet HEAD --; then
	echo "release: working tree is dirty" >&2
	exit 1
fi
branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$branch" != "master" ]]; then
	echo "release: not on master (currently $branch)" >&2
	exit 1
fi
git fetch origin master
if [[ "$(git rev-parse HEAD)" != "$(git rev-parse origin/master)" ]]; then
	echo "release: local master differs from origin/master" >&2
	exit 1
fi

# 2. Tests
run "scripts/run_tests.sh"

# 3. Promote CHANGELOG
TODAY="$(date -u +%Y-%m-%d)"
if [[ ! -f CHANGELOG.md ]]; then
	echo "release: CHANGELOG.md missing" >&2
	exit 1
fi

if ! grep -q '^## \[Unreleased\]' CHANGELOG.md; then
	echo "release: CHANGELOG.md has no [Unreleased] section" >&2
	exit 1
fi

new_unreleased="## [Unreleased]\n\n### Added\n\n### Changed\n\n### Fixed\n\n### Removed\n\n## [${VERSION#v}] — ${TODAY}"

if [[ "$DRY_RUN" == 1 ]]; then
	echo "[dry-run] would replace [Unreleased] with promoted block in CHANGELOG.md"
else
	# In-place replace, preserving existing Unreleased contents under the new versioned heading.
	python3 - <<PY
import re, pathlib
p = pathlib.Path("CHANGELOG.md")
s = p.read_text()
new = "## [Unreleased]\n\n### Added\n\n### Changed\n\n### Fixed\n\n### Removed\n\n## [${VERSION#v}] — ${TODAY}"
s = re.sub(r"^## \[Unreleased\]", new, s, count=1, flags=re.M)
p.write_text(s)
PY
fi

# 4. Commit
run "git add CHANGELOG.md"
run "git commit -m 'chore(release): ${VERSION}'"

# 5. Tag
if gpg --list-secret-keys >/dev/null 2>&1 && [[ -n "$(git config user.signingkey || true)" ]]; then
	run "git tag -s '${VERSION}' -m '${VERSION}'"
else
	run "git tag -a '${VERSION}' -m '${VERSION}'"
fi

# 6. Push
run "git push origin master --follow-tags"

# 7. GitHub release
notes_file="$(mktemp)"
trap 'rm -f "$notes_file"' EXIT

if [[ "$DRY_RUN" != 1 ]]; then
	# Extract this version's section from CHANGELOG
	awk -v v="${VERSION#v}" '
		$0 ~ "^## \\["v"\\]" {flag=1; next}
		flag && /^## / {exit}
		flag {print}
	' CHANGELOG.md > "$notes_file"
fi

if command -v gh >/dev/null 2>&1; then
	run "gh release create '${VERSION}' --title '${VERSION}' --notes-file '$notes_file'"
else
	echo "release: gh not installed, skipping GitHub release creation"
fi

echo "release: ${VERSION} done."
