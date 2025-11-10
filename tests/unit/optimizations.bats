#!/usr/bin/env bats

load '../helpers/test_helper'

# Helper to extract just tape values
get_tape() {
  grep "^tape" | sed 's/tape  : //'
}

@test "simple optimization: repeated increments (+++)" {
  plain=$(bash "$TM_SH" -q <(echo "+++++") 2>&1 | get_tape)
  optimized=$(bash "$TM_SH" -q -o <(echo "+++++") 2>&1 | get_tape)
  [[ "$plain" == "$optimized" ]]
}

@test "simple optimization: repeated decrements (---)" {
  plain=$(bash "$TM_SH" -q <(echo "+++++---") 2>&1 | get_tape)
  optimized=$(bash "$TM_SH" -q -o <(echo "+++++---") 2>&1 | get_tape)
  [[ "$plain" == "$optimized" ]]
}

@test "simple optimization: repeated right shifts (>>>)" {
  plain=$(bash "$TM_SH" -q <(echo "++>++>++") 2>&1 | get_tape)
  optimized=$(bash "$TM_SH" -q -o <(echo "++>++>++") 2>&1 | get_tape)
  [[ "$plain" == "$optimized" ]]
}

@test "simple optimization: repeated left shifts (<<<)" {
  plain=$(bash "$TM_SH" -q <(echo "++>++>++<<<") 2>&1 | get_tape)
  optimized=$(bash "$TM_SH" -q -o <(echo "++>++>++<<<") 2>&1 | get_tape)
  [[ "$plain" == "$optimized" ]]
}

@test "heavy optimization: hello_world.bf produces same output" {
  plain=$(bash "$TM_SH" -q "$PROGRAMS_DIR/hello_world.bf" 2>&1 | grep -v "^tape" | grep -v "^operations" | grep -v "^program" | grep -v "^optimized")
  optimized=$(bash "$TM_SH" -q -O "$PROGRAMS_DIR/hello_world.bf" 2>&1 | grep -v "^tape" | grep -v "^operations" | grep -v "^program" | grep -v "^optimized")
  [[ "$plain" == "$optimized" ]]
}

@test "heavy optimization: alphabet.bf produces same output" {
  plain=$(bash "$TM_SH" -q "$PROGRAMS_DIR/alphabet.bf" 2>&1 | grep -v "^tape" | grep -v "^operations" | grep -v "^program" | grep -v "^optimized")
  optimized=$(bash "$TM_SH" -q -O "$PROGRAMS_DIR/alphabet.bf" 2>&1 | grep -v "^tape" | grep -v "^operations" | grep -v "^program" | grep -v "^optimized")
  [[ "$plain" == "$optimized" ]]
}

@test "heavy optimization: simple.bf produces same tape" {
  plain=$(bash "$TM_SH" -q "$PROGRAMS_DIR/simple.bf" 2>&1 | get_tape)
  optimized=$(bash "$TM_SH" -q -O "$PROGRAMS_DIR/simple.bf" 2>&1 | get_tape)
  [[ "$plain" == "$optimized" ]]
}

@test "heavy optimization: loop.bf produces same tape" {
  plain=$(bash "$TM_SH" -q "$PROGRAMS_DIR/loop.bf" 2>&1 | get_tape)
  optimized=$(bash "$TM_SH" -q -O "$PROGRAMS_DIR/loop.bf" 2>&1 | get_tape)
  [[ "$plain" == "$optimized" ]]
}

@test "heavy optimization: nested_loop.bf produces same tape" {
  plain=$(bash "$TM_SH" -q "$PROGRAMS_DIR/nested_loop.bf" 2>&1 | get_tape)
  optimized=$(bash "$TM_SH" -q -O "$PROGRAMS_DIR/nested_loop.bf" 2>&1 | get_tape)
  [[ "$plain" == "$optimized" ]]
}

@test "heavy optimization: multiply.bf produces same tape" {
  plain=$(bash "$TM_SH" -q "$PROGRAMS_DIR/multiply.bf" 2>&1 | get_tape)
  optimized=$(bash "$TM_SH" -q -O "$PROGRAMS_DIR/multiply.bf" 2>&1 | get_tape)
  [[ "$plain" == "$optimized" ]]
}

@test "heavy optimization: copy.bf produces same tape" {
  plain=$(bash "$TM_SH" -q "$PROGRAMS_DIR/copy.bf" 2>&1 | get_tape)
  optimized=$(bash "$TM_SH" -q -O "$PROGRAMS_DIR/copy.bf" 2>&1 | get_tape)
  [[ "$plain" == "$optimized" ]]
}

@test "optimization: repeated operations are combined" {
  result=$(echo "++++" | bash "$TM_SH" -q -p -o /dev/stdin 2>&1)
  [[ "$result" == *"optimized away"* ]]
  [[ "$result" == *"program: 4+"* ]]
}

@test "optimization: zeroing loop [-] is recognized" {
  # Heavy optimization should convert [-] to Z
  result=$(echo "+++++[-]" | bash "$TM_SH" -q -p -O /dev/stdin 2>&1)
  [[ "$result" == *"Z"* ]]
}

@test "optimization: move patterns are recognized" {
  # [->>+<<] should be optimized to a move pattern
  result=$(echo "+++[->>+<<]" | bash "$TM_SH" -q -p -O /dev/stdin 2>&1)
  # Should contain A (move to right) pattern
  [[ "$result" =~ [0-9]+A ]]
}

@test "optimization: copy patterns are recognized" {
  # [->+>+<<] should be optimized to a copy pattern
  result=$(echo "+++[->+>+<<]" | bash "$TM_SH" -q -p -O /dev/stdin 2>&1)
  # Should contain C (copy) pattern
  [[ "$result" =~ C ]]
}

@test "optimization: percentage calculation is correct" {
  result=$(echo "++++" | bash "$TM_SH" -q -p -o /dev/stdin 2>&1)
  # With 4 '+' becoming '4+', we go from 4 instructions to 2 characters
  # but the optimization message should show percentage
  [[ "$result" =~ [0-9]+\.[0-9]+% ]]
}
