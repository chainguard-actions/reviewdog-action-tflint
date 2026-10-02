<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-tflint/v1.28.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-tflint/v1.28.0** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remote install script directly to `sh` without first downloading it to a file for inspection. The pattern `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/.../install.sh | sh -s -- -b ...` executes remote content directly in a shell. Even though the URL contains a pinned commit SHA in the path, the content is still streamed and executed without any integrity verification step.

Locations:

- `script.sh:47`

### script-injection (severity: high)

Rule (b): Unquoted shell variable expansions of workflow-controllable inputs in script.sh. (1) `${INPUT_FLAGS}` (sourced from `inputs.flags`) and `${CHDIR_COMMAND}` (derived from `inputs.tflint_target_dir`) are used unquoted in the tflint command line: `"${TFLINT_PATH}/tflint" -c "${INPUT_TFLINT_CONFIG}" ${INPUT_FLAGS} ${CHDIR_COMMAND} --format=checkstyle`. An attacker-controlled value in `inputs.flags` containing shell metacharacters (`;`, `|`, `&`, `$(...)`) can break out of the intended command. (2) `for RULESET in ${INPUT_TFLINT_RULESETS}` performs unquoted word-splitting on the workflow-controlled `inputs.tflint_rulesets` input, allowing glob expansion and shell metacharacter injection.

Locations:

- `script.sh:57`
- `script.sh:90`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

Fixed three issues in script.sh:
1. unsafe-shell (line 47): Replaced `curl ... | sh -s -- -b ...` with a two-step approach: download the reviewdog install script to a temp file (`${TEMP_PATH}/reviewdog-install.sh`), then execute it with `sh "${REVIEWDOG_INSTALL_SCRIPT}" -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}"`. The `--` was dropped since it was the shell's option terminator in the pipe form, not the script's argument.
2. script-injection (line 57 - INPUT_TFLINT_RULESETS): Replaced `for RULESET in ${INPUT_TFLINT_RULESETS}` (unquoted word-splitting) with a guarded `if [ -n ... ]` block using `printf '%s' "${INPUT_TFLINT_RULESETS}" | xargs printf '%s\0'` piped into a `while IFS= read -r -d '' RULESET` loop for safe, quote-aware tokenization.
3. script-injection (line 90 - INPUT_FLAGS and CHDIR_COMMAND): Replaced unquoted `${INPUT_FLAGS}` and `${CHDIR_COMMAND}` with bash arrays: `chdir_args=()` populated conditionally with `("--chdir=${INPUT_TFLINT_TARGET_DIR}")`, and `flags_args=()` populated via the xargs/NUL-delimited tokenization pattern with a guard. Both arrays are expanded as `"${flags_args[@]}"` and `"${chdir_args[@]}"` in the tflint command.

