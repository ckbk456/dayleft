# Implemented timing contract

Owners: `Sources/DayleftCore/` (`TimeOfDay.swift`, `Schedule.swift`, `ScheduleResolver.swift`,
`WorkWindow.swift`, `DialGeometry.swift`); tests in `Tests/DayleftCoreTests/`.

The core reads no system clock and stores nothing. Callers pass the current instant and a
`Calendar` (whose time zone defines the local day) on every refresh.

## Schedule values

- `TimeOfDay` is a minute of the local day (0–1439). `ShiftHours` is one session: a start and
  cutoff on 5-minute steps, at least 15 minutes apart; a cutoff at or before the start ends the
  next day, so the longest session is 23h 55m.
- `WorkSessions` holds 1–4 sessions sorted by start. Each ends at least 5 minutes before the
  next starts, so only the last may cross midnight, and the last ends at least 5 minutes before
  the first starts again (a day fits in 24 hours). `addingSession()` centres up to an hour in the
  longest break; `removing(at:)` keeps at least one session.
- `DayPlan` names a set of weekdays and their sessions. `Schedule` holds 1–7 plans whose weekdays
  are disjoint, with at least one weekday in total; weekdays in no plan are days off.
  `Schedule.standard` is one "Weekdays" plan, Monday–Friday 09:00–18:00. `assigning(_:to:)`
  moves a weekday between plans.
- `DayOverride` replaces the sessions that start on its `LocalDay`: different sessions or a day off.
- Decoding revalidates every value, so stored data cannot bypass these rules.

## Resolving windows

A session belongs to the day it starts. `ScheduleResolver.windows(on:)` turns that day's sessions
(its override, otherwise its plan) into absolute `WorkWindow`s. A wall time inside a
daylight-saving gap moves to the next valid time; a repeated time uses its first occurrence. A
session squeezed to nothing by a gap has no window that day. Countdown and elapsed fraction
always use real elapsed seconds.

## States

`state(at:)` checks yesterday's and today's windows, then picks the first matching row:

| State | Condition | Menu bar (presentation) |
|---|---|---|
| `working` | Inside a window; yesterday's overnight session wins over today's overlapping one | Time left in the session |
| `onBreak` | One of today's sessions has ended and another of today's starts later | Next start time |
| `finished` | A window ended earlier today | `Done` |
| `beforeStart` | Today's first session starts later today | Next start time |
| `dayOff` | Otherwise: a day-off change, a day in no plan, or no valid window today | `Off` |

`finished` therefore lasts until local midnight or the next start, whichever is first; work from
yesterday's overnight session that ended today is `finished`, never a break. A session ending
exactly at midnight counts as ending the day before, so `Done` does not fill the next day.
Every state except `working` carries the next window, searched up to 15 days ahead.

`timeline(for:)` returns the windows of the day a state belongs to (the active, previous, or
ended window's day; today before the start; empty on a day off). `remainingWork(in:at:)` sums
the work left in it. The presentation draws the timeline as one bar with gaps for breaks.

`WorkWindow.Snapshot.remainingWholeMinutes` rounds up, so the final partial minute shows `1m`
and the value agrees with the minute shown by the system clock. A non-finite clock reading is
treated as before the start; values too large for `Int` clamp instead of trapping.

## Refresh and expiry

`nextRefresh(after:)` returns the earliest future instant among the next change in displayed
whole minutes (of the session, or of the break countdown), the active cutoff, the next start, and the next local midnight. Apps also refresh
on wake, clock and time-zone changes, and settings edits. `isExpired(_:at:)` reports that a
change for day D can be discarded once day D+2 begins: `state` only looks at yesterday's and
today's shifts, so the change still applies only to its own shift. Dropping it earlier would
revive the usual hours of a shift that was shortened to end now. Only one change is stored, so
applying a change for a new day replaces an older one that may still cover a running shift.

## Dial geometry

`DialGeometry` places midnight at the top running clockwise (15° per hour), converts points and
angles to 5-minute-snapped times, reports arcs, the nearest handle across sessions, the
session under an angle, and the handle or arc under a point (handles by distance in points,
preferring the selected session; arcs only near the ring; elsewhere nothing), and moves a handle while keeping 15 minutes from its own session's other
handle and a 5-minute break from neighbouring sessions. With one session, a handle approaching
the other stops on the side it came from; with several, a target outside the allowed range stops
at its nearer end, so a handle never jumps across another session. `App/Components/DayDial.swift` draws the dial and
routes drags (starting only on a handle or an arc), arrow keys, VoiceOver adjustments, and typed times through these functions. It shows
the chosen start and cutoff as large labels above the dial and the shift length below it.

## App wiring

`App/Model/TimerModel.swift` resolves with `Calendar.autoupdatingCurrent`, discards an expired
today-only change, and sleeps until `nextRefresh` (plus 50 ms so it lands after the boundary).
It also refreshes on wake, clock, time-zone, calendar-day, and locale changes and after settings
edits. `DayleftPresentation` owns all displayed text. Manual checks live in
[the timer guide](../../testing/MANUAL%20TO-DO/timer.md).
