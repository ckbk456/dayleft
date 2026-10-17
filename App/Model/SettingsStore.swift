import DayleftCore
import DayleftPresentation
import Foundation
import Observation

/// Owns persisted work-hour settings in the app's local defaults.
@Observable
@MainActor
final class SettingsStore {
  private(set) var document: SettingsDocument
  @ObservationIgnored private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    document = SettingsDocument.decode(
      defaults.data(forKey: SettingsDocument.storageKey),
      legacy: defaults.data(forKey: SettingsDocument.legacyStorageKey))
    // Persist migrated or default settings once, so plan identities stay stable across launches.
    if defaults.data(forKey: SettingsDocument.storageKey) == nil { save() }
  }

  var schedule: Schedule { document.schedule }
  var override: DayOverride? { document.override }

  func setSchedule(_ schedule: Schedule) {
    document.schedule = schedule
    save()
  }

  func setOverride(_ override: DayOverride?) {
    document.override = override
    save()
  }

  private func save() {
    defaults.set(document.encoded(), forKey: SettingsDocument.storageKey)
  }
}
