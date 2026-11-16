<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-tflint/v1.29.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-tflint/v1.29.0** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh (the action's entrypoint, run from action.yml) downloads the reviewdog installer and pipes it straight into a shell: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}"`. The URL is pinned to a commit, but the content still runs without being saved and checked first. Save it to a file, verify it, then run it.

Locations:

- `script.sh:48`

### script-injection (severity: high)

Rule (b): script.sh expands workflow-controlled inputs without quotes. (1) `for RULESET in ${INPUT_TFLINT_RULESETS}; do`, where INPUT_TFLINT_RULESETS comes from inputs.tflint_rulesets. (2) `TFLINT_PLUGIN_DIR=${TFLINT_PLUGIN_DIR} "${TFLINT_PATH}/tflint" -c "${INPUT_TFLINT_CONFIG}" ${INPUT_FLAGS} ${CHDIR_COMMAND} --format=checkstyle`, where INPUT_FLAGS comes from inputs.flags and CHDIR_COMMAND is built from inputs.tflint_target_dir. Line 112 has a `# shellcheck disable=SC2086` directive above it, but the array-assignment exception does not cover it because neither line is a NAME=($VAR) array assignment. Splitting the value into a quoted array (with the directive) and expanding that as "${arr[@]}" would meet the rule.

Locations:

- `script.sh:62`
- `script.sh:112`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed script.sh without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/script.sh b/script.sh
index c0ac2ac..454e9bd 100755
--- a/script.sh
+++ b/script.sh
@@ -45,7 +45,14 @@ echo '::group::Preparing'
 echo '::endgroup::'
 
 echo "::group::🐶 Installing reviewdog (${REVIEWDOG_VERSION}) ... https://github.com/reviewdog/reviewdog"
-  curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}" 2>&1
+  REVIEWDOG_INSTALLER="${TEMP_PATH}/reviewdog-install.sh"
+  curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh -o "${REVIEWDOG_INSTALLER}"
+  if [[ ! -s "${REVIEWDOG_INSTALLER}" ]]; then
+    echo "Failed to download reviewdog installer" >&2
+    exit 1
+  fi
+  sh "${REVIEWDOG_INSTALLER}" -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}" 2>&1
+  rm -f "${REVIEWDOG_INSTALLER}"
 echo '::endgroup::'
 
 echo "::group:: Installing tflint (${tflint_version}) ... https://github.com/terraform-linters/tflint"

```

Locations:

- `script.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection, prior-fix

**Notes:**

All three findings are fixed in script.sh. I haven't run the action after these changes.

- **unsafe-shell / prior-fix:** the reviewdog installer is now saved to a temp file first. The script stops if that file is missing or empty, otherwise runs it with `sh "$file" -b "$REVIEWDOG_PATH" "$REVIEWDOG_VERSION"` and deletes it. I dropped the `-s --` from the old pipe form, so the installer's first argument is `-b`. This is the same change the previous harden made.

- **script-injection, tflint_rulesets:** the value is now split into an array with `RULESETS=($INPUT_TFLINT_RULESETS)`, which splits and globs exactly as upstream's unquoted expansion did. The loop reads `${RULESETS[@]+"${RULESETS[@]}"}`, so an empty input doesn't trip `set -u` on older bash (3.2, as on macOS).

- **script-injection, flags:** the value is now split into an array with `TFLINT_FLAGS=($INPUT_FLAGS)` and passed as `${TFLINT_FLAGS[@]+"${TFLINT_FLAGS[@]}"}`.

- **script-injection, tflint_target_dir:** the `--chdir` option is now passed as one quoted argument with `${CHDIR_COMMAND:+"$CHDIR_COMMAND"}`, so it disappears when the default `.` is used. One behaviour change: a target directory containing spaces now reaches tflint as a single path, where upstream split it into several arguments.

- **Also:** `TFLINT_PLUGIN_DIR` is now quoted on that command line.

action.yml did not need changes.

