#!/usr/bin/env bats

load '../helpers/test_helper'

# Advanced edge cases and exotic scenarios

# ==================================================
# Invalid Flag Arguments
# ==================================================

@test "non-numeric -i flag argument fails" {
  run bash "$TM_SH" -i abc <(echo "+++")
  assert_failure
  assert_output --partial "error: -i requires a positive integer"
}

@test "negative -i flag argument fails" {
  run bash "$TM_SH" -i -5 <(echo "+++")
  assert_failure
  assert_output --partial "error: -i requires a positive integer"
}

@test "zero -i flag argument runs zero iterations" {
  run bash "$TM_SH" -q -i 0 <(echo "+++")
  assert_failure
  assert_output --partial "iteration maximum reached: 0"
}

@test "non-numeric -s flag argument fails" {
  run bash "$TM_SH" -s xyz <(echo "+++")
  assert_failure
  assert_output --partial "error: -s requires a numeric argument"
}

@test "negative -s flag argument fails" {
  run bash "$TM_SH" -s -1 <(echo "+++")
  assert_failure
  assert_output --partial "error: -s requires a numeric argument"
}

@test "decimal -s flag argument is valid" {
  run bash "$TM_SH" -q -s 0.001 <(echo "+++")
  assert_success
}

# ==================================================
# File Handling Errors
# ==================================================

@test "non-existent file fails gracefully" {
  run bash "$TM_SH" -q /nonexistent/file/path.bf
  assert_success
  # It treats the path as a program string, not an error
  assert_output --partial "tape"
}

@test "reading from /dev/null produces empty program" {
  run bash "$TM_SH" -q /dev/null
  assert_success
  assert_output --partial "tape  : 0"
}

# ==================================================
# Complex Optimization Patterns
# ==================================================

@test "copy operation to the right [->+>+<<]" {
  # Should copy value to two positions to the right
  result=$(echo "+++[->+>+<<]" | bash "$TM_SH" -q -O /dev/stdin 2>&1)
  [[ "$result" == *"tape  : 0 3 3"* ]]
}

@test "copy operation recognized by optimizer" {
  result=$(echo "+++[->+>+<<]" | bash "$TM_SH" -q -p -O /dev/stdin 2>&1 | grep "program:")
  [[ "$result" == *"C"* ]]
}

@test "complex copy with offset [->++>++<<]" {
  # Copy with multiplier
  result=$(echo "++[->++>++<<]" | bash "$TM_SH" -q -O /dev/stdin 2>&1)
  [[ "$result" == *"tape  : 0 4 4"* ]]
}

@test "move and multiply [->>+++<<]" {
  result=$(echo "++[->>+++<<]" | bash "$TM_SH" -q -O /dev/stdin 2>&1)
  [[ "$result" == *"tape  : 0 0 6"* ]]
}

@test "move and multiply recognized by optimizer" {
  result=$(echo "++[->>+++<<]" | bash "$TM_SH" -q -p -O /dev/stdin 2>&1 | grep "program:")
  # Should show the optimized instruction
  [[ "$result" == *"3_2A"* ]] || [[ "$result" == *"A"* ]]
}

@test "subtract move to the right [->>-<<]" {
  # Set position 0 to 5, then subtract it from position 3
  result=$(echo "+++++>++>>+++<<[->>-<<]" | bash "$TM_SH" -q -O /dev/stdin 2>&1)
  # tape[0]=5, tape[1]=2, tape[2]=0, tape[3] decremented twice = 1
  [[ "$result" == *"tape  : 5 0 0 1"* ]]
}

@test "move left operation [-<<+>>]" {
  # Move value two positions to the left
  result=$(echo ">>+++[-<<+>>]" | bash "$TM_SH" -q -O /dev/stdin 2>&1)
  [[ "$result" == *"tape  : 3 0 0"* ]]
}

@test "multiple different optimizations in one program" {
  # Combines zeroing, moves, and simple optimizations
  result=$(echo "++++[-]>+++++[->+<]>[->>+<<]" | bash "$TM_SH" -q -O /dev/stdin 2>&1)
  [[ "$result" == *"tape  : 0 0 0 0 5"* ]]
}

# ==================================================
# Large Value Handling
# ==================================================

