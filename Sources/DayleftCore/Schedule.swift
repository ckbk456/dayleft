import Foundation

/// One to four work sessions in a day, sorted by start, with breaks between them.
///
/// Sessions may not overlap or touch: each ends at least `minimumBreakMinutes` before the next
/// starts. Only the last session may cross midnight, and the whole day fits in 24 hours, so a
/// day's sessions never run into the same plan's sessions the next day.
public struct WorkSessions: Hashable, Codable, Sendable {
  public static let maximumCount = 4
  public static let minimumBreakMinutes = ShiftHours.stepMinutes
  /// The default length of a session added into a gap.
  public static let addedSessionMinutes = 60

  public let all: [ShiftHours]

  public init(_ sessions: [ShiftHours]) throws {
    guard !sessions.isEmpty else { throw ScheduleError.noSessions }
    guard sessions.count <= Self.maximumCount else { throw ScheduleError.tooManySessions }
    let sorted = sessions.sorted { $0.start < $1.start }
    for (index, session) in sorted.enumerated() {
      let next = sorted[(index + 1) % sorted.count]
      // The following start, measured on a timeline beginning at this session's day.
      let nextStart =
        index + 1 < sorted.count
        ? next.start.minuteOfDay : next.start.minuteOfDay + TimeOfDay.minutesPerDay
      let end = session.start.minuteOfDay + session.durationMinutes
      guard end + Self.minimumBreakMinutes <= nextStart else {
        throw ScheduleError.sessionsOverlap
      }
    }
    all = sorted
  }

  public init(_ session: ShiftHours) {
    all = [session]
  }

  public var count: Int { all.count }
  public var first: ShiftHours { all[0] }
  public var last: ShiftHours { all[all.count - 1] }
  public var totalMinutes: Int { all.reduce(0) { $0 + $1.durationMinutes } }

  /// Replaces one session; throws when the result breaks the session rules.
  public func replacing(at index: Int, with session: ShiftHours) throws -> WorkSessions {
    var sessions = all
    sessions[index] = session
    return try WorkSessions(sessions)
  }

  /// Removes one session, or returns nil when it is the only one.
  public func removing(at index: Int) -> WorkSessions? {
    guard count > 1 else { return nil }
    var sessions = all
    sessions.remove(at: index)
    return try? WorkSessions(sessions)
  }

  /// Adds a session in the middle of the longest break, up to an hour long, keeping a
  /// minimum break on both sides. Returns nil when the day is full or has no room.
  public func addingSession() -> (sessions: WorkSessions, index: Int)? {
    guard count < Self.maximumCount else { return nil }
    let gapBreak = Self.minimumBreakMinutes
    // The longest break, measured from each session's cutoff to the next session's start.
    let breaks = all.indices.map { index in
      (index: index, minutes: all[index].cutoff.minutes(until: all[(index + 1) % count].start))
    }
    guard let widest = breaks.max(by: { $0.minutes < $1.minutes }) else { return nil }
    let room = widest.minutes - 2 * gapBreak
    guard room >= ShiftHours.minimumMinutes else { return nil }
    let length =
      min(Self.addedSessionMinutes, room) / ShiftHours.stepMinutes
      * ShiftHours.stepMinutes
    let offset = ((widest.minutes - length) / 2) / ShiftHours.stepMinutes * ShiftHours.stepMinutes
    let start = all[widest.index].cutoff.adding(minutes: offset)
    guard let session = try? ShiftHours(start: start, cutoff: start.adding(minutes: length)),
      let sessions = try? WorkSessions(all + [session]),
      let index = sessions.all.firstIndex(of: session)
    else { return nil }
    return (sessions, index)
  }

  public init(from decoder: Decoder) throws {
    try self.init(decoder.singleValueContainer().decode([ShiftHours].self))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(all)
  }
}

/// Named work sessions for a set of weekdays, e.g. "Weekdays" or "Weekend".
public struct DayPlan: Hashable, Codable, Sendable, Identifiable {
  public let id: UUID
  public var name: String
  public var days: Set<Weekday>
  public var sessions: WorkSessions

