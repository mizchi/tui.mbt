# MoonBit Project Commands
# Library and examples form a single workspace (see moon.work),
# so a root `moon <cmd>` covers every member.

# Default target (js for browser compatibility)
target := "js"

# Default task: check and test
default: check test

# Format code (whole workspace)
fmt:
    moon fmt

# Type check whole workspace (library + examples)
check:
    moon check --deny-warn --target {{target}}

# Check that the native C stub stays Windows-compatible
check-windows-native:
    ./scripts/check-windows-native-compat.sh

# Check everything
check-all: check-windows-native check

# Run tests (whole workspace)
test:
    moon test --target {{target}}

# Test everything
test-all: test

# Update snapshot tests
test-update:
    moon test --update --target {{target}}

# Run example (default: simple)
run example="simple":
    cd examples/{{example}} && moon run . --target {{target}}

# Generate type definition files (whole workspace)
info:
    moon info

# Clean build artifacts (whole workspace)
clean:
    moon clean

# Generate component snapshots
snapshot:
    #!/usr/bin/env bash
    mkdir -p __snapshots__
    (cd examples/snapshot && moon run . --target {{target}}) 2>/dev/null | grep -v "^Generating\|^Done\|^To save\|^  moon" > __snapshots__/components.txt
    echo "Generated __snapshots__/components.txt ($(wc -l < __snapshots__/components.txt) lines)"
    (cd examples/snapshot-ansi && moon run . --target {{target}}) 2>/dev/null > __snapshots__/components.ansi
    echo "Generated __snapshots__/components.ansi ($(wc -l < __snapshots__/components.ansi) lines)"

# Run story lints (odd dimensions, reasonable sizes, etc.)
lint:
    cd examples/lint && moon run . --target {{target}}

# Pre-release check
release-check: fmt info check-all test-all lint

# Hot reload dev server
dev example="simple":
    node scripts/dev.js {{example}} --target {{target}}
