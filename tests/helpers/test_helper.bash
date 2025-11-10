#!/usr/bin/env bash

# Common test setup and helpers for BrainBash tests

# Load BATS support libraries
load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

# Path to the tm.sh interpreter (from tests/unit or tests/integration)
TM_SH="${BATS_TEST_DIRNAME}/../../tm.sh"

# Path to test programs
PROGRAMS_DIR="${BATS_TEST_DIRNAME}/../../programs"

# Run tm.sh with a program string
run_program() {
  local program="$1"
  shift
  echo "$program" | bash "$TM_SH" "$@" /dev/stdin
}

# Run tm.sh with input piped to it
run_with_input() {
  local input="$1"
  local program="$2"
  shift 2
  echo "$input" | bash "$TM_SH" "$@" <(echo "$program")
}

# Extract just the tape output from tm.sh results
get_tape_output() {
  grep "^tape" | sed 's/tape  : //'
}

# Extract program output (from . operations)
get_program_output() {
  sed '/^tape/d; /^operations:/d; /^program:/d; /^optimized/d; /^$/d; /% time/d; /^---/d; /input?>/d'
}