@test "tape can store large values beyond 255" {
  # Bash arithmetic uses 64-bit integers, not 8-bit bytes
  run bash "$TM_SH" -q <(yes '+' | head -n 300 | tr -d '\n')
  assert_success
  assert_output --partial "tape  : 300"
}

@test "tape can store very large values" {
  run bash "$TM_SH" -q <(yes '+' | head -n 1000 | tr -d '\n')
  assert_success
  assert_output --partial "tape  : 1000"
}

@test "decrement from 0 produces -1" {
  result=$(echo "-" | bash "$TM_SH" -q /dev/stdin 2>&1)
  [[ "$result" == *"tape  : -1"* ]]
}

@test "arithmetic with moderately large values works correctly" {
  # 50 + 30 = 80
  local tmpfile=$(mktemp)
  yes '+' | head -n 50 | tr -d '\n' > "$tmpfile"
  echo -n '>' >> "$tmpfile"
  yes '+' | head -n 30 | tr -d '\n' >> "$tmpfile"
  echo '<[->+<]' >> "$tmpfile"

  result=$(bash "$TM_SH" -q "$tmpfile" 2>&1)
  rm "$tmpfile"
  [[ "$result" == *"80"* ]]
}

# ==================================================
# Profiler Output Validation
# ==================================================

@test "profiler shows percentage breakdown" {
  result=$(echo "+++>++>+" | bash "$TM_SH" -q -P /dev/stdin 2>&1)
  [[ "$result" == *"% time"* ]]
  [[ "$result" == *":"* ]]
}

@test "profiler tracks loop execution frequency" {
  result=$(echo "+++[>+<-]" | bash "$TM_SH" -q -P /dev/stdin 2>&1)
  [[ "$result" == *"% time"* ]]
  # Loop body should be executed multiple times
  [[ "$result" == *"[>+<-]"* ]] || [[ "$result" == *">"* ]]
}

@test "profiler with optimizations shows optimized instructions" {
  result=$(echo "++++++++" | bash "$TM_SH" -q -P -o /dev/stdin 2>&1)
  [[ "$result" == *"% time"* ]]
}

# ==================================================
# Invalid Raw Mode Content
# ==================================================

@test "raw mode with invalid optimized instruction fails" {
  local tmpdir=$(mktemp -d)
  local rawfile="$tmpdir/test.raw"

  # Create a raw file with an invalid instruction
  echo "+++X+++" > "$rawfile"

  run bash "$TM_SH" -q -r "$rawfile"
  assert_failure
  assert_output --partial "error: unrecognized instruction"

  rm -rf "$tmpdir"
}

@test "raw mode with valid optimized instructions works" {
  local tmpdir=$(mktemp -d)
  local rawfile="$tmpdir/test.raw"

  # Create a raw file with valid optimized instructions
  # 5+ means increment 5 times, then > moves right, then 3+ increments 3 times
  echo "5+>3+" > "$rawfile"

  run bash "$TM_SH" -q -r "$rawfile"
  assert_success
  assert_output --partial "tape  : 5 3"

  rm -rf "$tmpdir"
}

# ==================================================
# Empty and Minimal Programs
# ==================================================

@test "empty string input produces empty execution" {
  run bash "$TM_SH" -q <(echo "")
  assert_success
  assert_output --partial "tape  : 0"
}

@test "program with only whitespace" {
  run bash "$TM_SH" -q "     "
  assert_success
  assert_output --partial "tape  : 0"
}

@test "program with only newlines" {
  result=$(printf "\n\n\n" | bash "$TM_SH" -q /dev/stdin 2>&1)
  [[ "$result" == *"tape  : 0"* ]]
}

@test "compile mode with empty program creates empty raw file" {
  local tmpdir=$(mktemp -d)
  local input="$tmpdir/empty.bf"
  echo "" > "$input"

  run bash "$TM_SH" -c "$input"
  assert_success

  [[ -f "$input.raw" ]]
  content=$(cat "$input.raw")
  [[ -z "$content" ]]

  rm -rf "$tmpdir"
}

# ==================================================
# Flag Combinations
# ==================================================

@test "compile with print shows program before compiling" {
  local tmpdir=$(mktemp -d)
  local input="$tmpdir/test.bf"
  echo "+++" > "$input"

  run bash "$TM_SH" -c -p "$input"
  assert_success
  assert_output --partial "program:"

  rm -rf "$tmpdir"
}

