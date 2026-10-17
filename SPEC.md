# Product specification

## Purpose

Dayleft is a native macOS menu bar utility that persistently reminds a person that the time in
their chosen work window is finite. It supports deliberate use of that time. It is useful on
its own, without accounts, tracking services, or a connection to another application.

## Approved design

The selected direction is the compact dark countdown with a large remaining-time label and a
horizontal workday-progress bar. See [the approved visual](docs/design/approved-menu-bar.png).
The image is visual direction; its decorative slogan is not a product requirement.

The menu bar shows a small hourglass and hours/minutes. Clicking it opens a compact, read-only
panel: remaining time, finish time, a clearly identified elapsed-workday bar, today's hours, and
the regular schedule. Nothing is edited inside the panel. Its rows, a Settings button, and ⌘, open a
separate settings window (tabs across the top: Today, Regular Schedule, General, About), where hours are
edited on a 24-hour dial. The UI uses two terms consistently: the **regular schedule** (day
plans with their weekdays and sessions) and **today's work** (a today-only change that never
edits the schedule). On macOS 26 and later the panel and window use Liquid Glass; macOS 14 and
15 keep the standard materials. The app has a Dock icon only while that window is open. Keep
the primary countdown prominent when later connected information is enabled.

## Standalone MVP: intended behavior

- The regular schedule is a list of up to 7 **day plans** (e.g. "Weekdays", "Weekend"). Each
  plan has a name, the weekdays it owns (a weekday belongs to at most one plan; days in no plan
  are days off, e.g. a Wednesday off), and 1–4 **sessions**. Defaults: one "Weekdays" plan,
  Monday–Friday, 09:00–18:00. Plans, days, and sessions can be added, edited, and removed.
- Sessions are edited on a 24-hour dial (5-minute steps, at least 15 minutes each) that draws
  every session as an arc, with a session list below it; selecting a row highlights its arc and
  gives it the handles. Sessions are separated by at least a 5-minute break and never overlap;
  only a day's last session may cross midnight, and a day's sessions fit within 24 hours.
  A session belongs to the day it starts. Breaks are not counted as work.
- Let the user change today's sessions, or take today off, without changing the regular
  schedule. The change applies to the work starting today and ends when that work ends.
- Before work, show the first start time; during a session, the time left in that session
  (the panel adds the work left today across sessions); on a break between sessions, the next
  session's start (the panel labels it a break and counts down to it); after the last cutoff,
  `Done` until local midnight or the next start, whichever is first; on a day off, `Off`. Work
  that ended today from yesterday's overnight session shows `Done`, not a break. Do not replace
  `Done` with a nearly full-day countdown. Working past the cutoff is not shown.
- The panel's progress bar spans the day's first start to its last cutoff; sessions are
  segments, breaks are gaps, and work before now is solid.
- Settings saved by versions with a single set of hours migrate to one plan with one session.
- Skipped local times move to the next valid time and repeated times use their first
  occurrence; countdowns use real elapsed time.
- Recompute from the current clock. Refresh after sleep/wake, clock changes, timezone changes,
  settings edits, and day rollover. Resolve local dates with a calendar, not fixed 86,400-second days.
- Use hours/minutes, rounding partial minutes up. Follow the system 12/24-hour setting and
  light/dark appearance.
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

Working-past-cutoff display, final app name and
icon, theme/accessibility polish, distribution/signing identity,
and integration transport/provider selection remain open. Resolve each at its owning milestone.

## Current implementation

This specification describes intended behavior. For implemented behavior, read
[the timing contract](docs/logic/timing.md) and [scope](SCOPE.md).
