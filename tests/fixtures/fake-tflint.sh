#!/bin/bash
# Fake tflint binary: handles --version and outputs empty checkstyle XML for lint runs.
for arg in "$@"; do
  case "$arg" in
    --version)
      echo "TFLint version 0.50.3 (fake)"
      exit 0
      ;;
    --init)
      echo "Initialized (fake)"
      exit 0
      ;;
  esac
done
# Default: output empty checkstyle XML (no findings)
printf '<checkstyle version="4.3"></checkstyle>\n'
exit 0
