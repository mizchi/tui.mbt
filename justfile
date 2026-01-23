# MoonBit Project Commands

# Default target (js for browser compatibility)
target := "js"

# Default task: check and test
default: check test

# Format code
fmt:
    moon fmt

# Type check
check:
    moon check --deny-warn --target {{target}}

# Run tests
test:
    moon test --target {{target}}

# Update snapshot tests
test-update:
    moon test --update --target {{target}}

# Run main
run:
    moon run src/main --target {{target}}

# Generate type definition files
info:
    moon info

# Clean build artifacts
clean:
    moon clean

# Generate component snapshots
snapshot:
    #!/usr/bin/env bash
    mkdir -p __snapshots__
    moon run examples/snapshot --target {{target}} 2>/dev/null | grep -v "^Generating\|^Done\|^To save\|^  moon" > __snapshots__/components.txt
    echo "Generated __snapshots__/components.txt ($(wc -l < __snapshots__/components.txt) lines)"
    moon run examples/snapshot-ansi --target {{target}} 2>/dev/null > __snapshots__/components.ansi
    echo "Generated __snapshots__/components.ansi ($(wc -l < __snapshots__/components.ansi) lines)"

# Run story lints (odd dimensions, reasonable sizes, etc.)
lint:
    moon run examples/lint --target {{target}}

# Pre-release check
release-check: fmt info check test lint

# Hot reload dev server
dev example="chat":
    node scripts/dev.js {{example}} --target {{target}}
