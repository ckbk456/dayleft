import Foundation

public enum ScheduleError: Error, Equatable, Sendable {
  case invalidTimeOfDay
  case offStep
  case shiftTooShort
  case noWorkdays
  case noSessions
  case tooManySessions
  case sessionsOverlap
  case overlappingDays
}

/// A wall-clock time within a local day, independent of any date or time zone.
public struct TimeOfDay: Hashable, Comparable, Codable, Sendable {
  public static let minutesPerDay = 1_440

  public let minuteOfDay: Int

  public init(minuteOfDay: Int) throws {
    guard (0..<Self.minutesPerDay).contains(minuteOfDay) else {
      throw ScheduleError.invalidTimeOfDay
    }
    self.minuteOfDay = minuteOfDay
  }

  public init(hour: Int, minute: Int) throws {
    guard (0..<24).contains(hour), (0..<60).contains(minute) else {
      throw ScheduleError.invalidTimeOfDay
    }
    try self.init(minuteOfDay: hour * 60 + minute)
  }

  /// Wraps any minute count onto the 24-hour clock.
  public init(wrappingMinutes minutes: Int) {
    let wrapped = minutes % Self.minutesPerDay
    minuteOfDay = wrapped < 0 ? wrapped + Self.minutesPerDay : wrapped
  }

  public var hour: Int { minuteOfDay / 60 }
  public var minute: Int { minuteOfDay % 60 }

  public func adding(minutes: Int) -> TimeOfDay {
    TimeOfDay(wrappingMinutes: minuteOfDay + minutes)
  }

  /// Rounds to the nearest step, wrapping 24:00 to midnight.
  public func snapped(to step: Int) -> TimeOfDay {
    let rounded = Int((Double(minuteOfDay) / Double(step)).rounded()) * step
    return TimeOfDay(wrappingMinutes: rounded)
  }

  /// Minutes moving forward from `self` to `other`, in `0..<1440`.
  public func minutes(until other: TimeOfDay) -> Int {
    TimeOfDay(wrappingMinutes: other.minuteOfDay - minuteOfDay).minuteOfDay
  }

  public static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
    lhs.minuteOfDay < rhs.minuteOfDay
  }

  public init(from decoder: Decoder) throws {
    try self.init(minuteOfDay: decoder.singleValueContainer().decode(Int.self))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(minuteOfDay)
  }
}

/// Calendar weekday numbering: 1 is Sunday, matching `Calendar.Component.weekday`.
public enum Weekday: Int, CaseIterable, Codable, Comparable, Sendable {
  case sunday = 1
  case monday
  case tuesday
  case wednesday
  case thursday
  case friday
  case saturday

  public static let workweek: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]

  public static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A local calendar date. Resolved against whatever calendar and time zone are current.
public struct LocalDay: Hashable, Comparable, Codable, Sendable {
  public let year: Int
  public let month: Int
  public let day: Int

  public init(year: Int, month: Int, day: Int) {
    self.year = year
    self.month = month
    self.day = day
  }

  public init(containing date: Date, calendar: Calendar) {
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    self.init(year: components.year ?? 0, month: components.month ?? 0, day: components.day ?? 0)
  }

  /// Local noon avoids midnights that do not exist in some time zones.
  func noon(in calendar: Calendar) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
  }

  public func startDate(in calendar: Calendar) -> Date {
    calendar.startOfDay(for: noon(in: calendar))
  }

  public func adding(days: Int, calendar: Calendar) -> LocalDay {
    let date = calendar.date(byAdding: .day, value: days, to: noon(in: calendar))!
    return LocalDay(containing: date, calendar: calendar)
  }

  public func weekday(in calendar: Calendar) -> Weekday {
    Weekday(rawValue: calendar.component(.weekday, from: noon(in: calendar)))!
  }

  public static func < (lhs: LocalDay, rhs: LocalDay) -> Bool {
    (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
  }
}

/// Daily work hours on a 24-hour clock. A cutoff at or before the start ends the next day.
public struct ShiftHours: Hashable, Codable, Sendable {
  public static let stepMinutes = 5
  public static let minimumMinutes = 15

  public let start: TimeOfDay
  public let cutoff: TimeOfDay

  public init(start: TimeOfDay, cutoff: TimeOfDay) throws {
    guard start.minuteOfDay % Self.stepMinutes == 0, cutoff.minuteOfDay % Self.stepMinutes == 0
    else {
      throw ScheduleError.offStep
    }
    guard start.minutes(until: cutoff) >= Self.minimumMinutes else {
      throw ScheduleError.shiftTooShort
    }
    self.start = start
    self.cutoff = cutoff
  }

  public var durationMinutes: Int { start.minutes(until: cutoff) }
  public var crossesMidnight: Bool { cutoff <= start }

  private enum CodingKeys: String, CodingKey {
    case start
    case cutoff
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      start: container.decode(TimeOfDay.self, forKey: .start),
      cutoff: container.decode(TimeOfDay.self, forKey: .cutoff))
  }
}
