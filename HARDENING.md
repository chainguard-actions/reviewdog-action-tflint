<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-tflint/v1.25.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-tflint/v1.25.0** was hardened automatically. 4 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remotely fetched install script directly to `sh` without first saving it to a file for inspection. Pattern: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b ...`. Even though the URL is commit-pinned, piping remote content directly to a shell interpreter is an unsafe-shell pattern.

Locations:

- `script.sh:44`

### unpinned-uses (severity: high)

labels.yml uses `actions/checkout@master` — a mutable branch ref rather than a full 40-character commit SHA. This allows the referenced action to change without notice, enabling supply-chain attacks.

Locations:

- `.github/workflows/labels.yml:18`

### script-injection (severity: high)

tests.yml directly interpolates `${{ steps.test.outputs.tflint-return-code }}` and `${{ steps.test.outputs.reviewdog-return-code }}` inside `run:` shell command blocks (sub-rule a). These `steps.*.outputs.*` expressions are substituted by the GitHub Actions template engine before the shell sees them, allowing an attacker who can influence action outputs to inject arbitrary shell commands. The pattern repeats across all 7 test jobs in the file.

Locations:

- `.github/workflows/tests.yml:33`
- `.github/workflows/tests.yml:34`
- `.github/workflows/tests.yml:88`
- `.github/workflows/tests.yml:89`
- `.github/workflows/tests.yml:143`
- `.github/workflows/tests.yml:144`
- `.github/workflows/tests.yml:196`
- `.github/workflows/tests.yml:197`
- `.github/workflows/tests.yml:251`
- `.github/workflows/tests.yml:252`

### missing-permissions (severity: medium)

None of the workflow files define a top-level `permissions:` key, and no individual job defines its own `permissions:` block. Without explicit permissions, workflows run with the default (potentially broad) token permissions.

Locations:

- `.github/workflows/depup.yml:1`
- `.github/workflows/labels.yml:1`
- `.github/workflows/lint.yml:1`
- `.github/workflows/release.yml:1`
- `.github/workflows/tests.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, unpinned-uses, script-injection, missing-permissions

**Notes:**

1. script.sh (unsafe-shell): Replaced `curl ... | sh -s -- -b ...` with a two-step approach: download install script to a temp file with `curl -sfL ... -o`, then execute with `sh script -b ...` (dropping the `--` which was only the shell's option terminator in the pipe form). 2. labels.yml (unpinned-uses): Pinned `actions/checkout@master` to full SHA `61b9e3751b92087fd0b06925ba6dd6314e06f089 # master`. 3. tests.yml (script-injection): In all 7 test jobs, moved `${{ steps.test.outputs.tflint-return-code }}` and `${{ steps.test.outputs.reviewdog-return-code }}` from inline `run:` shell strings into `env:` blocks as `TFLINT_RETURN_CODE` and `REVIEWDOG_RETURN_CODE`, referenced as plain env vars in the shell. 4. missing-permissions (all 5 workflows): Added top-level `permissions:` blocks — depup.yml: `contents: read`; labels.yml: `contents: read, issues: write`; lint.yml: `contents: read, checks: write, pull-requests: write`; release.yml: `contents: write, pull-requests: write`; tests.yml: `contents: read, checks: write, pull-requests: write`.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed two unquoted shell variable expansions in script.sh:
1. Line 64: Replaced `for RULESET in ${INPUT_TFLINT_RULESETS}` with xargs-based tokenization into a TFLINT_RULESETS bash array (with empty-guard), then iterated with `"${TFLINT_RULESETS[@]}"`.
2. Line 112: Replaced unquoted `${INPUT_FLAGS}` and `${CHDIR_COMMAND}` with properly guarded bash arrays. INPUT_FLAGS is tokenized via xargs into INPUT_FLAGS_ARGS; CHDIR_COMMAND is replaced by CHDIR_ARGS array. Both are expanded as quoted array expansions in the tflint invocation. The shellcheck disable comment was removed as it is no longer needed.

