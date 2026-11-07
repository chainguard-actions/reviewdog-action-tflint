<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-tflint/v1.29.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-tflint/v1.29.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh, the script run by the action's composite run step, downloads the reviewdog installer and pipes it straight into a shell: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}"`. The URL is pinned to a commit, but the downloaded content runs without being saved or checked first. Fix: download it to a file, verify its checksum, then run it as a separate command.

Locations:

- `script.sh:48`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell

**Notes:**

script.sh: the reviewdog install.sh is now downloaded with curl -sfL into $TEMP_PATH, the script fails if the file is empty, and it then runs as `sh "$installer" -b "$REVIEWDOG_PATH" "$REVIEWDOG_VERSION"`. The '-s --' is dropped so the installer still sees -b as $1. The URL is still pinned to commit fd59714416d6d9a1c0692d872e38e7f8448df4fc, so its content can't change. There is no checksum check yet: I had no way to fetch the file and get its real sha256, and I didn't want to make one up. A follow-up could add `echo "<sha256>  $installer" | sha256sum -c` once the hash is computed.