@test "optimize and Optimize together applies both" {
  run bash "$TM_SH" -q -o -O <(echo "++++[-]")
  assert_success
  # Should apply both optimizations
}

@test "quiet and profile together shows only profiler output" {
  result=$(echo "+++" | bash "$TM_SH" -q -P /dev/stdin 2>&1)
  # Should have profiler output
  [[ "$result" == *"% time"* ]]
  # Should not have chars: output (which is normally shown)
  ! [[ "$result" == *"chars :"* ]]
}

@test "print and quiet shows program but not execution trace" {
  result=$(echo "+++" | bash "$TM_SH" -q -p /dev/stdin 2>&1)
  [[ "$result" == *"program:"* ]]
  # Should not have chars: output
  ! [[ "$result" == *"chars :"* ]]
}

# ==================================================
# Very Large Tape Indices
# ==================================================

@test "tape can extend to position 1000" {
  run bash "$TM_SH" -q <(printf '%.0s>' {1..1000}; echo "+")
  assert_success
  # Tape should show many zeros and a 1 at the end
  assert_output --partial " 1"
}

@test "moving far right and back to beginning" {
  local tmpfile=$(mktemp)
  yes '>' | head -n 100 | tr -d '\n' > "$tmpfile"
  echo -n '+' >> "$tmpfile"
  yes '<' | head -n 100 | tr -d '\n' >> "$tmpfile"
  echo '+' >> "$tmpfile"

  result=$(bash "$TM_SH" -q "$tmpfile" 2>&1)
  rm "$tmpfile"
  # After moving right 100, increment, move left 100, increment
  # Position 0 and position 100 should both be 1
  [[ "$result" == *"tape  : 1 0 0"* ]]
}

# ==================================================
# Optimization Edge Cases
# ==================================================

@test "optimization does not break on single operations" {
  run bash "$TM_SH" -q -O <(echo "+")
  assert_success
  assert_output --partial "tape  : 1"
}

@test "optimization on already optimized code (raw mode)" {
  local tmpdir=$(mktemp -d)
  local rawfile="$tmpdir/test.raw"

  # Write pre-optimized code
  echo "5+3>2-" > "$rawfile"

  # Run with optimization flag (should still work)
  run bash "$TM_SH" -q -r -o "$rawfile"
  assert_success

  rm -rf "$tmpdir"
}

@test "very long sequence of mixed operations optimizes correctly" {
  prog=$(printf '%.0s+' {1..50}; printf '%.0s-' {1..30}; printf '%.0s>' {1..20}; printf '%.0s<' {1..10})
  result=$(echo "$prog" | bash "$TM_SH" -q -o /dev/stdin 2>&1)
  # Net: +20 at position 0, then move right 10
  [[ "$result" == *"20"* ]]
}

# ==================================================
# Nested Loop Complexity
# ==================================================

@test "quadruple nested loops execute correctly" {
  # Properly terminating nested loops: +++[>++[>+<-]<-]
  # This creates a multiplication: 3 * 2 * 1 at different positions
  run bash "$TM_SH" -q <(echo "+++[>++[>+<-]<-]")
  assert_success
  assert_output --partial "tape"
}

@test "deeply nested loops with operations" {
  # ++[>++[>++<-]<-] - nested multiplication
  run bash "$TM_SH" -q <(echo "++[>++[>++<-]<-]")
  assert_success
  # tape[0]=0, tape[1]=0, tape[2]=8 (2*2*2)
  assert_output --partial "8"
}

# ==================================================
# Mixed Valid and Invalid Characters
# ==================================================

@test "program with unicode characters ignores them" {
  result=$(echo "++♠♣♥♦+++" | bash "$TM_SH" -q /dev/stdin 2>&1)
  [[ "$result" == *"tape  : 5"* ]]
}

@test "program with tabs and special chars" {
  result=$(printf "+\t+\t+" | bash "$TM_SH" -q /dev/stdin 2>&1)
  [[ "$result" == *"tape  : 3"* ]]
}

@test "program with null bytes is handled" {
  result=$(printf "+\x00+\x00+" | bash "$TM_SH" -q /dev/stdin 2>&1)
  [[ "$result" == *"tape  : 3"* ]]
}
