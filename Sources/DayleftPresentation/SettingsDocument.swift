import DayleftCore
import Foundation

/// The persisted settings. Login launch is not stored; the system owns that state.
/// Stored as JSON under `storageKey`; bump the key's version for any incompatible change and
/// migrate the previous key in `decode`.
public struct SettingsDocument: Equatable, Codable, Sendable {
  public static let storageKey = "settings.v2"
  /// Single-hours settings from versions before work sessions; read once to migrate.
  public static let legacyStorageKey = "settings.v1"

  public var schedule: Schedule
  public var override: DayOverride?

  public init(schedule: Schedule = .standard, override: DayOverride? = nil) {
    self.schedule = schedule
    self.override = override
  }

  /// Missing or unreadable data falls back to the migrated legacy settings, then to defaults,
  /// rather than failing launch.
  public static func decode(_ data: Data?, legacy: Data? = nil) -> SettingsDocument {
    if let data, let document = try? JSONDecoder().decode(Self.self, from: data) {
      return document
    }
    if let legacy, let document = try? JSONDecoder().decode(LegacyDocument.self, from: legacy) {
      return document.migrated
    }
    return SettingsDocument()
  }

  public func encoded() -> Data {
    // Every stored value is plain Codable data, so encoding cannot fail.
    try! JSONEncoder().encode(self)
  }
}

/// The `settings.v1` format: one set of hours for every workday.
private struct LegacyDocument: Decodable {
  struct LegacySchedule: Decodable {
    let hours: ShiftHours
    let workdays: Set<Weekday>
  }

  struct LegacyOverride: Decodable {
    enum Change: Decodable {
      case hours(ShiftHours)
      case dayOff
    }

    let day: LocalDay
    let change: Change
  }

  let schedule: LegacySchedule
  let override: LegacyOverride?

  var migrated: SettingsDocument {
    let schedule =
      (try? Schedule(
        plans: [
          DayPlan(
            name: "Workdays", days: self.schedule.workdays,
            sessions: WorkSessions(self.schedule.hours))
        ])) ?? .standard
    let override = self.override.map { old in
      switch old.change {
      case .hours(let hours): DayOverride(day: old.day, change: .hours(hours))
      case .dayOff: DayOverride(day: old.day, change: .dayOff)
      }
    }
    return SettingsDocument(schedule: schedule, override: override)
  }
}
