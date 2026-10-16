# Implemented timing contract

Owner: `Sources/DayleftCore/WorkWindow.swift`; tests: `Tests/DayleftCoreTests/WorkWindowTests.swift`.

`WorkWindow` accepts finite, strictly ordered absolute `Date` bounds. It does not resolve a
recurring schedule, store preferences, choose a timezone, or read the system clock. Callers
supply the current instant to `snapshot(at:)` on every refresh. Real application clocks are
expected to supply a finite instant.

| Clock position | Phase | Remaining work budget | Elapsed fraction |
|---|---|---|---|
| Before start | upcoming | Full interval duration | 0 |
| At start through before end | working | End minus now | (now minus start) / duration |
| At or after end | finished | 0 | 1 |

`remainingLabel` rounds up to whole minutes. This preserves `1m` during a final partial minute.
The bar represents **elapsed** work-window time; do not label it remaining. The approved
09:00–18:00 example at 14:36 has 3h 24m remaining and about 62.22% elapsed.

Once dates are resolved, crossing midnight and daylight-saving changes work through absolute
elapsed time. This is not proof that recurring-schedule resolution or lifecycle refresh exists.
Those belong to the next milestone. Current tests cover invalid bounds, start/end boundaries,
the approved example, skipped clock ticks, rounding, an overnight absolute interval, and a
spring daylight-saving interval.

The SwiftUI app uses fixed sample instants and a fixed menu bar label. It is a scaffold preview,
not a running countdown. UI inspection remains [human-owned](../../testing/MANUAL%20TO-DO/timer.md).
