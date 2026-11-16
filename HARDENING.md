<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-tflint/v1.28.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-tflint/v1.28.0** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) broken in the composite step's script (action.yml step 'tflint' runs script.sh). Workflow-controlled inputs are expanded without quotes outside an array assignment, so the SC2206 array exception does not cover them. (1) `for RULESET in ${INPUT_TFLINT_RULESETS}; do` (line 62): the value from inputs.tflint_rulesets is split on whitespace and glob-expanded. (2) `TFLINT_PLUGIN_DIR=${TFLINT_PLUGIN_DIR} "${TFLINT_PATH}/tflint" -c "${INPUT_TFLINT_CONFIG}" ${INPUT_FLAGS} ${CHDIR_COMMAND} --format=checkstyle` (line 112): inputs.flags and inputs.tflint_target_dir (through CHDIR_COMMAND) are expanded without quotes directly on the command line. The shellcheck SC2086 directive only applies to array assignments, not to command arguments. Fix: build arrays first with the directive, e.g. `# shellcheck disable=SC2206` then `FLAGS=(${INPUT_FLAGS})` and `RULESETS=(${INPUT_TFLINT_RULESETS})`, and expand them as "${FLAGS[@]}" / "${RULESETS[@]}". Pass CHDIR as a quoted argument, e.g. ${INPUT_TFLINT_TARGET_DIR:+"--chdir=$INPUT_TFLINT_TARGET_DIR"}.

Locations:

- `script.sh:62`
- `script.sh:112`
- `action.yml:15`

### unsafe-shell (severity: high)

A remote script is piped straight into a shell: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}"`. The URL is pinned to a commit, but the content is still run without being saved to a file and checked first. Download it to a file, verify it, then run it.

Locations:

- `script.sh:48`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed script.sh without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/script.sh b/script.sh
index c0ac2ac..a121583 100755
--- a/script.sh
+++ b/script.sh
@@ -45,7 +45,9 @@ echo '::group::Preparing'
 echo '::endgroup::'
 
 echo "::group::🐶 Installing reviewdog (${REVIEWDOG_VERSION}) ... https://github.com/reviewdog/reviewdog"
-  curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}" 2>&1
+  REVIEWDOG_INSTALL_SCRIPT="${TEMP_PATH}/reviewdog-install.sh"
+  curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh -o "${REVIEWDOG_INSTALL_SCRIPT}"
+  sh "${REVIEWDOG_INSTALL_SCRIPT}" -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}" 2>&1
 echo '::endgroup::'
 
 echo "::group:: Installing tflint (${tflint_version}) ... https://github.com/terraform-linters/tflint"
@@ -59,17 +61,19 @@ echo "::group:: Installing tflint (${tflint_version}) ... https://github.com/ter
   rm -rf "${TEMP_PATH}/tflint.zip" "${TEMP_PATH}/temp-tflint"
 echo '::endgroup::'
 
-for RULESET in ${INPUT_TFLINT_RULESETS}; do
-  PLUGIN="tflint-ruleset-${RULESET}"
-  REPOSITORY="https://github.com/terraform-linters/${PLUGIN}"
+if [ -n "${INPUT_TFLINT_RULESETS}" ]; then
+  while IFS= read -r -d '' RULESET; do
+    PLUGIN="tflint-ruleset-${RULESET}"
+    REPOSITORY="https://github.com/terraform-linters/${PLUGIN}"
 
-  echo "::group:: Installing tflint plugin for ${RULESET} (latest) ... ${REPOSITORY}"
-    curl --silent --show-error --fail \
-      --location "${REPOSITORY}"/releases/latest/download/"${PLUGIN}"_"${os}"_"${arch}".zip \
-      --output "${PLUGIN}".zip \
-    && unzip "${PLUGIN}".zip -d "${TFLINT_PLUGIN_DIR}" && rm "${PLUGIN}".zip
-  echo '::endgroup::'
-done
+    echo "::group:: Installing tflint plugin for ${RULESET} (latest) ... ${REPOSITORY}"
+      curl --silent --show-error --fail \
+        --location "${REPOSITORY}"/releases/latest/download/"${PLUGIN}"_"${os}"_"${arch}".zip \
+        --output "${PLUGIN}".zip \
+      && unzip "${PLUGIN}".zip -d "${TFLINT_PLUGIN_DIR}" && rm "${PLUGIN}".zip
+    echo '::endgroup::'
+  done < <(printf '%s' "${INPUT_TFLINT_RULESETS}" | xargs printf '%s\0')
+fi
 
 case "${INPUT_TFLINT_INIT:-false}" in
     true)
@@ -100,16 +104,22 @@ echo '::group:: Running tflint with reviewdog 🐶 ...'
 
 
   # We only want to specify the tflint target directory if it is not the default to avoid conflicts
-  CHDIR_COMMAND=""
+  chdir_args=()
   if [ "$INPUT_TFLINT_TARGET_DIR" == "." ]; then
     echo "Using default working directory. No need to specify chdir"
   else
     echo "Custom target directory specified."
-    CHDIR_COMMAND="--chdir=${INPUT_TFLINT_TARGET_DIR}"
+    chdir_args=("--chdir=${INPUT_TFLINT_TARGET_DIR}")
   fi
 
-  # shellcheck disable=SC2086
-  TFLINT_PLUGIN_DIR=${TFLINT_PLUGIN_DIR} "${TFLINT_PATH}/tflint" -c "${INPUT_TFLINT_CONFIG}" ${INPUT_FLAGS} ${CHDIR_COMMAND} --format=checkstyle \
+  # Tokenize INPUT_FLAGS into an array using xargs for safe word-splitting
+  flags_args=()
+  if [ -n "${INPUT_FLAGS}" ]; then
+    while IFS= read -r -d '' t; do flags_args+=("$t"); done \
+      < <(printf '%s' "${INPUT_FLAGS}" | xargs printf '%s\0')
+  fi
+
+  TFLINT_PLUGIN_DIR=${TFLINT_PLUGIN_DIR} "${TFLINT_PATH}/tflint" -c "${INPUT_TFLINT_CONFIG}" "${flags_args[@]}" "${chdir_args[@]}" --format=checkstyle \
     | "${REVIEWDOG_PATH}/reviewdog" -f=checkstyle \
         -name="tflint" \
         -reporter="${INPUT_REPORTER}" \

```

Locations:

- `script.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, unsafe-shell, prior-fix

**Notes:**

script.sh changes:
- The reviewdog install.sh (pinned to a commit) is now downloaded to a temp file, checked to be non-empty, then run as `sh file -b ... VERSION`. The `-s --` from the old pipe form is dropped.
- `tflint_rulesets` is split once into an array, `RULESETS=(${INPUT_TFLINT_RULESETS})` with a SC2206 shellcheck directive, and the loop expands it quoted. The loop is written so an empty list still works under `set -u` on bash 3.2.
- `flags` is split into the array `flags_args=(${INPUT_FLAGS})`. The target directory goes into `chdir_args=("--chdir=...")`. Both arrays are expanded quoted on the tflint command line.
- An unquoted array assignment splits on whitespace and expands globs exactly as upstream's unquoted variables did. I didn't use the earlier harden's xargs split because xargs treats quotes in the value differently from upstream.

action.yml: the run line is now `"$GITHUB_ACTION_PATH/script.sh"`, so a path containing spaces still works.

