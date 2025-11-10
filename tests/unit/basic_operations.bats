#!/usr/bin/env bats

load '../helpers/test_helper'

@test "increment operation increases tape value" {
  run bash "$TM_SH" -q <(echo "+++++")
  assert_success
  assert_output --partial "tape  : 5"
}

@test "decrement operation decreases tape value" {
  run bash "$TM_SH" -q <(echo "+++++--")
  assert_success
  assert_output --partial "tape  : 3"
}

@test "right shift moves tape position" {
  run bash "$TM_SH" -q <(echo "+++>++")
  assert_success
  assert_output --partial "tape  : 3 2"
}

@test "left shift moves tape position back" {
  run bash "$TM_SH" -q <(echo "+++>++<")
  assert_success
  assert_output --partial "tape  : 3 2"
}

@test "simple loop executes when value is non-zero" {
  run bash "$TM_SH" -q <(echo "+++[-]")
  assert_success
  assert_output --partial "tape  : 0"
}

@test "loop skips when value is zero" {
  run bash "$TM_SH" -q <(echo "[+++]")
  assert_success
  assert_output --partial "tape  : 0"
}

@test "nested loops work correctly" {
  run bash "$TM_SH" -q <(echo "++[>++[>++<-]<-]")
  assert_success
  assert_output --partial "tape  : 0 0 8"
}

@test "tape underflow produces error" {
  run bash "$TM_SH" -q <(echo "<")
  assert_failure
  assert_output --partial "error: lshift < 0"
}

@test "empty program executes successfully" {
  run bash "$TM_SH" -q <(echo "")
  assert_success
  assert_output --partial "tape  : 0"
}

@test "comments are ignored" {
  run bash "$TM_SH" -q <(echo "# This is a comment
+++
# Another comment
++")
  assert_success
  assert_output --partial "tape  : 5"
}

@test "output operation prints ASCII character" {
  # 65 = 'A' in ASCII
  local prog=""; for i in {1..65}; do prog="${prog}+"; done; prog="${prog}."
  run bash "$TM_SH" -q <(echo "$prog")
  assert_success
  assert_output --partial "A"
}

@test "multiple output operations print correctly" {
  # Use hello_world.bf as it's a known working program
  run bash "$TM_SH" -q "$PROGRAMS_DIR/hello_world.bf"
  assert_success
  assert_output --partial "Hello World"
}

@test "deeply nested loops execute correctly" {
  # ++[>+<-] should move 2 to the right position
  run bash "$TM_SH" -q <(echo "++[>+<-]")
  assert_success
  assert_output --partial "tape  : 0 2"
}

@test "tape can handle zero values correctly" {
  run bash "$TM_SH" -q <(echo "+++---")
  assert_success
  assert_output --partial "tape  : 0"
}

@test "non-brainfuck characters are ignored" {
  run bash "$TM_SH" -q <(echo "++abc++xyz++")
  assert_success
  assert_output --partial "tape  : 6"
}
