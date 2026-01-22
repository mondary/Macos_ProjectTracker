#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
exec /usr/bin/env swift "${PWD}/menubar/ProjectTrackerMenuBar.swift"
