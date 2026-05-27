# scripts/

Shell utilities for the Godotty development workflow.

| Script | Purpose |
|--------|---------|
| `bump_godotty_node_ref.sh` | Bump the pinned `godotty-node` git ref in `nightly-real.yml` and `install_godotty_node.sh`. See below for the bump procedure. |
| `install_gdunit4.sh` | Download and install GdUnit4 v6.1.3 into `project/addons/gdUnit4/`. |
| `install_godotty_node.sh` | Clone `godotty-node` at `GODOTTY_NODE_REF`, build with `cargo build --release`, install the native library. |
| `lint.sh` | Run gdlint + shellcheck across the project. |
| `ralph_loop.sh` | Driver for the autonomous Ralph Loop. |
| `release.sh` | Cut a release from the `[Unreleased]` CHANGELOG section. |
| `run_tests.sh` | Run the GdUnit4 test suite (headless). |

## Bumping the godotty-node pin

The nightly-real CI workflow pins `godotty-node` at a specific git ref via the
`GODOTTY_NODE_REF` env var in `.github/workflows/nightly-real.yml`. To update
the pin to a new SHA, tag, or branch:

```bash
# 1. Run the bump helper (edits both files, prints a diff):
bash scripts/bump_godotty_node_ref.sh <new-ref>

# 2. Review the diff, then commit:
git add .github/workflows/nightly-real.yml scripts/install_godotty_node.sh
git commit -m "chore(ci): bump godotty-node ref to <new-ref>"
git push
```

Then go to **Actions → Nightly Real-mode CI → Run workflow** and verify:
- The "Resolve godotty-node ref" step prints `Using godotty-node ref: <new-ref>`.
- The build-and-test job completes green.

Static tests in `tests/ci/workflow_contains_ref_test.sh` assert the invariants
(workflow has the env var, install script references it, bump script exists).
