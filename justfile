# MoonBit Project Commands

# Default target (js for browser compatibility)
target := "js"

# Example directories
examples := "command-launcher completion components editor form grid-area grid-layout lint popup simple snapshot snapshot-ansi toadlike wizard"

# Default task: check and test
default: check test

# Format code
fmt:
    moon fmt
    for dir in {{examples}}; do (cd examples/$dir && moon fmt); done

# Type check main library
check:
    moon check --deny-warn --target {{target}}

# Check all examples
check-examples:
    for dir in {{examples}}; do (cd examples/$dir && moon check --deny-warn --target {{target}}); done

# Check everything
check-all: check check-examples

# Run tests for main library
test:
    moon test --target {{target}}

# Run tests for all examples
test-examples:
    for dir in {{examples}}; do (cd examples/$dir && moon test --target {{target}}); done

# Test everything
test-all: test test-examples

# Update snapshot tests
test-update:
    moon test --update --target {{target}}

# Run example (default: simple)
run example="simple":
    cd examples/{{example}} && moon run . --target {{target}}

# Generate type definition files
info:
    moon info
    for dir in {{examples}}; do (cd examples/$dir && moon info); done

# Clean build artifacts
clean:
    moon clean
    for dir in {{examples}}; do (cd examples/$dir && moon clean); done

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
