import Observation
import ServiceManagement

/// Opt-in launch at login. The system's registration status is the source of truth.
@Observable
@MainActor
final class LoginItem {
  enum Status: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case unavailable
  }

  private(set) var status: Status = .disabled
  private(set) var lastError: String?

  init() {
    refresh()
  }

  var isEnabled: Bool { status == .enabled || status == .requiresApproval }

  func refresh() {
    switch SMAppService.mainApp.status {
    case .enabled: status = .enabled
    case .requiresApproval: status = .requiresApproval
    case .notRegistered: status = .disabled
    case .notFound: status = .unavailable
    @unknown default: status = .unavailable
    }
  }

  func setEnabled(_ enabled: Bool) {
    do {
      if enabled {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
      lastError = nil
    } catch {
      lastError = error.localizedDescription
    }
    refresh()
  }

  /// Opens System Settings so the person can approve the login item.
  func openSystemSettings() {
    SMAppService.openSystemSettingsLoginItems()
  }
}
