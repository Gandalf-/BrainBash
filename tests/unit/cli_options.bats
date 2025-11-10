#!/usr/bin/env bats

load '../helpers/test_helper'

@test "help flag exits successfully" {
  run bash "$TM_SH" -h
  assert_success
  assert_output --partial "usage:"
}

@test "help flag with long form exits successfully" {
  run bash "$TM_SH" --help
  assert_success
  assert_output --partial "usage:"
}

@test "no input shows usage and fails" {
  run bash "$TM_SH"
  assert_failure
  assert_output --partial "usage:"
}

@test "max iterations flag limits execution" {
  # This program would run forever without iteration limit
  run bash "$TM_SH" -q -i 100 <(echo "+[+]")
  assert_success
  assert_output --partial "iteration maximum reached: 100"
}

@test "print flag shows program before execution" {
  run bash "$TM_SH" -q -p <(echo "+++")
  assert_success
  assert_output --partial "program: +++"
}

@test "profile flag shows execution statistics" {
  run bash "$TM_SH" -q -P -p <(echo "+++")
  assert_success
  assert_output --partial "% time"
}

@test "optimize flag applies simple optimizations" {
  run bash "$TM_SH" -q -p -o <(echo "++++")
  assert_success
  assert_output --partial "optimized away"
  assert_output --partial "program: 4+"
}

@test "Optimize flag applies heavy optimizations" {
  run bash "$TM_SH" -q -p -O <(echo "+++++[-]")
  assert_success
  assert_output --partial "program: 5+Z"
}

@test "quiet flag suppresses execution trace" {
  run bash "$TM_SH" -q <(echo "+++")
  assert_success
  # Should only show final tape, not intermediate steps
  [[ $(echo "$output" | grep -c "tape") -eq 1 ]]
}

@test "reading from actual file works" {
  run bash "$TM_SH" -q "$PROGRAMS_DIR/simple.bf"
  assert_success
  assert_output --partial "tape"
}

@test "compile mode creates correct output file" {
  local tmpdir=$(mktemp -d)
  local input="$tmpdir/test.bf"
  echo "+++>++>+" > "$input"

  run bash "$TM_SH" -c "$input"
  assert_success

  # Check that .raw file was created with correct name
  [[ -f "$input.raw" ]]

  # Check that compiled program has content
  [[ -s "$input.raw" ]]

  # Clean up
  rm -rf "$tmpdir"
}

@test "raw mode executes compiled program" {
  local tmpdir=$(mktemp -d)
  local input="$tmpdir/test.bf"
  echo "+++>++>+" > "$input"

  # First compile
  bash "$TM_SH" -c "$input"

  # Then execute raw
  run bash "$TM_SH" -q -r "$input.raw"
  assert_success
  assert_output --partial "tape  : 3 2 1"

  # Clean up
  rm -rf "$tmpdir"
}

@test "compile with optimization produces optimized raw file" {
  local tmpdir=$(mktemp -d)
  local input="$tmpdir/test.bf"
  echo "++++" > "$input"

  # Compile with optimization
  bash "$TM_SH" -c -o "$input"

  # Raw file should contain optimized form
  local content=$(cat "$input.raw")
  [[ "$content" == "4+" ]]

  # Clean up
  rm -rf "$tmpdir"
}

@test "optimization preserves program semantics" {
  # Same program with and without optimization should produce same result
  plain=$(bash "$TM_SH" -q <(echo "+++>++>+") 2>&1)
  optimized=$(bash "$TM_SH" -q -o <(echo "+++>++>+") 2>&1)
  [[ "$plain" == "$optimized" ]]
}
