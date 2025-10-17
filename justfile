# justfile for MRReviewer
# Run commands with: just <command>

# Run all tests
test:
    nvim --headless -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"

# Run a specific test file
# Usage: just test-file tests/diffview_spec.lua
test-file FILE:
    nvim --headless -c "lua require('plenary.test_harness').test_file('{{FILE}}', { minimal_init = 'tests/minimal_init.lua' })"

# Run tests in watch mode (re-run on file changes)
# Note: Requires entr to be installed (brew install entr)
test-watch:
    #!/usr/bin/env bash
    if ! command -v entr &> /dev/null; then
        echo "Error: entr is not installed. Install with: brew install entr"
        exit 1
    fi
    find lua tests -name '*.lua' | entr -c just test

# Run luacheck linter
lint:
    luacheck lua/ tests/

# Run stylua formatter (check mode)
format-check:
    stylua --check lua/ tests/

# Run stylua formatter (apply changes)
format:
    stylua lua/ tests/

# Show coverage summary (if available)
coverage:
    @echo "Coverage tracking via plenary test output"
    @just test | grep -E "(Success|Failed|Total)"

# Clean up temporary files
clean:
    rm -f /tmp/mrreviewer_*
    rm -f /tmp/plenary_*

# Run pre-commit checks (format, lint, test)
pre-commit:
    @echo "Running pre-commit checks..."
    @echo "1. Formatting code..."
    @just format
    @echo "2. Running linter..."
    @just lint
    @echo "3. Running tests..."
    @just test
    @echo "✓ All pre-commit checks passed!"

# List all available commands
help:
    @just --list
