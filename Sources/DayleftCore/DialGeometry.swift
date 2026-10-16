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

  private static func normalized(_ degrees: Double) -> Double {
    let value = degrees.truncatingRemainder(dividingBy: 360)
    return value < 0 ? value + 360 : value
  }

  private static func circularDistance(_ a: Double, _ b: Double) -> Double {
    let difference = abs(normalized(a) - normalized(b))
    return min(difference, 360 - difference)
  }
}
