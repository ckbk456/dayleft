# Development environment

## Toolchain and sources

- Deployment target: macOS 13.0. Swift tools/language mode: 6.0; no package dependencies.
- Local bootstrap verified with Xcode 27.1 (27A9275), Swift 6.4, macOS 27.0.1, Python 3.14.6.
- CI selects Xcode 16.4 on `macos-15`, whose [official runner inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md)
  lists that installation. Runner images can change; inspect the selected runner if it disappears.
- XcodeGen is pinned to [2.46.0](https://github.com/yonaskolb/XcodeGen/releases/tag/2.46.0).
  [Versioned project specification](https://github.com/yonaskolb/XcodeGen/blob/2.46.0/Docs/ProjectSpec.md)
  owns `project.yml` syntax. `tooling/versions.env` records the official release asset's SHA-256.
- SwiftUI [MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra)
  owns the menu bar surface; `LSUIElement` hides the Dock/application-switcher entry.
- Use installed `xcodebuild -help`, `swift test --help`, and `xcrun swift-format --help` for
  toolchain-specific flags. Formatting comes from the selected Xcode and `.swift-format`.

`make setup` downloads only a checksum-verified tool into the repository's ignored `.tools/`
directory, then generates `Dayleft.xcodeproj`. It does not install global packages or change
the selected Xcode. Full Xcode, its license acceptance/first-run components, Python, and make
are host prerequisites; the script reports failure if they are unavailable.

## Command registry

All commands run from the repository root. Estimates are initial investigation budgets,
not guarantees. The command definitions are `Makefile` and `scripts/dev.sh` unless stated.

| Purpose | Exact command | Source | Expected time | CPU intensive | Environment / mode |
|---|---|---|---|---|---|
| Inspect tools | `make doctor` | `scripts/dev.sh:doctor` | <10 s | No | macOS, full Xcode; diagnostic |
| Set up tool/project | `make setup` | `tooling/versions.env`, setup/generate functions | <1 min | Low | Network for pinned archive; conditional |
| Regenerate project | `make generate` | `project.yml` | <10 s | Low | Pinned local tool; deterministic |
| Check metadata/links/style | `make lint` | checker, plists, `.swift-format` | <30 s | Low | Python 3, Xcode formatter; deterministic per toolchain |
| Rewrite Swift formatting | `make format` | `.swift-format` | <30 s | Low | Mutating, explicitly intended formatting only |
| Test core | `make test` | `Package.swift`, core tests | <3 min cold | Yes | Swift 6+, one shot, 2 jobs |
| Build unsigned app | `make build` | `project.yml`, app, local package | <3 min cold | Yes | Full Xcode, macOS SDK, 2 jobs |
| Complete local/CI gate | `make check` | lint → test → build | <5 min cold | Yes, serial | Same prerequisites as above; deterministic per toolchain |
| Open native project | `make open` | project generator, macOS `open` | <10 s | No | Human-owned GUI handoff |
| Run native preview | Xcode: Dayleft scheme → My Mac → Run | generated scheme | <1 min | Build is intensive | Human-owned; local signing choice may be required |

The shell gate holds `.build/dayleft-validation.lock`, records its PID, and removes it on exit.
Do not bypass it or use `make -j`; do not remove a live lock. Verify process exit before
recovering a stale lock. Shell-owned commands are kept until completion; no watchers are used.

## Layout

`App/` is the native sample UI. `Sources/DayleftCore` is the dependency-free timing model.
`Tests/DayleftCoreTests` owns deterministic behavior checks. The Xcode app links that same
local package. There is no remote package resolution, database, migration, service, listener,
provider configuration, signing secret, or environment file in this scaffold.

## Validation and release boundaries

CI uses a SHA-pinned checkout action, checksum-pinned generator, one serial gate, minimal read
permission, and a 15-minute timeout. It verifies metadata/docs links, Swift style, core tests,
and an unsigned Debug app build. It does not run a native UI suite or sign/notarize the app.

Record local and actual hosted CI results separately in the delivery handoff. Human verification
is consolidated in [the timer guide](../testing/MANUAL%20TO-DO/timer.md). A successful compile,
an app screenshot, or fixed sample UI is not proof that live-timer MVP behavior works.
