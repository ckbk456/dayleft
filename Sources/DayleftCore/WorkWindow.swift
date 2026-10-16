import Foundation

/// A resolved interval in absolute time. Schedule and time-zone resolution belong to the app.
public struct WorkWindow: Equatable, Sendable {
  public enum ValidationError: Error, Equatable {
    case invalidBounds
  }

  public enum Phase: Equatable, Sendable {
    case upcoming
    case working
    case finished
  }

  public struct Snapshot: Equatable, Sendable {
    public let phase: Phase
    /// Full work duration before the start; zero at and after the finish.
    public let remaining: TimeInterval
    /// Elapsed fraction of the work window, clamped to 0...1.
    public let elapsedFraction: Double

    /// Minute precision, rounded up so an active final minute is never shown as zero.
    public var remainingLabel: String {
      let minutes = Int(ceil(remaining / 60))
      let hours = minutes / 60
      let remainder = minutes % 60
      return hours > 0 ? "\(hours)h \(remainder)m" : "\(remainder)m"
    }
  }

  public let start: Date
  public let end: Date

  public init(start: Date, end: Date) throws {
    guard start.timeIntervalSinceReferenceDate.isFinite,
      end.timeIntervalSinceReferenceDate.isFinite,
      end > start,
      end.timeIntervalSince(start).isFinite
    else {
      throw ValidationError.invalidBounds
    }
    self.start = start
    self.end = end
  }

  /// Recompute from the supplied clock; never decrement a stored countdown.
  public func snapshot(at now: Date) -> Snapshot {
    let duration = end.timeIntervalSince(start)
    if now < start {
      return Snapshot(phase: .upcoming, remaining: duration, elapsedFraction: 0)
    }
    if now >= end {
      return Snapshot(phase: .finished, remaining: 0, elapsedFraction: 1)
    }
    return Snapshot(
      phase: .working,
      remaining: end.timeIntervalSince(now),
      elapsedFraction: now.timeIntervalSince(start) / duration
    )
  }
}
