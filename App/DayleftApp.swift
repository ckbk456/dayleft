import SwiftUI

@main
struct DayleftApp: App {
  @State private var model: TimerModel
  @State private var settingsWindow: SettingsWindowController

  init() {
    let model = TimerModel(settings: SettingsStore())
    _model = State(initialValue: model)
    _settingsWindow = State(
      initialValue: SettingsWindowController(model: model, loginItem: LoginItem()))
  }

  var body: some Scene {
    MenuBarExtra {
      PanelView(model: model, openSettings: settingsWindow.show)
    } label: {
      // Interpolating the image into one Text keeps both icon and time in the status item.
      Text("\(Image(systemName: "hourglass")) \(model.presentation.menuBarText)")
        .monospacedDigit()
        .accessibilityLabel(model.presentation.accessibilityLabel)
    }
    .menuBarExtraStyle(.window)
    .commands {
      // Shown in the app menu while the settings window makes Dayleft a regular app.
      CommandGroup(replacing: .appSettings) {
        Button("Settings…") { settingsWindow.show() }
          .keyboardShortcut(",")
      }
    }
  }
}
