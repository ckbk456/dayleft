# Development environment

## Toolchain and sources

- Deployment target: macOS 14.0. Swift tools/language mode: 6.0; no package dependencies.
- Local bootstrap verified with Xcode 27.1 (27A9275), Swift 6.4, macOS 27.0.1, Python 3.14.6.
- CI selects Xcode 26.6 on `macos-26`, whose [official runner inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md)
  lists that installation. The `xcode-27` image is a preview with an Xcode beta, so it is not
  the gate. Runner images change; inspect the selected runner if it disappears.
- XcodeGen is pinned to [2.46.0](https://github.com/yonaskolb/XcodeGen/releases/tag/2.46.0).
  [Versioned project specification](https://github.com/yonaskolb/XcodeGen/blob/2.46.0/Docs/ProjectSpec.md)
  owns `project.yml` syntax. `tooling/versions.env` records the official release asset's SHA-256.
- SwiftUI [MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra)
  owns the menu bar surface; `LSUIElement` hides the Dock/application-switcher entry.
- [swift-format 604.0.0](https://github.com/swiftlang/swift-format/releases/tag/604.0.0) has no
  release binary. Setup builds that tag after checking its commit, pins its swift-syntax
  commit, and installs `.tools/swift-format/bin/swift-format`. Lint and format use only that
  binary with `.swift-format`, so results do not depend on the Xcode version.
- `make doctor` rejects a Command Line Tools–only developer directory and reports the local
  and CI Xcode versions, warning when the local major version is older than CI.

`make setup` installs only the pinned tools into the repository's ignored `.tools/`
directory, then generates `Dayleft.xcodeproj`. It does not install global packages or change
the selected Xcode. Full Xcode, its license acceptance/first-run components, Python, and make
are host prerequisites; the script reports failure if they are unavailable.

## Command registry

All commands run from the repository root. Estimates are initial investigation budgets,
not guarantees. The command definitions are `Makefile` and `scripts/dev.sh` unless stated.

| Purpose | Exact command | Source | Expected time | CPU intensive | Environment / mode |
|---|---|---|---|---|---|
| Inspect tools | `make doctor` | `scripts/dev.sh:doctor` | <10 s | No | macOS, full Xcode; diagnostic |
| Set up tools/project | `make setup` | `tooling/versions.env`, setup/generate functions | <5 min first run | Yes, first run | Network for pinned sources; conditional |
| Regenerate project | `make generate` | `project.yml` | <10 s | Low | Pinned local tool; deterministic |
| Check metadata/links/style | `make lint` | checker, plists, `.swift-format` | <30 s | Low | Python 3, Xcode formatter; deterministic per toolchain |
| Rewrite Swift formatting | `make format` | `.swift-format` | <30 s | Low | Mutating, explicitly intended formatting only |
| Test core | `make test` | `Package.swift`, core tests | <3 min cold | Yes | Swift 6+, one shot, 2 jobs |
| Build unsigned app | `make build` | `project.yml`, app, local package | <3 min cold | Yes | Full Xcode, macOS SDK, 2 jobs |
| Complete local/CI gate | `make check` | lint → test → build | <5 min cold | Yes, serial | Same prerequisites as above; deterministic per toolchain |
| Open native project | `make open` | project generator, macOS `open` | <10 s | No | Human-owned GUI handoff |
| Run native preview | Xcode: Dayleft scheme → My Mac → Run | generated scheme | <1 min | Build is intensive | Human-owned; local signing choice may be required |

Every command except `doctor` holds `.build/dayleft-validation.lock`, records its PID, and
removes it on exit (`open` releases it before launching Xcode). Do not bypass it or use
`make -j`; do not remove a live lock. A blocked command reports whether the recorded PID has
exited; confirm that before removing a stale lock. Shell-owned commands are kept until completion; no watchers are used.

## Layout

`App/` is the native UI and its models (timer refresh, settings persistence, login item).
`Sources/DayleftCore` is the dependency-free timing model; `Sources/DayleftPresentation` turns
day states into menu bar, panel, and VoiceOver text and owns the stored settings format.
`Tests/DayleftCoreTests` owns deterministic behavior checks. The Xcode app links that same
local package. There is no remote package resolution, database, migration, service, listener,
provider configuration, signing secret, or environment file. Settings live in local defaults.

## Validation and release boundaries

CI runs on pushes to `main` and on pull requests. It uses SHA-pinned checkout and cache
actions, pinned tools cached by `tooling/versions.env`, one serial gate, minimal read
permission, and a 20-minute timeout. It verifies metadata/docs links, Swift style, core tests,
and an unsigned Debug app build. It does not run a native UI suite or sign/notarize the app.

Record local and actual hosted CI results separately in the delivery handoff. Human verification
is consolidated in [the timer guide](../testing/MANUAL%20TO-DO/timer.md). A successful compile,
or an app screenshot is not proof that live-timer MVP behavior works.
