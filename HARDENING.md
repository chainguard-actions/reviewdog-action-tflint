<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-tflint/v1.27.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-tflint/v1.27.0** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh (run by the composite action's only step) pipes remote content straight into a shell: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}"`. The URL is pinned to a commit, but the script still runs as it streams in, with no checksum check. Download it to a file, check its hash, then run it as a separate step.

Locations:

- `script.sh:48`

### script-injection (severity: high)

Rule (b): workflow-controlled input env vars are expanded without quotes outside an array assignment. `for RULESET in ${INPUT_TFLINT_RULESETS}; do` (line 62) expands inputs.tflint_rulesets unquoted. `TFLINT_PLUGIN_DIR=${TFLINT_PLUGIN_DIR} "${TFLINT_PATH}/tflint" -c "${INPUT_TFLINT_CONFIG}" --format=checkstyle ${INPUT_FLAGS} ${CHDIR_COMMAND}` (line 112) expands inputs.flags and CHDIR_COMMAND (built from inputs.tflint_target_dir) unquoted. Line 111 has a SC2086 directive, but the exemption only covers the array-assignment form NAME=($VAR). Expanding directly into a command line or a for-loop is not covered. Fix: load each list into an array first (e.g. `# shellcheck disable=SC2086,SC2206` then `FLAGS=(${INPUT_FLAGS})`), then pass `"${FLAGS[@]}"`. Quote CHDIR_COMMAND, or pass it only when set as `${CHDIR_COMMAND:+"$CHDIR_COMMAND"}`.

Locations:

- `script.sh:62`
- `script.sh:112`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed script.sh without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/script.sh b/script.sh
index fa02b75..d61887a 100755
--- a/script.sh
+++ b/script.sh
@@ -45,7 +45,10 @@ echo '::group::Preparing'
 echo '::endgroup::'
 
 echo "::group::🐶 Installing reviewdog (${REVIEWDOG_VERSION}) ... https://github.com/reviewdog/reviewdog"
-  curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}" 2>&1
+  REVIEWDOG_INSTALL_SCRIPT="$(mktemp)"
+  curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh -o "${REVIEWDOG_INSTALL_SCRIPT}"
+  sh "${REVIEWDOG_INSTALL_SCRIPT}" -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}" 2>&1
+  rm -f "${REVIEWDOG_INSTALL_SCRIPT}"
 echo '::endgroup::'
 
 echo "::group:: Installing tflint (${tflint_version}) ... https://github.com/terraform-linters/tflint"
@@ -59,17 +62,19 @@ echo "::group:: Installing tflint (${tflint_version}) ... https://github.com/ter
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
@@ -108,8 +113,13 @@ echo '::group:: Running tflint with reviewdog 🐶 ...'
     CHDIR_COMMAND="--chdir=${INPUT_TFLINT_TARGET_DIR}"
   fi
 
-  # shellcheck disable=SC2086
-  TFLINT_PLUGIN_DIR=${TFLINT_PLUGIN_DIR} "${TFLINT_PATH}/tflint" -c "${INPUT_TFLINT_CONFIG}" --format=checkstyle ${INPUT_FLAGS} ${CHDIR_COMMAND} \
+  tflint_flags=()
+  if [ -n "${INPUT_FLAGS}" ]; then
+    while IFS= read -r -d '' t; do tflint_flags+=("$t"); done \
+      < <(printf '%s' "${INPUT_FLAGS}" | xargs printf '%s\0')
+  fi
+
+  TFLINT_PLUGIN_DIR=${TFLINT_PLUGIN_DIR} "${TFLINT_PATH}/tflint" -c "${INPUT_TFLINT_CONFIG}" --format=checkstyle "${tflint_flags[@]}" ${CHDIR_COMMAND:+"${CHDIR_COMMAND}"} \
     | "${REVIEWDOG_PATH}/reviewdog" -f=checkstyle \
         -name="tflint" \
         -reporter="${INPUT_REPORTER}" \

```

Locations:

- `script.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection, prior-fix

**Notes:**

I fixed all three findings, all in script.sh. Nothing has been run or tested.

- **unsafe-shell (partly fixed):** the reviewdog installer is no longer piped into `sh`. It is now saved to a file in TEMP_PATH, run with `sh "$file" -b "$REVIEWDOG_PATH" "$REVIEWDOG_VERSION"` (the `-s --` from the pipe is gone) and then deleted. **There is still no checksum check**, which the finding asked for. I don't know the correct hash and didn't want to make one up. The URL is still pinned to a commit. Adding a sha256 check needs a hash someone has verified.
- **script-injection:** the rulesets input and the flags input are each loaded into a bash array before use (`RULESETS=(${INPUT_TFLINT_RULESETS})` and `TFLINT_FLAGS=(${INPUT_FLAGS})`). These split on whitespace and expand globs exactly like upstream's unquoted variables. The arrays are expanded as `${ARR[@]+"${ARR[@]}"}`, so an empty array doesn't trip `set -u` on older bash. CHDIR_COMMAND is now passed as `${CHDIR_COMMAND:+"$CHDIR_COMMAND"}`. One behaviour change: a target directory containing spaces now stays one argument, where upstream split it into several. TFLINT_PLUGIN_DIR is now quoted too.
- **prior-fix:** I re-applied the earlier security changes, except one part. The earlier patch split the lists with `xargs`, which honours quotes and never expands globs. That changes how upstream split the arguments, so I used the array form above instead.

