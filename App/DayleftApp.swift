import SwiftUI

@main
struct DayleftApp: App {
  @State private var model = TimerModel(settings: SettingsStore())
  @State private var loginItem = LoginItem()

  var body: some Scene {
    MenuBarExtra {
      PanelView(model: model)
    } label: {
      // Interpolating the image into one Text keeps both icon and time in the status item.
      Text("\(Image(systemName: "hourglass")) \(model.presentation.menuBarText)")
        .monospacedDigit()
        .accessibilityLabel(model.presentation.accessibilityLabel)
    }
    .menuBarExtraStyle(.window)

    Settings {
      SettingsView(model: model, loginItem: loginItem)
    }
  }
}
