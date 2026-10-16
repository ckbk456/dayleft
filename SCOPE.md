# Scope and delivery boundaries

## This bootstrap includes

- A native SwiftUI macOS app target and generated Xcode project.
- An option-1-inspired fixed sample-day menu bar preview with a working Quit action.
- A dependency-free Swift package with a resolved-time-interval timing core and boundary tests.
- Versioned XcodeGen setup, a serial validation gate, CI, project instructions, and product docs.
- A public source repository. This initial publication is not a release.

## Standalone timer MVP remains to implement

Live schedule resolution and refresh, persistent editable work hours, today-only overrides,
before/during/after-work presentation, day rollover, Settings, opt-in login launch, lifecycle
and accessibility verification. See [SPEC.md](SPEC.md) for the intended behavior.

## Explicitly after MVP

Slopometer communication and goal pacing; Google Tasks or other task providers; authentication,
account management, task write-back, sync/conflict handling, and related network entitlements.
Do not add a plugin framework in anticipation of unbuilt connections.

## Outside this bootstrap

Production deployment, signing identities, notarization, App Store submission, automatic updates,
telemetry, billing, public binary releases, and end-user support promises.

## Authority

The bootstrap request authorizes the initial scaffold and public repository. It does not authorize
a pull request, merging existing development branches, releases, deployment, or changes to the
Slopometer repository. Future changes follow the request-mode rules in [AGENTS.md](AGENTS.md).
