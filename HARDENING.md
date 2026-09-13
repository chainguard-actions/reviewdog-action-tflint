<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-tflint/v1.26.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-tflint/v1.26.0** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remote install script directly to `sh` without first downloading and verifying it. The pattern `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- ...` executes whatever content is served at that URL in the runner shell. Even though the URL references a specific commit SHA in the path, the content is still fetched and executed in a single pipeline without any integrity check (e.g. checksum verification), making this an unsafe-shell pattern.

Locations:

- `script.sh:44`

### script-injection (severity: high)

Rule (b) — unquoted shell variable expansions of untrusted inputs allow shell metacharacter injection.

1. `for RULESET in ${INPUT_TFLINT_RULESETS}` (line 57): INPUT_TFLINT_RULESETS is set from `${{ inputs.tflint_rulesets }}` via the env: block, but is used unquoted in the for-loop word-split position. An attacker-controlled value containing shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) would be interpreted by the shell.

2. `${INPUT_FLAGS} ${CHDIR_COMMAND}` on the tflint invocation line (~line 96): INPUT_FLAGS is set from `${{ inputs.flags }}` and is expanded unquoted on the command line, allowing word-splitting and glob expansion on attacker-controlled content. CHDIR_COMMAND is derived from INPUT_TFLINT_TARGET_DIR (itself from `${{ inputs.tflint_target_dir }}`) and is also unquoted.

Locations:

- `script.sh:57`
- `script.sh:96`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

Fixed three issues in hardened/action/script.sh:
1. unsafe-shell (line 44): Replaced `curl ... | sh -s -- -b ...` with a two-step approach: download the reviewdog install script to a temp file, then execute it with `sh "${REVIEWDOG_INSTALL_SCRIPT}" -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}"`. The `--` was dropped as it was the shell's option terminator (not the script's), per the fix guidelines.
2. script-injection (line 57): Replaced unquoted `for RULESET in ${INPUT_TFLINT_RULESETS}` with a guarded xargs-based tokenization loop using NUL delimiters and `while IFS= read -r -d '' RULESET` to safely iterate over the space-separated list without shell metacharacter injection.
3. script-injection (line 96): Replaced unquoted `${INPUT_FLAGS} ${CHDIR_COMMAND}` with bash arrays: INPUT_FLAGS is tokenized via xargs into `tflint_flags` array (quote-aware, handles flags with values), and CHDIR_COMMAND is placed into `chdir_args` array. Both are expanded with `"${tflint_flags[@]}"` and `"${chdir_args[@]}"`.

