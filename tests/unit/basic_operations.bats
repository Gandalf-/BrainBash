#!/usr/bin/env bats

load '../helpers/test_helper'

@test "increment operation increases tape value" {
  run bash "$TM_SH" -q <(echo "+++++")
  assert_success
  stripped=$(echo "$output" | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$stripped" == *"tape  : 5"* ]]
}

@test "decrement operation decreases tape value" {
  run bash "$TM_SH" -q <(echo "+++++--")
  assert_success
  stripped=$(echo "$output" | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$stripped" == *"tape  : 3"* ]]
}

@test "right shift moves tape position" {
  run bash "$TM_SH" -q <(echo "+++>++")
  assert_success
  stripped=$(echo "$output" | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$stripped" == *"tape  : 3 2"* ]]
}

@test "left shift moves tape position back" {
  run bash "$TM_SH" -q <(echo "+++>++<")
  assert_success
  stripped=$(echo "$output" | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$stripped" == *"tape  : 3 2"* ]]
}

@test "simple loop executes when value is non-zero" {
  run bash "$TM_SH" -q <(echo "+++[-]")
  assert_success
  stripped=$(echo "$output" | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$stripped" == *"tape  : 0"* ]]
}

@test "loop skips when value is zero" {
  run bash "$TM_SH" -q <(echo "[+++]")
  assert_success
  stripped=$(echo "$output" | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$stripped" == *"tape  : 0"* ]]
}

@test "nested loops work correctly" {
  run bash "$TM_SH" -q <(echo "++[>++[>++<-]<-]")
  assert_success
  stripped=$(echo "$output" | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$stripped" == *"tape  : 0 0 8"* ]]
}

@test "tape underflow produces error" {
  run bash "$TM_SH" -q <(echo "<")
  assert_failure
  assert_output --partial "error: lshift < 0"
}

@test "empty program executes successfully" {
  run bash "$TM_SH" -q <(echo "")
  assert_success
  stripped=$(echo "$output" | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$stripped" == *"tape  : 0"* ]]
}

@test "comments are ignored" {
  run bash "$TM_SH" -q <(echo "# This is a comment
+++
# Another comment
++")
  assert_success
  stripped=$(echo "$output" | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$stripped" == *"tape  : 5"* ]]
}
