#!/usr/bin/env bats

load '../helpers/test_helper'

@test "hello_world.bf prints 'Hello World!'" {
  result=$(bash "$TM_SH" -q "$PROGRAMS_DIR/hello_world.bf" 2>&1 | grep -v "^tape" | grep -v "^operations")
  [[ "$result" == *"Hello World!"* ]]
}

@test "alphabet.bf prints the alphabet" {
  result=$(bash "$TM_SH" -q "$PROGRAMS_DIR/alphabet.bf" 2>&1 | grep -v "^tape" | grep -v "^operations")
  [[ "$result" == *"abcdefghijklmnopqrstuvwxyz"* ]]
}

@test "simple.bf executes without error" {
  result=$(bash "$TM_SH" -q "$PROGRAMS_DIR/simple.bf" 2>&1 || true)
  # Just verify it produces tape output (doesn't crash)
  [[ "$result" == *"tape"* ]]
}

@test "loop.bf executes without error" {
  result=$(bash "$TM_SH" -q "$PROGRAMS_DIR/loop.bf" 2>&1 || true)
  [[ "$result" == *"tape"* ]]
}

@test "nested_loop.bf executes without error" {
  result=$(bash "$TM_SH" -q "$PROGRAMS_DIR/nested_loop.bf" 2>&1 || true)
  [[ "$result" == *"tape"* ]]
}

@test "optimize.bf executes without error" {
  result=$(bash "$TM_SH" -q "$PROGRAMS_DIR/optimize.bf" 2>&1 || true)
  [[ "$result" == *"tape"* ]]
}

@test "multiply.bf executes without error" {
  result=$(bash "$TM_SH" -q "$PROGRAMS_DIR/multiply.bf" 2>&1 || true)
  [[ "$result" == *"tape"* ]]
}

@test "copy.bf executes without error" {
  result=$(bash "$TM_SH" -q "$PROGRAMS_DIR/copy.bf" 2>&1 || true)
  [[ "$result" == *"tape"* ]]
}

@test "counter.bf executes without error" {
  result=$(bash "$TM_SH" -q "$PROGRAMS_DIR/counter.bf" 2>&1 || true)
  [[ "$result" == *"tape"* ]]
}
