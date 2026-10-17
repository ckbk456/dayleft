import Foundation

/// Geometry for a 24-hour dial: midnight at the top, time running clockwise.
public enum DialGeometry {
  public enum Handle: Sendable {
    case start
    case cutoff
  }

  /// Degrees clockwise from the top for a time of day.
  public static func angle(for time: TimeOfDay) -> Double {
    Double(time.minuteOfDay) / Double(TimeOfDay.minutesPerDay) * 360
  }

  /// Degrees clockwise from the top for an offset from the dial centre, with y pointing down.
  public static func angle(dx: Double, dy: Double) -> Double {
    normalized(atan2(dx, -dy) * 180 / .pi)
  }

  /// The time at an angle, snapped to the shift step.
  public static func time(atAngle degrees: Double) -> TimeOfDay {
    let minutes = normalized(degrees) / 360 * Double(TimeOfDay.minutesPerDay)
    return TimeOfDay(wrappingMinutes: Int(minutes.rounded())).snapped(to: ShiftHours.stepMinutes)
  }

  /// Start angle and clockwise sweep of the work arc, in degrees.
  public static func arc(for hours: ShiftHours) -> (start: Double, sweep: Double) {
    (angle(for: hours.start), Double(hours.durationMinutes) / Double(TimeOfDay.minutesPerDay) * 360)
  }

  /// The handle closest to an angle; a tie selects the start.
  public static func nearestHandle(to degrees: Double, hours: ShiftHours) -> Handle {
    let toStart = circularDistance(degrees, angle(for: hours.start))
    let toCutoff = circularDistance(degrees, angle(for: hours.cutoff))
    return toCutoff < toStart ? .cutoff : .start
  }

  /// Moves one handle, keeping it at least the minimum shift length from the other handle.
  /// A handle that would land too close stops on the side it came from, so it never jumps
  /// across the other handle.
  public static func moving(_ handle: Handle, of hours: ShiftHours, to time: TimeOfDay)
    -> ShiftHours
  {
    let target = time.snapped(to: ShiftHours.stepMinutes)
    let (current, other) =
      handle == .start ? (hours.start, hours.cutoff) : (hours.cutoff, hours.start)
    let gap = ShiftHours.minimumMinutes
    var placed = target
    if min(target.minutes(until: other), other.minutes(until: target)) < gap {
      // Previously before the other handle (going clockwise) means stop just before it.
      let wasBefore = current.minutes(until: other) <= other.minutes(until: current)
      placed = wasBefore ? other.adding(minutes: -gap) : other.adding(minutes: gap)
    }
    let result =
      handle == .start
      ? try? ShiftHours(start: placed, cutoff: hours.cutoff)
      : try? ShiftHours(start: hours.start, cutoff: placed)
    return result ?? hours
  }

  /// The handle closest to an angle among all sessions; ties prefer the earlier session's start.
  public static func nearestHandle(to degrees: Double, in sessions: WorkSessions)
    -> (index: Int, handle: Handle)
  {
    var best = (index: 0, handle: Handle.start, distance: Double.infinity)
    for (index, session) in sessions.all.enumerated() {
      for handle in [Handle.start, .cutoff] {
        let time = handle == .start ? session.start : session.cutoff
        let distance = circularDistance(degrees, angle(for: time))
        if distance < best.distance { best = (index, handle, distance) }
      }
    }
    return (best.index, best.handle)
  }

  /// Moves one handle of a session, keeping that session at least the minimum length and a
  /// minimum break from its neighbours. A target outside that range stops at its nearer end, so
  /// a handle never jumps across another session. Returns the sessions and the moved session's
  /// new index, which changes only when a start moves across midnight.
  public static func moving(
    _ handle: Handle, ofSession index: Int, in sessions: WorkSessions, to time: TimeOfDay
  ) -> (sessions: WorkSessions, index: Int) {
    let session = sessions.all[index]
    guard sessions.count > 1 else {
      return (WorkSessions(moving(handle, of: session, to: time)), 0)
    }
    let count = sessions.count
    let previous = sessions.all[(index - 1 + count) % count]
    let next = sessions.all[(index + 1) % count]
    let gap = WorkSessions.minimumBreakMinutes
    let minimum = ShiftHours.minimumMinutes
    // The handle's allowed range, running clockwise from `low` to `high`.
    let (low, high) =
      handle == .start
      ? (previous.cutoff.adding(minutes: gap), session.cutoff.adding(minutes: -minimum))
      : (session.start.adding(minutes: minimum), next.start.adding(minutes: -gap))
    let target = time.snapped(to: ShiftHours.stepMinutes)
    let span = low.minutes(until: high)
    let offset = low.minutes(until: target)
    let placed =
      offset <= span
      ? target : (offset - span <= TimeOfDay.minutesPerDay - offset ? high : low)
    let moved =
      handle == .start
      ? try? ShiftHours(start: placed, cutoff: session.cutoff)
      : try? ShiftHours(start: session.start, cutoff: placed)
    guard let moved, let result = try? sessions.replacing(at: index, with: moved),
      let newIndex = result.all.firstIndex(of: moved)
    else { return (sessions, index) }
    return (result, newIndex)
  }

  /// The session whose arc contains an angle, if any.
  public static func session(at degrees: Double, in sessions: WorkSessions) -> Int? {
    let time = TimeOfDay(
      wrappingMinutes: Int((normalized(degrees) / 360 * Double(TimeOfDay.minutesPerDay)).rounded()))
    return sessions.all.firstIndex { $0.start.minutes(until: time) < $0.durationMinutes }
  }

  /// What a click on the dial lands on.
  public enum Target: Equatable, Sendable {
    /// A session's start or cutoff handle.
    case handle(index: Int, Handle)
    /// A session's arc, away from its handles.
    case session(Int)
  }

  /// The handle or arc under a point, given as an offset from the dial centre with y pointing
  /// down. A handle counts within `handleReach` points of its centre on the ring, preferring the
  /// selected session's handles; an arc counts within `ringReach` points of the ring. Anywhere
  /// else, including the middle of the dial and gaps between sessions, is no target.
  public static func target(
    dx: Double, dy: Double, radius: Double, ringReach: Double, handleReach: Double,
    in sessions: WorkSessions, selected: Int
  ) -> Target? {
    let count = sessions.count
    let order = (0..<count).map { (selected + $0) % count }
    var best: (target: Target, distance: Double)?
    for index in order {
      for handle in [Handle.start, .cutoff] {
        let session = sessions.all[index]
        let radians = angle(for: handle == .start ? session.start : session.cutoff) * .pi / 180
        let distance = hypot(dx - radius * sin(radians), dy + radius * cos(radians))
        guard distance <= handleReach else { continue }
        if index == selected { return .handle(index: index, handle) }
        if distance < best?.distance ?? .infinity {
          best = (.handle(index: index, handle), distance)
        }
      }
    }
    if let best { return best.target }
    guard abs(hypot(dx, dy) - radius) <= ringReach,
      let index = session(at: angle(dx: dx, dy: dy), in: sessions)
    else { return nil }
    return .session(index)
  }

  private static func normalized(_ degrees: Double) -> Double {
    let value = degrees.truncatingRemainder(dividingBy: 360)
    return value < 0 ? value + 360 : value
  }

  private static func circularDistance(_ a: Double, _ b: Double) -> Double {
    let difference = abs(normalized(a) - normalized(b))
    return min(difference, 360 - difference)
  }
}
