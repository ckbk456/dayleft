# Foundation plan to the standalone MVP

Approved 2026-10-16. Sequence: PR 1 → PR 2 → PR 3 and PR 4 → MVP UI. Each PR uses its own
`codex/<name>` worktree from the latest `origin/main` and needs `make check` plus hosted CI.
Once implemented, [SPEC](../../SPEC.md) and [the timing contract](../logic/timing.md) own these
rules; this plan records the agreed order and acceptance criteria.

## Locked decisions

| Area | Decision |
|---|---|
| Licence | MIT |
| Bundle ID | `app.dayleft.Dayleft` (confirm domain ownership before a public release) |
| Minimum macOS | 14.0 |
| Default schedule | Monday–Friday, 09:00–18:00 |
| Work hours | Any start and cutoff on a 24-hour dial, 5-minute steps, at least 15 minutes, start ≠ cutoff |
| Overnight shifts | Allowed; a shift belongs to the day it starts |
| Workdays | Per-weekday on/off, at least one on; all workdays share the same hours |
| Today-only change | Custom hours or day off for the shift starting today; ends when that shift ends |
| Working past cutoff | Not shown in the MVP |
| Clock changes | Skipped start → next valid time; repeated hour → first occurrence; bar uses real elapsed time |
| Clock format | System 12/24-hour setting |
| Appearance | System light/dark |

| State | Menu bar |
|---|---|
| Working | `3h 24m` (partial minutes round up) |
| Finished | `Done` until local midnight or the next start, whichever is first; a shift ending exactly at midnight ends the day before |
| Before start | Next start time, e.g. `09:00` |
| Day off | `Off` until local midnight, then the next start |

## PR 1: toolchain and identity

MIT licence, final bundle ID, macOS 14, pinned `swift-format` built from a verified tag, CI on
the stable `macos-26` runner with Xcode 26.6, doctor/toolchain reporting, locking for project
generation, stale-lock reporting, and CI on `main` pushes plus pull requests.

The only Xcode 27 hosted runner is a preview image with an Xcode beta, so CI does not use it.
Pinning the formatter keeps lint identical across local and hosted Xcode versions.

## PR 2: timing model and dial math

Foundation-only `DayleftCore`: `TimeOfDay`, `Weekday`, `ShiftHours`, `Schedule`,
`DayOverride`, `DayState`, `ScheduleResolver` (`state`, `nextRefresh`, override expiry) and
`DialGeometry`. `WorkWindow` exposes rounded-up whole minutes and clamps non-finite instants;
text formatting leaves the core. Tests cover weekdays, overnight shifts, overrides, the
Done/before-start switch, both clock-change directions in two hemispheres, time-zone changes,
calendar edge cases, refresh alignment and dial geometry.

## PR 3: live app wiring and docs

`DayleftPresentation` package target for text, `TimerModel`, `SettingsStore` (`settings.v1`),
`LoginItem`, refresh on wake/clock/time-zone/day changes, live menu bar and panel with no fixed
sample values, verified menu bar label rendering, and product/manual-guide updates.

## PR 4: day dial component

Reusable `DayDial` with drag, keyboard and VoiceOver adjustment, synced time fields, mid-shift
warning and previews. Geometry comes from `DialGeometry`.

## MVP UI

Settings (dial, workdays, login launch), Adjust today (dial, day off), Work hours row and
footer from the approved design, all built on the models above.

### Acceptance criteria

1. First launch uses Monday–Friday 09:00–18:00 and the correct current state.
2. Each state shows the agreed menu bar text.
3. The panel shows remaining time, cutoff, elapsed bar and shift endpoints.
4. Settings apply immediately and persist after relaunch.
5. A today-only change affects only that shift and ends with it.
6. A Friday overnight shift into Saturday counts down correctly.
7. Sleep/wake, manual clock change, time-zone change and midnight refresh correctly.
8. Login launch is off by default and reflects the system status.
9. The dial and Settings are usable by keyboard and VoiceOver.
10. Light, dark and Increase Contrast appearances are readable.
11. No network or account is required.
12. `make check` and hosted CI pass.