  public init(id: UUID = UUID(), name: String, days: Set<Weekday>, sessions: WorkSessions) {
    self.id = id
    self.name = name
    self.days = days
    self.sessions = sessions
  }
}

/// The regular schedule: day plans, each owning a distinct set of weekdays.
/// Weekdays in no plan are days off.
public struct Schedule: Hashable, Codable, Sendable {
  public static let maximumPlans = 7

  public static let standard = try! Schedule(plans: [
    DayPlan(
      id: UUID(uuidString: "D4E7C3A0-5B1F-4C1E-9E0A-000000000001")!, name: "Weekdays",
      days: Weekday.workweek,
      sessions: WorkSessions(
        try! ShiftHours(
          start: TimeOfDay(hour: 9, minute: 0), cutoff: TimeOfDay(hour: 18, minute: 0))))
  ])

  public let plans: [DayPlan]

  public init(plans: [DayPlan]) throws {
    guard !plans.isEmpty, plans.count <= Self.maximumPlans else { throw ScheduleError.noWorkdays }
    var seen = Set<Weekday>()
    for plan in plans {
      guard seen.isDisjoint(with: plan.days) else { throw ScheduleError.overlappingDays }
      seen.formUnion(plan.days)
    }
    guard !seen.isEmpty else { throw ScheduleError.noWorkdays }
    self.plans = plans
  }

  /// One plan with a single session on the given weekdays.
  public init(hours: ShiftHours, workdays: Set<Weekday>, name: String = "Workdays") throws {
    try self.init(plans: [DayPlan(name: name, days: workdays, sessions: WorkSessions(hours))])
  }

  /// Every weekday that has work.
  public var workdays: Set<Weekday> {
    plans.reduce(into: Set<Weekday>()) { $0.formUnion($1.days) }
  }

  public func plan(on weekday: Weekday) -> DayPlan? {
    plans.first { $0.days.contains(weekday) }
  }

  public func sessions(on weekday: Weekday) -> WorkSessions? {
    plan(on: weekday)?.sessions
  }

  /// Replaces the plan with the same id; throws when the result is invalid.
  public func updating(_ plan: DayPlan) throws -> Schedule {
    try Schedule(plans: plans.map { $0.id == plan.id ? plan : $0 })
  }

  /// Gives `weekday` to the plan with `planID`, taking it from any other plan.
  public func assigning(_ weekday: Weekday, to planID: DayPlan.ID) throws -> Schedule {
    try Schedule(
      plans: plans.map { plan in
        var plan = plan
        if plan.id == planID { plan.days.insert(weekday) } else { plan.days.remove(weekday) }
        return plan
      })
  }

  private enum CodingKeys: String, CodingKey {
    case plans
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try self.init(plans: container.decode([DayPlan].self, forKey: .plans))
  }
}

/// A change to the work that starts on `day`.
public struct DayOverride: Hashable, Codable, Sendable {
  public enum Change: Hashable, Codable, Sendable {
    case sessions(WorkSessions)
    case dayOff

    /// A single different session.
    public static func hours(_ hours: ShiftHours) -> Change {
      .sessions(WorkSessions(hours))
    }
  }

  public let day: LocalDay
  public let change: Change

  public init(day: LocalDay, change: Change) {
    self.day = day
    self.change = change
  }
}

public enum DayState: Equatable, Sendable {
  /// Today's first session has not started yet.
  case beforeStart(next: WorkWindow)
  case working(window: WorkWindow, snapshot: WorkWindow.Snapshot)
  /// Between two of today's sessions.
  case onBreak(previous: WorkWindow, next: WorkWindow)
  /// Today's work has ended; shown until local midnight or the next start, whichever is first.
  case finished(window: WorkWindow, next: WorkWindow)
  /// No work today: a day-off change or a day in no plan.
  case dayOff(next: WorkWindow)
}
