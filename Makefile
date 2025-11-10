.PHONY: test lint all

all: lint test

test:
	@echo "Running test suite..."
	@tests/bats/bin/bats tests/unit/
	@tests/bats/bin/bats tests/integration/

lint:
	@echo "Running shellcheck..."
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not found. Install with: apt-get install shellcheck"; exit 1; }
	@shellcheck *.sh
