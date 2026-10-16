# Scope and delivery boundaries

## Implemented

- A native SwiftUI menu bar app with a live countdown and the approved panel layout.
- Settings with a 24-hour dial, workday toggles, and opt-in login launch; "Adjust today…" for
  custom hours or a day off on the current shift.
- A dependency-free timing core: schedules, weekdays, overnight shifts, today-only changes,
  day states, refresh boundaries, and 24-hour dial geometry, with deterministic tests.
- A presentation layer for menu bar, panel, and VoiceOver text; local settings persistence;
  refresh on wake, clock, time-zone, locale, and day changes; a login-item wrapper.
- Pinned tooling, a serial validation gate, CI, project instructions, and product docs.

## Standalone timer MVP remains to verify

The human checks in [the timer guide](testing/MANUAL%20TO-DO/timer.md): native menu bar
behavior, visual fidelity, accessibility, sleep/wake, clock changes, and login launch. See
[SPEC.md](SPEC.md) and [the foundation plan](docs/plans/foundation.md).

## Explicitly after MVP

Slopometer communication and goal pacing; Google Tasks or other task providers; authentication,
account management, task write-back, sync/conflict handling, and related network entitlements.
Do not add a plugin framework in anticipation of unbuilt connections.

## Outside this bootstrap

Production deployment, signing identities, notarization, App Store submission, automatic updates,
telemetry, billing, public binary releases, and end-user support promises.

## Authority

Changes follow the request-mode rules in [AGENTS.md](AGENTS.md). Authority to implement or merge
does not authorize releases, deployment, binary publication, or changes to the Slopometer
repository.
