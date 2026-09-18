<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-tflint/v1.27.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-tflint/v1.27.0** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remotely fetched install script directly to `sh` without first saving it to a file for inspection. The command `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}"` executes whatever the remote server returns in a shell. Even though the URL is pinned to a commit SHA, this pattern is inherently unsafe as it bypasses any opportunity to verify the downloaded content before execution.

Locations:

- `script.sh:44`

### script-injection (severity: high)

Rule (b) violation — unquoted shell variable expansions of untrusted inputs allow word-splitting and shell metacharacter injection:

1. Line 57: `for RULESET in ${INPUT_TFLINT_RULESETS}; do` — `INPUT_TFLINT_RULESETS` is sourced from `inputs.tflint_rulesets` (attacker-controlled) and is expanded unquoted, enabling glob expansion and word-splitting attacks.

2. Line 100: `"${TFLINT_PATH}/tflint" ... --format=checkstyle ${INPUT_FLAGS} ${CHDIR_COMMAND}` — both `${INPUT_FLAGS}` (from `inputs.flags`) and `${CHDIR_COMMAND}` (derived from `inputs.tflint_target_dir`) are expanded unquoted, allowing shell metacharacters in those values to be interpreted by the shell. These should be quoted as `"${INPUT_FLAGS}"` and `"${CHDIR_COMMAND}"` (or use an array).

Locations:

- `script.sh:57`
- `script.sh:100`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

Fixed three issues in script.sh:
1. (unsafe-shell, line 44) Replaced `curl ... | sh -s -- -b ...` with: download install script to a temp file via `curl ... -o`, then execute with `sh "$SCRIPT" -b ...` (dropped the '--' as it was the shell's option terminator, not the script's argument).
2. (script-injection, line 57) Replaced unquoted `for RULESET in ${INPUT_TFLINT_RULESETS}` with a guarded xargs NUL-delimited tokenization loop: `if [ -n "${INPUT_TFLINT_RULESETS}" ]; then while IFS= read -r -d '' RULESET; do ... done < <(printf '%s' "${INPUT_TFLINT_RULESETS}" | xargs printf '%s\0'); fi`.
3. (script-injection, line 100) Tokenized INPUT_FLAGS (a list/args input) into a bash array `tflint_flags` via xargs, and used `${CHDIR_COMMAND:+"${CHDIR_COMMAND}"}` for the single optional CHDIR_COMMAND value. Removed the `# shellcheck disable=SC2086` comment that was suppressing the warning.

