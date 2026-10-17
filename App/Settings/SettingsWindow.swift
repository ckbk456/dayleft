import SwiftUI

/// The settings window: a tab bar of panes across the top, above the selected pane's controls.
struct SettingsWindow: View {
  let model: TimerModel
  let loginItem: LoginItem
  @Bindable var navigation: SettingsNavigation

  var body: some View {
    TabView(selection: $navigation.pane) {
      ForEach(SettingsPane.allCases) { pane in
        detail(pane)
          .tabItem { Label(pane.title, systemImage: pane.systemImage) }
          .tag(pane)
      }
    }
    .tint(.orange)
    .navigationTitle(navigation.pane.title)
    .frame(width: 680, height: 680)
  }

  @ViewBuilder private func detail(_ pane: SettingsPane) -> some View {
    switch pane {
    case .today: TodayPane(model: model, navigation: navigation)
    case .schedule: SchedulePane(model: model)
    case .general: GeneralPane(loginItem: loginItem)
    case .about: AboutPane()
    }
  }
}
