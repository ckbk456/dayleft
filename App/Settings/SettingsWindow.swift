import SwiftUI

/// The settings window: a sidebar of panes beside the selected pane's controls.
struct SettingsWindow: View {
  let model: TimerModel
  let loginItem: LoginItem
  @Bindable var navigation: SettingsNavigation

  /// Each sidebar label's natural width, which follows the system's sidebar and text size.
  @State private var labelWidths: [SettingsPane: CGFloat] = [:]

  var body: some View {
    NavigationSplitView(columnVisibility: .constant(.all)) {
      List(SettingsPane.allCases, selection: paneBinding) { pane in
        Label(pane.title, systemImage: pane.systemImage)
          .fixedSize(horizontal: true, vertical: false)
          .onGeometryChange(for: CGFloat.self) {
            $0.size.width
          } action: { width in
            labelWidths[pane] = width
          }
      }
      .navigationSplitViewColumnWidth(min: sidebarWidth, ideal: sidebarWidth, max: sidebarWidth)
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

  /// The sidebar is locked: it cannot be dragged or collapsed, and it is just wide enough for the
  /// longest label plus the selection pill's insets, so larger text widens it instead of truncating.
  private var sidebarWidth: CGFloat {
    max(170, ((labelWidths.values.max() ?? 0) + 44).rounded(.up))
  }

  /// `List` selects optionals; the window always has a pane selected.
  private var paneBinding: Binding<SettingsPane?> {
    Binding(get: { navigation.pane }, set: { if let pane = $0 { navigation.pane = pane } })
  }
}
