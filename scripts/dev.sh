#!/bin/bash
set -euo pipefail

DAYLEFT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DAYLEFT_ROOT"
source tooling/versions.env
DAYLEFT_XCODEGEN=".tools/xcodegen/bin/xcodegen"
DAYLEFT_LOCK=".build/dayleft-validation.lock"

doctor() {
  xcode-select -p
  xcodebuild -version
  swift --version
  xcrun --find swift-format
  command -v python3
}

setup() {
  doctor
  if [[ ! -x "$DAYLEFT_XCODEGEN" ]] || \
    [[ "$("$DAYLEFT_XCODEGEN" --version)" != "Version: $XCODEGEN_VERSION" ]]; then
    mkdir -p .tools
    local archive=".tools/xcodegen-$XCODEGEN_VERSION.zip"
    curl --fail --location --silent --show-error \
      "https://github.com/yonaskolb/XcodeGen/releases/download/$XCODEGEN_VERSION/xcodegen.zip" \
      --output "$archive"
    printf '%s  %s\n' "$XCODEGEN_SHA256" "$archive" | shasum -a 256 --check
    ditto -x -k "$archive" .tools
  fi
  [[ "$("$DAYLEFT_XCODEGEN" --version)" == "Version: $XCODEGEN_VERSION" ]]
  generate
}

generate() {
  if [[ ! -x "$DAYLEFT_XCODEGEN" ]]; then
    printf 'Run make setup first.\n' >&2
    exit 1
  fi
  "$DAYLEFT_XCODEGEN" generate --no-env --spec project.yml
}

lint() {
  bash -n scripts/dev.sh
  python3 scripts/check_structure.py
  xcrun swift-format lint --strict --recursive Package.swift App Sources Tests
}

test_core() {
  swift test --jobs 2 -Xswiftc -warnings-as-errors
}

build_app() {
  generate
  xcodebuild -project Dayleft.xcodeproj -scheme Dayleft \
    -configuration Debug -destination 'generic/platform=macOS' \
    -derivedDataPath .build/xcode -jobs 2 \
    CODE_SIGNING_ALLOWED=NO build -quiet
}

lock_validation() {
  mkdir -p .build
  if ! mkdir "$DAYLEFT_LOCK" 2>/dev/null; then
    printf 'Another validation owns %s. Inspect its PID before retrying.\n' "$DAYLEFT_LOCK" >&2
    if [[ -f "$DAYLEFT_LOCK/pid" ]]; then cat "$DAYLEFT_LOCK/pid" >&2; fi
    exit 1
  fi
  printf '%s\n' "$$" > "$DAYLEFT_LOCK/pid"
  trap 'rm -f "$DAYLEFT_LOCK/pid"; rmdir "$DAYLEFT_LOCK"' EXIT
}

case "${1:-}" in
  setup) setup ;;
  doctor) doctor ;;
  generate) generate ;;
  lint) lock_validation; lint ;;
  format)
    lock_validation
    xcrun swift-format format --in-place --recursive Package.swift App Sources Tests
    ;;
  test) lock_validation; test_core ;;
  build) lock_validation; build_app ;;
  check)
    lock_validation
    lint
    test_core
    build_app
    ;;
  open) generate; open Dayleft.xcodeproj ;;
  *) printf 'Usage: make {setup|doctor|generate|lint|format|test|build|check|open}\n' >&2; exit 2 ;;
esac
