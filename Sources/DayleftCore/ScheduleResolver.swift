import Foundation

/// Resolves recurring sessions into absolute work windows using a calendar and its time zone.
///
/// Wall-clock times that do not exist (a daylight-saving gap) move to the next valid time;
/// repeated times use their first occurrence. A session belongs to the day it starts.
public struct ScheduleResolver: Sendable {
  /// Every weekday recurs twice within this span, so a schedule always finds a next start even
  /// when one day is overridden and another is unrepresentable.
  static let searchDays = 15

  public let calendar: Calendar

  public init(calendar: Calendar) {
    self.calendar = calendar
  }

  /// The sessions planned for `day`: its today-only change, otherwise its day plan.
  public func sessions(on day: LocalDay, schedule: Schedule, override: DayOverride?)
    -> WorkSessions?
  {
    if let override, override.day == day {
      switch override.change {
      case .dayOff: return nil
      case .sessions(let sessions): return sessions
      }
    }
    return schedule.sessions(on: day.weekday(in: calendar))
  }

  /// The windows for the sessions starting on `day`, in order; empty when that day has no work.
  public func windows(on day: LocalDay, schedule: Schedule, override: DayOverride?)
    -> [WorkWindow]
  {
    guard let sessions = sessions(on: day, schedule: schedule, override: override) else {
      return []
    }
    return sessions.all.compactMap { window(for: $0, on: day) }
  }

  public func state(at now: Date, schedule: Schedule, override: DayOverride?) -> DayState {
    let today = LocalDay(containing: now, calendar: calendar)
    let todays = windows(on: today, schedule: schedule, override: override)
    let recent =
      windows(
        on: today.adding(days: -1, calendar: calendar), schedule: schedule, override: override)
      + todays
    // Yesterday's overnight session comes first, so it wins over today's overlapping one.
    if let active = recent.first(where: { $0.start <= now && now < $0.end }) {
      return .working(window: active, snapshot: active.snapshot(at: now))
    }
    let next = nextWindow(after: now, from: today, schedule: schedule, override: override)
    let nextIsToday = todays.contains(next)
    if nextIsToday, let previous = todays.filter({ $0.end <= now }).max(by: { $0.end < $1.end }) {
      return .onBreak(previous: previous, next: next)
    }
    let endedToday = recent.filter { $0.end <= now && endingDay(of: $0) == today }
    if let ended = endedToday.max(by: { $0.end < $1.end }) {
      return .finished(window: ended, next: next)
    }
    return nextIsToday ? .beforeStart(next: next) : .dayOff(next: next)
  }

  /// The windows of the work day a state belongs to, in order, for drawing the day's progress.
  /// Empty on a day off.
  public func timeline(for state: DayState, schedule: Schedule, override: DayOverride?)
    -> [WorkWindow]
  {
    let anchor: WorkWindow
    switch state {
    case .working(let window, _), .finished(let window, _), .onBreak(let window, _):
      anchor = window
    case .beforeStart(let next):
      anchor = next
    case .dayOff:
      return []
    }
    let day = LocalDay(containing: anchor.start, calendar: calendar)
    let windows = windows(on: day, schedule: schedule, override: override)
    return windows.contains(anchor) ? windows : [anchor]
  }

  /// Work still ahead in `timeline` at `now`, in seconds.
  public func remainingWork(in timeline: [WorkWindow], at now: Date) -> TimeInterval {
    timeline.reduce(0) { $0 + $1.snapshot(at: now).remaining }
  }

  /// The next instant at which `state` or its displayed whole minutes can change.
  public func nextRefresh(after now: Date, schedule: Schedule, override: DayOverride?) -> Date {
    let today = LocalDay(containing: now, calendar: calendar)
    var candidates = [today.adding(days: 1, calendar: calendar).startDate(in: calendar)]
    switch state(at: now, schedule: schedule, override: override) {
    case .working(let window, _):
      candidates.append(contentsOf: minuteTicks(toward: window.end, from: now))
    case .onBreak(_, let next):
      // The panel counts down to the end of the break.
      candidates.append(contentsOf: minuteTicks(toward: next.start, from: now))
    case .beforeStart(let next), .finished(_, let next), .dayOff(let next):
      candidates.append(next.start)
    }
    return candidates.filter { $0 > now }.min() ?? now.addingTimeInterval(60)
  }

  /// Whether the override can no longer affect any state and can be discarded.
  ///
  /// `state` only considers yesterday's and today's sessions, so an override stops mattering
  /// when the second day after it begins. Dropping it at its last session's end would revive the
  /// regular sessions for a day that was shortened to end early.
  public func isExpired(_ override: DayOverride, at now: Date) -> Bool {
    now >= override.day.adding(days: 2, calendar: calendar).startDate(in: calendar)
  }

  /// The next change in rounded-up whole minutes before `end`, and `end` itself.
  private func minuteTicks(toward end: Date, from now: Date) -> [Date] {
    let minutes = (end.timeIntervalSince(now) / 60).rounded(.up)
    guard minutes.isFinite else { return [end] }
    return [end.addingTimeInterval(-max(minutes - 1, 0) * 60), end]
  }

  private func window(for session: ShiftHours, on day: LocalDay) -> WorkWindow? {
    let cutoffDay = session.crossesMidnight ? day.adding(days: 1, calendar: calendar) : day
    // A session squeezed to nothing by a daylight-saving gap has no window that day.
    return try? WorkWindow(
      start: date(session.start, on: day), end: date(session.cutoff, on: cutoffDay))
  }

  private func nextWindow(
    after now: Date, from today: LocalDay, schedule: Schedule, override: DayOverride?
  ) -> WorkWindow {
    for offset in 0..<Self.searchDays {
      let day = today.adding(days: offset, calendar: calendar)
      if let window = windows(on: day, schedule: schedule, override: override).first(where: {
        $0.start > now
      }) {
        return window
      }
    }
    preconditionFailure("A schedule with a workday always starts within \(Self.searchDays) days")
  }

  /// A session ending exactly at midnight ends on the earlier day, so its Done state expires then.
  private func endingDay(of window: WorkWindow) -> LocalDay {
    LocalDay(containing: window.end.addingTimeInterval(-1), calendar: calendar)
  }

  private func date(_ time: TimeOfDay, on day: LocalDay) -> Date {
    calendar.date(
      bySettingHour: time.hour, minute: time.minute, second: 0, of: day.startDate(in: calendar),
      matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward)!
  }
}
