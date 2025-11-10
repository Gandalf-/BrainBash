#!/usr/bin/env bats

load '../helpers/test_helper'

@test "increment operation increases tape value" {
  result=$(bash "$TM_SH" -q <(echo "+++++") 2>&1 | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$result" == *"tape  : 5"* ]]
}

@test "decrement operation decreases tape value" {
  result=$(bash "$TM_SH" -q <(echo "+++++--") 2>&1 | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$result" == *"tape  : 3"* ]]
}

@test "right shift moves tape position" {
  result=$(bash "$TM_SH" -q <(echo "+++>++") 2>&1 | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$result" == *"tape  : 3 2"* ]]
}

@test "left shift moves tape position back" {
  result=$(bash "$TM_SH" -q <(echo "+++>++<") 2>&1 | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$result" == *"tape  : 3 2"* ]]
}

@test "simple loop executes when value is non-zero" {
  result=$(bash "$TM_SH" -q <(echo "+++[-]") 2>&1 | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$result" == *"tape  : 0"* ]]
}

@test "loop skips when value is zero" {
  result=$(bash "$TM_SH" -q <(echo "[+++]") 2>&1 | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$result" == *"tape  : 0"* ]]
}

@test "nested loops work correctly" {
  result=$(bash "$TM_SH" -q <(echo "++[>++[>++<-]<-]") 2>&1 | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$result" == *"tape  : 0 0 8"* ]]
}

@test "tape underflow produces error" {
  result=$(bash "$TM_SH" -q <(echo "<") 2>&1)
  [[ "$result" == *"error: lshift < 0"* ]]
}

@test "empty program executes successfully" {
  result=$(bash "$TM_SH" -q <(echo "") 2>&1 | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$result" == *"tape  : 0"* ]]
}

@test "comments are ignored" {
  result=$(bash "$TM_SH" -q <(echo "# This is a comment
+++
# Another comment
++") 2>&1 | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$result" == *"tape  : 5"* ]]
}
