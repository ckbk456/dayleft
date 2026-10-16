import Foundation

/// Resolves recurring hours into absolute work windows using a calendar and its time zone.
///
/// Wall-clock times that do not exist (a daylight-saving gap) move to the next valid time;
/// repeated times use their first occurrence. A shift belongs to the day it starts.
public struct ScheduleResolver: Sendable {
  /// Every weekday recurs twice within this span, so a schedule always finds a next start even
  /// when one day is overridden and another is unrepresentable.
  static let searchDays = 15

  public let calendar: Calendar

  public init(calendar: Calendar) {
    self.calendar = calendar
  }

  /// The window for the shift starting on `day`, or `nil` when that day has no shift.
  public func window(on day: LocalDay, schedule: Schedule, override: DayOverride?) -> WorkWindow? {
    let hours: ShiftHours
    if let override, override.day == day {
      switch override.change {
      case .dayOff: return nil
      case .hours(let custom): hours = custom
      }
    } else if schedule.workdays.contains(day.weekday(in: calendar)) {
      hours = schedule.hours
    } else {
      return nil
    }
    let cutoffDay = hours.crossesMidnight ? day.adding(days: 1, calendar: calendar) : day
    // A shift squeezed to nothing by a daylight-saving gap has no window that day.
    return try? WorkWindow(
      start: date(hours.start, on: day), end: date(hours.cutoff, on: cutoffDay))
  }

  public func state(at now: Date, schedule: Schedule, override: DayOverride?) -> DayState {
    let today = LocalDay(containing: now, calendar: calendar)
    let recent = [today.adding(days: -1, calendar: calendar), today].compactMap {
      window(on: $0, schedule: schedule, override: override)
    }
    if let active = recent.first(where: { $0.start <= now && now < $0.end }) {
      return .working(window: active, snapshot: active.snapshot(at: now))
    }
    let next = nextWindow(after: now, from: today, schedule: schedule, override: override)
    let endedToday = recent.filter { $0.end <= now && endingDay(of: $0) == today }
    if let ended = endedToday.max(by: { $0.end < $1.end }) {
      return .finished(window: ended, next: next)
    }
    if LocalDay(containing: next.start, calendar: calendar) == today,
      window(on: today, schedule: schedule, override: override) == next
    {
      return .beforeStart(next: next)
    }
    return .dayOff(next: next)
  }

  /// The next instant at which `state` or its displayed whole minutes can change.
  public func nextRefresh(after now: Date, schedule: Schedule, override: DayOverride?) -> Date {
    let today = LocalDay(containing: now, calendar: calendar)
    var candidates = [today.adding(days: 1, calendar: calendar).startDate(in: calendar)]
    switch state(at: now, schedule: schedule, override: override) {
    case .working(let window, let snapshot):
      let minutesAfterTick = Double(max(snapshot.remainingWholeMinutes - 1, 0))
      candidates.append(window.end.addingTimeInterval(-minutesAfterTick * 60))
      candidates.append(window.end)
    case .beforeStart(let next), .finished(_, let next), .dayOff(let next):
      candidates.append(next.start)
    }
    return candidates.filter { $0 > now }.min() ?? now.addingTimeInterval(60)
  }

  /// Whether the override's shift (or day off) is over and it can be discarded.
  public func isExpired(_ override: DayOverride, at now: Date) -> Bool {
    let nextMidnight = override.day.adding(days: 1, calendar: calendar).startDate(in: calendar)
    // The override decides its own day, so the recurring schedule passed here is irrelevant.
    guard case .hours = override.change,
      let window = window(on: override.day, schedule: .standard, override: override)
    else {
      return now >= nextMidnight
    }
    return now >= window.end
  }

  private func nextWindow(
    after now: Date, from today: LocalDay, schedule: Schedule, override: DayOverride?
  ) -> WorkWindow {
    for offset in 0..<Self.searchDays {
      let day = today.adding(days: offset, calendar: calendar)
      if let window = window(on: day, schedule: schedule, override: override), window.start > now {
        return window
      }
    }
    preconditionFailure("A schedule with a workday always starts within \(Self.searchDays) days")
  }

  /// A shift ending exactly at midnight ends on the earlier day, so its Done state expires then.
  private func endingDay(of window: WorkWindow) -> LocalDay {
    LocalDay(containing: window.end.addingTimeInterval(-1), calendar: calendar)
  }

  private func date(_ time: TimeOfDay, on day: LocalDay) -> Date {
    calendar.date(
      bySettingHour: time.hour, minute: time.minute, second: 0, of: day.startDate(in: calendar),
      matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward)!
  }
}
