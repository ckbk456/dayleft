import AppKit
import Observation
import SwiftUI

/// Pages of the settings window, in sidebar order.
enum SettingsPane: String, CaseIterable, Identifiable {
  case today
  case schedule
  case general
  case about

  var id: Self { self }

  var title: String {
    switch self {
    case .today: "Today"
    case .schedule: "Work Hours"
    case .general: "General"
    case .about: "About"
    }
  }

  var systemImage: String {
    switch self {
    case .today: "calendar.badge.clock"
    case .schedule: "clock"
    case .general: "gearshape"
    case .about: "info.circle"
    }
  }
}

/// Which pane is showing, and a counter that lets panes discard unapplied drafts on reopen.
@Observable
@MainActor
final class SettingsNavigation {
  var pane: SettingsPane = .today
  private(set) var openCount = 0

  func opened() { openCount += 1 }
}

/// Owns Dayleft's single settings window, kept separate from the menu bar panel.
///
/// The app is a menu-bar-only accessory; while this window is open it becomes a regular app
/// (Dock icon, app switcher, main menu) and returns to an accessory when the window closes.
/// AppKit owns the window so it never opens or restores itself at launch.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
  private let model: TimerModel
  private let loginItem: LoginItem
  private let navigation = SettingsNavigation()
  private var window: NSWindow?

  init(model: TimerModel, loginItem: LoginItem) {
    self.model = model
    self.loginItem = loginItem
  }

  /// Brings the window to the front, optionally on a specific pane.
  func show(_ pane: SettingsPane? = nil) {
    if let pane { navigation.pane = pane }
    let window = self.window ?? makeWindow()
    self.window = window
    if !window.isVisible {
      navigation.opened()
      loginItem.refresh()
    }
    NSApplication.shared.setActivationPolicy(.regular)
    window.makeKeyAndOrderFront(nil)
    NSApplication.shared.activate()
  }

  func windowWillClose(_ notification: Notification) {
    NSApplication.shared.setActivationPolicy(.accessory)
  }

  private func makeWindow() -> NSWindow {
    let hosting = NSHostingController(
      rootView: SettingsWindow(model: model, loginItem: loginItem, navigation: navigation))
    hosting.sizingOptions = .preferredContentSize
    hosting.sceneBridgingOptions = [.title, .toolbars]
    let window = SettingsNSWindow(contentViewController: hosting)
    window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
    window.toolbar = NSToolbar(identifier: "DayleftSettings")
    window.toolbarStyle = .unified
    window.isReleasedWhenClosed = false
    window.delegate = self
    window.center()
    window.setFrameAutosaveName("DayleftSettings")
    return window
  }
}

/// Handles ⌘W itself, since an accessory app has no File menu to route it.
private final class SettingsNSWindow: NSWindow {
  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
      event.charactersIgnoringModifiers == "w"
    {
      performClose(nil)
      return true
    }
    return super.performKeyEquivalent(with: event)
  }
}
