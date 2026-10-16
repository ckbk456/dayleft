# Dayleft

A small native macOS menu bar app that reminds you how much of your chosen workday is left.

**Status: development scaffold, not a completed timer.** The app currently opens a fixed
09:00–18:00 sample day at 14:36, displaying `3h 24m`. Quit works; live scheduling,
editable hours, persistence, today-only adjustments, and login launch are upcoming MVP work.

![Approved menu bar direction](docs/design/approved-menu-bar.png)

The MVP is a standalone, local timer. Optional Slopometer goal pacing and task-list connections
belong after MVP. The timer remains complete and usable without connecting an account.

## Develop

Requirements: macOS 13+, full Xcode 16.4 or newer selected with `xcode-select`, command line
tools, Python 3, and `make`. XcodeGen 2.46.0 is downloaded into `.tools/` by `make setup`,
with its release archive verified by SHA-256. There are no third-party app dependencies.

```sh
make setup
make check
make open
```

In Xcode, select the **Dayleft** scheme and **My Mac**, then Run. The app appears in the menu
bar without a Dock icon. Choose **Quit** in its panel to stop it. For a local development run,
select **Sign to Run Locally** if Xcode requests signing configuration; no development team
or provider credentials are stored in this project.

`make build` creates an unsigned validation artifact at
`.build/xcode/Build/Products/Debug/Dayleft.app`. It verifies compilation; it is not a signed,
notarized release. `Dayleft.xcodeproj` is generated and ignored; edit `project.yml` instead.

## Project

- [Product specification](SPEC.md) and [scope](SCOPE.md): intended behavior and MVP boundaries.
- [Roadmap](ROADMAP.md): scaffold, standalone MVP, then optional connections.
- [Development guide and command registry](docs/development.md).
- [Documentation index](docs/README.md) and [current timing contract](docs/logic/timing.md).
- [Manual verification](testing/MANUAL%20TO-DO/README.md): pending human checks.
- [Contributing](CONTRIBUTING.md) and [agent operating contract](AGENTS.md).

Swift 6 provides the shared timing core and Swift Testing covers its boundaries. SwiftUI
`MenuBarExtra` provides the native menu bar surface. CI runs structural checks, formatting lint,
core tests, and an unsigned Debug build on macOS 15 with Xcode 16.4.

The name Dayleft is a working project name; name and trademark availability have not been assessed.
