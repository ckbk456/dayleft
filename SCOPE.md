# Scope and delivery boundaries

## Implemented

- A native SwiftUI menu bar app with a live countdown and panel from the default or saved hours.
- A dependency-free timing core: schedules, weekdays, overnight shifts, today-only changes,
  day states, refresh boundaries, and 24-hour dial geometry, with deterministic tests.
- A presentation layer for menu bar, panel, and VoiceOver text; local settings persistence;
  refresh on wake, clock, time-zone, locale, and day changes; a login-item wrapper.
- Pinned tooling, a serial validation gate, CI, project instructions, and product docs.

## Standalone timer MVP remains to implement

The dial component, Settings, "Adjust today…", the login-launch control, and the human checks
in [the timer guide](testing/MANUAL%20TO-DO/timer.md). See [SPEC.md](SPEC.md) and
[the foundation plan](docs/plans/foundation.md).

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
