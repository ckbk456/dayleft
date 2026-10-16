import SwiftUI

@main
struct DayleftApp: App {
  var body: some Scene {
    MenuBarExtra {
      TimerPreviewView()
        .preferredColorScheme(.dark)
    } label: {
      Label("3h 24m", systemImage: "hourglass")
        .monospacedDigit()
        .accessibilityLabel("Dayleft preview, 3 hours 24 minutes remaining")
    }
    .menuBarExtraStyle(.window)
  }
}
