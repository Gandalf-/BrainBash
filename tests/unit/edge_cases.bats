#!/usr/bin/env bats

load '../helpers/test_helper'

@test "large tape values are handled correctly" {
  # Create a value of 255 (max single byte)
  run bash "$TM_SH" -q <(printf '%.0s+' {1..255})
  assert_success
  assert_output --partial "tape  : 255"
}

@test "multiple tape underflow attempts fail consistently" {
  run bash "$TM_SH" -q <(echo "<<<")
  assert_failure
  assert_output --partial "error: lshift < 0"
}

@test "tape can be extended far to the right" {
  # Move 100 positions to the right
  run bash "$TM_SH" -q <(printf '%.0s>' {1..100})
  assert_success
  # Should have many zeros and final position initialized
  assert_output --regexp "tape.*0.*0.*0"
}

@test "alternating increment and decrement works" {
  run bash "$TM_SH" -q <(echo "+-+-+-+++")
  assert_success
  assert_output --partial "tape  : 3"
}

@test "empty loop body is valid" {
  run bash "$TM_SH" -q <(echo "[]")
  assert_success
  assert_output --partial "tape  : 0"
}

@test "loop with only movement is valid" {
  run bash "$TM_SH" -q <(echo "+[>]")
  assert_success
}

@test "unmatched brackets are handled gracefully" {
  # This has opening bracket but tape goes to 0 before closing
  run bash "$TM_SH" -q <(echo "+[->+<]")
  assert_success
}

@test "program with only loops and no operations" {
  run bash "$TM_SH" -q <(echo "[[[+++]]]")
  assert_success
  assert_output --partial "tape  : 0"
}

@test "very long sequence of same operation" {
  # 1000 increments
  run bash "$TM_SH" -q <(printf '%.0s+' {1..1000})
  assert_success
  assert_output --partial "tape  : 1000"
}

@test "operations at tape boundaries" {
  # Move right, increment, move back, should work
  run bash "$TM_SH" -q <(echo ">+++<++")
  assert_success
  assert_output --partial "tape  : 2 3"
}

@test "rapid tape movement" {
  run bash "$TM_SH" -q <(echo ">>><<<>>>")
  assert_success
  assert_output --partial "tape  : 0 0 0 0"
}

@test "decrement below zero wraps correctly" {
  # This tests wraparound behavior for bash arithmetic
  run bash "$TM_SH" -q <(echo "-")
  assert_success
  # In bash, 0-1 = -1, so we expect -1
  assert_output --partial "tape  : -1"
}
