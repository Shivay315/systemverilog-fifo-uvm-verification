#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for mutant in bad_empty bad_wrap bad_full_simultaneous; do
  echo
  echo "############################################################"
  echo "# Mutation test: $mutant"
  echo "############################################################"
  "$ROOT/scripts/run_mutation.sh" "$mutant"
done
echo
echo "All three mutants were detected by expected checker patterns."
