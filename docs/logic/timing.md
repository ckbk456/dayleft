# Implemented timing contract

Owners: `Sources/DayleftCore/` (`TimeOfDay.swift`, `Schedule.swift`, `ScheduleResolver.swift`,
`WorkWindow.swift`, `DialGeometry.swift`); tests in `Tests/DayleftCoreTests/`.

The core reads no system clock and stores nothing. Callers pass the current instant and a
`Calendar` (whose time zone defines the local day) on every refresh.

## Schedule values

- `TimeOfDay` is a minute of the local day (0–1439). `ShiftHours` holds a start and cutoff on
  5-minute steps, at least 15 minutes apart; a cutoff at or before the start ends the next day,
  so the longest shift is 23h 55m.
- `Schedule` applies one `ShiftHours` to a non-empty set of weekdays. `Schedule.standard` is
  Monday–Friday 09:00–18:00.
- `DayOverride` changes only the shift that starts on its `LocalDay`: custom hours or a day off.
- Decoding revalidates every value, so stored data cannot bypass these rules.

## Resolving windows

A shift belongs to the day it starts. `ScheduleResolver.window(on:)` turns that day's hours into
an absolute `WorkWindow`. A wall time inside a daylight-saving gap moves to the next valid time;
a repeated time uses its first occurrence. A shift squeezed to nothing by a gap has no window
that day. Countdown and elapsed fraction always use real elapsed seconds.

## States

`state(at:)` checks yesterday's and today's windows, then picks the first matching row:

| State | Condition | Menu bar (presentation) |
|---|---|---|
| `working` | Inside a window; yesterday's overnight shift wins over today's overlapping change | Remaining time |
| `finished` | A window ended earlier today | `Done` |
| `beforeStart` | Today's own shift starts later today | Next start time |
| `dayOff` | Otherwise: a day-off change, a non-workday, or no valid window today | `Off` |

`finished` therefore lasts until local midnight or the next start, whichever is first. A shift
ending exactly at midnight counts as ending the day before, so `Done` does not fill the next day.
Every state except `working` carries the next window, searched up to 15 days ahead.

`WorkWindow.Snapshot.remainingWholeMinutes` rounds up, so the final partial minute shows `1m`
and the value agrees with the minute shown by the system clock. A non-finite clock reading is
treated as before the start; values too large for `Int` clamp instead of trapping.

## Refresh and expiry

`nextRefresh(after:)` returns the earliest future instant among the next change in displayed
whole minutes, the active cutoff, the next start, and the next local midnight. Apps also refresh
on wake, clock and time-zone changes, and settings edits. `isExpired(_:at:)` reports that a
change for day D can be discarded once day D+2 begins: `state` only looks at yesterday's and
today's shifts, so the change still applies only to its own shift. Dropping it earlier would
revive the usual hours of a shift that was shortened to end now. Only one change is stored, so
applying a change for a new day replaces an older one that may still cover a running shift.

## Dial geometry

`DialGeometry` places midnight at the top running clockwise (15° per hour), converts points and
angles to 5-minute-snapped times, reports the arc and the nearest handle, and moves a handle
while keeping 15 minutes from the other one. A handle approaching the other stops on the side
it came from rather than jumping across.

## Not yet implemented

## App wiring

`App/Model/TimerModel.swift` resolves with `Calendar.autoupdatingCurrent`, discards an expired
today-only change, and sleeps until `nextRefresh` (plus 50 ms so it lands after the boundary).
It also refreshes on wake, clock, time-zone, calendar-day, and locale changes and after settings
edits. `DayleftPresentation` owns all displayed text. Manual checks live in
[the timer guide](../../testing/MANUAL%20TO-DO/timer.md).
