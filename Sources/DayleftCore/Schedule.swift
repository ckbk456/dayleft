import Foundation

/// Recurring work hours shared by every selected weekday.
public struct Schedule: Hashable, Codable, Sendable {
  public static let standard = try! Schedule(
    hours: ShiftHours(
      start: TimeOfDay(hour: 9, minute: 0), cutoff: TimeOfDay(hour: 18, minute: 0)),
    workdays: Weekday.workweek)

  public let hours: ShiftHours
  public let workdays: Set<Weekday>

  public init(hours: ShiftHours, workdays: Set<Weekday>) throws {
    guard !workdays.isEmpty else { throw ScheduleError.noWorkdays }
    self.hours = hours
    self.workdays = workdays
  }

  private enum CodingKeys: String, CodingKey {
    case hours
    case workdays
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(
      hours: container.decode(ShiftHours.self, forKey: .hours),
      workdays: container.decode(Set<Weekday>.self, forKey: .workdays))
  }
}

/// A change to the single shift that starts on `day`.
public struct DayOverride: Hashable, Codable, Sendable {
  public enum Change: Hashable, Codable, Sendable {
    case hours(ShiftHours)
    case dayOff
  }

  public let day: LocalDay
  public let change: Change

  public init(day: LocalDay, change: Change) {
    self.day = day
    self.change = change
  }
}

public enum DayState: Equatable, Sendable {
  /// Today's shift has not started yet.
  case beforeStart(next: WorkWindow)
  case working(window: WorkWindow, snapshot: WorkWindow.Snapshot)
  /// A shift ended today; shown until local midnight or the next start, whichever is first.
  case finished(window: WorkWindow, next: WorkWindow)
  /// No shift today: a day-off override or a non-workday.
  case dayOff(next: WorkWindow)
}
