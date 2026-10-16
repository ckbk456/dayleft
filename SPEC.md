# Product specification

## Purpose

Dayleft is a native macOS menu bar utility that persistently reminds a person that the time in
their chosen work window is finite. It supports deliberate use of that time. It is useful on
its own, without accounts, tracking services, or a connection to another application.

## Approved design

The selected direction is the compact dark countdown with a large remaining-time label and a
horizontal workday-progress bar. See [the approved visual](docs/design/approved-menu-bar.png).
The image is visual direction; its decorative slogan and unimplemented controls are not product
requirements. The scaffold uses this direction in a fixed sample-day preview.

The menu bar shows a small hourglass and hours/minutes. Clicking opens a panel with remaining
time, finish time, a clearly identified elapsed-workday bar, and work-hour controls. Keep the
primary countdown prominent when later connected information is enabled.

## Standalone MVP: intended behavior

- Let the user choose recurring start and finish times for a workday. Initial delivery may use
  one same-day daily window; workweek and overnight scheduling require a separate design decision.
- Let the user change today's hours without changing the recurring defaults.
- Before work, identify the next start; during work, show the remaining work-window time;
  at the cutoff, show that the workday is finished. Do not immediately replace this with a
  nearly full-day countdown to tomorrow. Define the day-rollover behavior during scheduling work.
- Recompute from the current clock. Refresh after sleep/wake, clock changes, timezone changes,
  settings edits, and day rollover. Resolve local dates with a calendar, not fixed 86,400-second days.
- Use hours/minutes by default. The current core rounds partial minutes up.
- Persist user preferences locally. Include Settings, Quit, and opt-in launch at login.
- Work offline with no account or external service dependency.

## Connections after MVP

**Slopometer:** optionally display a selected daily output goal and current count, with
Behind target / On pace / Ahead of target. Slopometer owns activity counting, metric selection,
repository/author scope, and goal identity. The integration must agree on the goal day/timezone
and how the work window maps to that goal. Show freshness and unavailable states. Even pacing
is a heuristic; define its tolerance before implementation.

**Task lists:** optionally display outstanding tasks from a selected provider/list alongside
remaining time. Google Tasks is a candidate, not a committed implementation or verified
connection. Evaluate other providers separately. A task count is not an effort estimate;
do not claim workload fit without duration estimates.

Connected sections appear only when enabled. A person using the standalone timer should not
have to dismiss setup prompts for unrelated connections.

## Decisions still open

Workweek/overnight scheduling, break accounting, ambiguous/nonexistent local clock times,
final app name and icon, theme/accessibility polish, distribution/signing identity,
and integration transport/provider selection remain open. Resolve each at its owning milestone.

## Current implementation

This specification describes intended behavior. For implemented behavior, read
[the timing contract](docs/logic/timing.md) and [scope](SCOPE.md).
