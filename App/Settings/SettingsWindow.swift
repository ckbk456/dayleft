import SwiftUI

/// The settings window: a sidebar of panes beside the selected pane's controls.
struct SettingsWindow: View {
  let model: TimerModel
  let loginItem: LoginItem
  @Bindable var navigation: SettingsNavigation

  var body: some View {
    NavigationSplitView {
      List(SettingsPane.allCases, selection: paneBinding) { pane in
        Label(pane.title, systemImage: pane.systemImage)
      }
      .navigationSplitViewColumnWidth(170)
      .toolbar(removing: .sidebarToggle)
    } detail: {
      detail
        .navigationTitle(navigation.pane.title)
    }
    .frame(width: 680, height: 680)
  }

  @ViewBuilder private var detail: some View {
    switch navigation.pane {
    case .today: TodayPane(model: model, navigation: navigation)
    case .schedule: SchedulePane(model: model)
    case .general: GeneralPane(loginItem: loginItem)
    case .about: AboutPane()
    }
  }

  /// `List` selects optionals; the window always has a pane selected.
  private var paneBinding: Binding<SettingsPane?> {
    Binding(get: { navigation.pane }, set: { if let pane = $0 { navigation.pane = pane } })
  }
}
