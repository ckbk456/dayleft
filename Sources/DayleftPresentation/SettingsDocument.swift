import DayleftCore
import Foundation

/// The persisted settings. Login launch is not stored; the system owns that state.
/// Stored as JSON under `storageKey`; bump the key's version for any
/// incompatible change.
public struct SettingsDocument: Equatable, Codable, Sendable {
  public static let storageKey = "settings.v1"

  public var schedule: Schedule
  public var override: DayOverride?

  public init(schedule: Schedule = .standard, override: DayOverride? = nil) {
    self.schedule = schedule
    self.override = override
  }

  /// Missing or unreadable data falls back to defaults rather than failing launch.
  public static func decode(_ data: Data?) -> SettingsDocument {
    guard let data, let document = try? JSONDecoder().decode(Self.self, from: data) else {
      return SettingsDocument()
    }
    return document
  }

  public func encoded() -> Data {
    // Every stored value is plain Codable data, so encoding cannot fail.
    try! JSONEncoder().encode(self)
  }
}
