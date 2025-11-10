# BrainBash Test Suite

This directory contains automated tests for the BrainBash Brainfuck interpreter.

## Test Framework

Tests are written using [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core), a TAP-compliant testing framework for Bash.

## Test Structure

```
tests/
├── unit/                       # Unit tests for individual operations
│   ├── basic_operations.bats  # Tests for +, -, >, <, [, ], etc.
│   └── optimizations.bats     # Tests for optimization correctness
├── integration/                # Integration tests
│   └── example_programs.bats  # Tests for example .bf programs
├── helpers/                    # Test utilities
│   └── test_helper.bash       # Common test helper functions
├── bats/                       # BATS core framework (submodule)
└── test_helper/                # BATS helper libraries (submodules)
    ├── bats-support/           # BATS support library
    └── bats-assert/            # BATS assertion library
```

## Running Tests

### Run all tests:
```bash
tests/bats/bin/bats tests/unit/ tests/integration/
```

### Run specific test suite:
```bash
tests/bats/bin/bats tests/unit/basic_operations.bats
tests/bats/bin/bats tests/unit/optimizations.bats
tests/bats/bin/bats tests/integration/example_programs.bats
```

### Run a single test:
```bash
tests/bats/bin/bats tests/unit/basic_operations.bats --filter "increment"
```

## Test Coverage

### Unit Tests (23 tests)

**basic_operations.bats** - Tests core Brainfuck operations:
- Increment/decrement operations (+/-)
- Tape movement (>/<)
- Loops ([/])
- Edge cases (underflow, empty programs, comments)

**optimizations.bats** - Tests optimization correctness:
- Simple optimizations (repeated operations)
- Heavy optimizations (move patterns, zeroing, copies)
- Equivalence testing (optimized vs non-optimized output)

### Integration Tests (9 tests)

**example_programs.bats** - Tests example programs:
- hello_world.bf
- alphabet.bf
- simple.bf, loop.bf, nested_loop.bf
- optimize.bf, multiply.bf, copy.bf, counter.bf

## Known Issues

### Exit Code Behavior
The tm.sh interpreter currently exits with status 1 on successful execution and status 0 on errors. Tests have been written to work around this behavior, but this should be fixed in tm.sh:

```bash
# In tm.sh, errors should exit with non-zero:
(( tape_pos < 0 )) && { echo "error: lshift < 0" ; exit 1; }  # Not: exit

# In tm.sh shut_down function, should exit cleanly:
exit 0  # Not: exit
```

### Color Codes in Output
Tests strip ANSI color codes from output since tm.sh always outputs colors regardless of TTY status or quiet mode.

## CI Integration

Tests run automatically on Travis CI when commits are pushed. See `.travis.yml` for configuration.

## Adding New Tests

1. Create a new .bats file in the appropriate directory (unit/ or integration/)
2. Load the test helper: `load '../helpers/test_helper'`
3. Write tests using the `@test` directive
4. Run tests locally before committing

### Example Test

```bash
@test "my new test" {
  result=$(bash "$TM_SH" -q <(echo "+++") 2>&1 | grep "^tape" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$result" == *"tape  : 3"* ]]
}
```

## Test Statistics

- **Total Tests**: 32
- **Unit Tests**: 23
- **Integration Tests**: 9
- **Test Execution Time**: ~5-10 seconds
