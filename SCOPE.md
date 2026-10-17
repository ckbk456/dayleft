# Scope and delivery boundaries

## Implemented

- A native SwiftUI menu bar app with a live countdown and a compact read-only panel.
- A separate settings window: the regular schedule as day plans (weekdays plus up to four
  sessions each, edited on a multi-session 24-hour dial with a session list), opt-in login
  launch, and a Today pane for different sessions or a day off on the current day.
- A dependency-free timing core: day plans, sessions and breaks, overnight sessions, today-only changes,
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
