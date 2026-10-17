#!/bin/bash
set -euo pipefail

DAYLEFT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DAYLEFT_ROOT"
source tooling/versions.env
DAYLEFT_XCODEGEN=".tools/xcodegen/bin/xcodegen"
DAYLEFT_SWIFT_FORMAT=".tools/swift-format/bin/swift-format"
DAYLEFT_LOCK=".build/dayleft-validation.lock"

doctor() {
  local developer_dir
  developer_dir="$(xcode-select -p)"
  if [[ -z "${DEVELOPER_DIR:-}" && "$developer_dir" == *CommandLineTools* ]]; then
    printf 'Full Xcode is required, but the active developer directory is %s.\n' \
      "$developer_dir" >&2
    printf 'Select Xcode with: sudo xcode-select -s /Applications/Xcode.app\n' >&2
    printf 'or export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer\n' >&2
    exit 1
  fi
  xcodebuild -version
  swift --version
  command -v python3
  local local_xcode
  local_xcode="$(xcodebuild -version | awk 'NR == 1 { print $2 }')"
  printf 'Local Xcode %s; hosted CI uses Xcode %s.\n' "$local_xcode" "$CI_XCODE_VERSION"
  if [[ "${local_xcode%%.*}" -lt "${CI_XCODE_VERSION%%.*}" ]]; then
    printf 'warning: local Xcode is older than CI; build results may differ.\n' >&2
  fi
}

setup_xcodegen() {
  if [[ -x "$DAYLEFT_XCODEGEN" ]] && \
    [[ "$("$DAYLEFT_XCODEGEN" --version)" == "Version: $XCODEGEN_VERSION" ]]; then
    return
  fi
  mkdir -p .tools
  local archive=".tools/xcodegen-$XCODEGEN_VERSION.zip"
  curl --fail --location --silent --show-error \
    "https://github.com/yonaskolb/XcodeGen/releases/download/$XCODEGEN_VERSION/xcodegen.zip" \
    --output "$archive"
  printf '%s  %s\n' "$XCODEGEN_SHA256" "$archive" | shasum -a 256 --check
  ditto -x -k "$archive" .tools
  [[ "$("$DAYLEFT_XCODEGEN" --version)" == "Version: $XCODEGEN_VERSION" ]]
}

setup_swift_format() {
  if [[ -x "$DAYLEFT_SWIFT_FORMAT" ]] && \
    [[ "$("$DAYLEFT_SWIFT_FORMAT" --version)" == "$SWIFT_FORMAT_VERSION" ]]; then
    return
  fi
  local source=".tools/src/swift-format"
  rm -rf "$source"
  mkdir -p .tools/src .tools/swift-format/bin
  git -c advice.detachedHead=false clone --quiet --depth 1 \
    --branch "$SWIFT_FORMAT_VERSION" https://github.com/swiftlang/swift-format.git "$source"
  if [[ "$(git -C "$source" rev-parse HEAD)" != "$SWIFT_FORMAT_COMMIT" ]]; then
    printf 'swift-format %s does not match the pinned commit.\n' "$SWIFT_FORMAT_VERSION" >&2
    exit 1
  fi
  swift package --package-path "$source" resolve
  swift package --package-path "$source" resolve swift-syntax --revision "$SWIFT_SYNTAX_COMMIT"
  if ! grep -q "\"revision\" : \"$SWIFT_SYNTAX_COMMIT\"" "$source/Package.resolved"; then
    printf 'swift-syntax did not resolve to the pinned commit.\n' >&2
    exit 1
  fi
  swift build --package-path "$source" -c release --product swift-format --jobs 2
  cp "$source/.build/release/swift-format" "$DAYLEFT_SWIFT_FORMAT"
  rm -rf "$source"
  [[ "$("$DAYLEFT_SWIFT_FORMAT" --version)" == "$SWIFT_FORMAT_VERSION" ]]
}

setup() {
  doctor
  setup_xcodegen
  setup_swift_format
  generate
}

generate() {
  if [[ ! -x "$DAYLEFT_XCODEGEN" ]]; then
    printf 'Run make setup first.\n' >&2
    exit 1
  fi
  "$DAYLEFT_XCODEGEN" generate --no-env --spec project.yml
}

require_swift_format() {
  if [[ ! -x "$DAYLEFT_SWIFT_FORMAT" ]]; then
    printf 'Run make setup first.\n' >&2
    exit 1
  fi
}

lint() {
  require_swift_format
  bash -n scripts/dev.sh scripts/stamp_build_info.sh
  python3 scripts/check_structure.py
  "$DAYLEFT_SWIFT_FORMAT" lint --strict --recursive Package.swift App Sources Tests
}

format() {
  require_swift_format
  "$DAYLEFT_SWIFT_FORMAT" format --in-place --recursive Package.swift App Sources Tests
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

# Release build signed ad hoc for running on this Mac only; not a distributable release.
build_local_app() {
  generate
  xcodebuild -project Dayleft.xcodeproj -scheme Dayleft \
    -configuration Release -destination 'generic/platform=macOS' \
    -derivedDataPath .build/xcode-local -jobs 2 \
    CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= build -quiet
  codesign --verify --strict .build/xcode-local/Build/Products/Release/Dayleft.app
  printf 'Built .build/xcode-local/Build/Products/Release/Dayleft.app\n'
}

lock_validation() {
  mkdir -p .build
  if ! mkdir "$DAYLEFT_LOCK" 2>/dev/null; then
    local owner=""
    if [[ -f "$DAYLEFT_LOCK/pid" ]]; then owner="$(cat "$DAYLEFT_LOCK/pid")"; fi
    if [[ -n "$owner" ]] && ! kill -0 "$owner" 2>/dev/null; then
      printf 'Stale lock %s: recorded PID %s has exited.\n' "$DAYLEFT_LOCK" "$owner" >&2
      printf 'After confirming no validation is running, remove it with: rm -r %s\n' \
        "$DAYLEFT_LOCK" >&2
    else
      printf 'Another validation (PID %s) owns %s. Wait for it to finish.\n' \
        "${owner:-unknown}" "$DAYLEFT_LOCK" >&2
    fi
    exit 1
  fi
  printf '%s\n' "$$" > "$DAYLEFT_LOCK/pid"
  trap unlock_validation EXIT
}

unlock_validation() {
  rm -f "$DAYLEFT_LOCK/pid"
  rmdir "$DAYLEFT_LOCK" 2>/dev/null || true
  trap - EXIT
}

case "${1:-}" in
  setup) lock_validation; setup ;;
  doctor) doctor ;;
  generate) lock_validation; generate ;;
  lint) lock_validation; lint ;;
  format) lock_validation; format ;;
  test) lock_validation; test_core ;;
  build) lock_validation; build_app ;;
  app) lock_validation; build_local_app ;;
  check)
    lock_validation
    lint
    test_core
    build_app
    ;;
  open)
    lock_validation
    generate
    unlock_validation
    open Dayleft.xcodeproj
    ;;
  *) printf 'Usage: make {setup|doctor|generate|lint|format|test|build|check|app|open}\n' >&2; exit 2 ;;
esac
