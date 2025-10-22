#!/bin/bash
echo "Running Rust Clippy..."
cargo clippy -- -D warnings
