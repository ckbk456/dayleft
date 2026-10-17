import DayleftCore
import DayleftPresentation
import SwiftUI

/// Changes only today's work (or the work running now); the regular schedule is never edited here.
/// Edits are a draft until Apply, since a change can end the running work immediately.
struct TodayPane: View {
  let model: TimerModel
  let navigation: SettingsNavigation

  private enum Choice: Hashable {
    case regular
    case different
    case dayOff
  }

  @State private var choice: Choice = .regular
  @State private var sessions: WorkSessions

  init(model: TimerModel, navigation: SettingsNavigation) {
    self.model = model
    self.navigation = navigation
    _sessions = State(initialValue: Self.regularOrDefault(model))
  }

  private var formatter: DayleftFormatter {
    DayleftFormatter(calendar: .autoupdatingCurrent, locale: .autoupdatingCurrent)
  }

  var body: some View {
    VStack(spacing: 0) {
      Form {
        Section {
          LabeledContent("Now") {
            VStack(alignment: .trailing, spacing: 2) {
              Text(model.presentation.headline)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
              Text(model.presentation.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
              if let note = model.presentation.dayNote {
                Text(note)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }
        }

        Section {
          Picker("Today's work", selection: $choice) {
            Text("Regular schedule").tag(Choice.regular)
            Text("Different hours").tag(Choice.different)
            Text("Day off").tag(Choice.dayOff)
          }
          .pickerStyle(.segmented)

          switch choice {
          case .regular:
            Text(regularText)
              .foregroundStyle(.secondary)
          case .different:
            Label(
              "These sessions are for today only. Your regular schedule stays as it is.",
              systemImage: "calendar.badge.clock"
            )
            .foregroundStyle(.secondary)
          case .dayOff:
            Text(
              model.adjustableDayIsWorkday
                ? "No work today. Your regular schedule continues on the next workday."
                : "Today isn't a workday in your regular schedule anyway."
            )
            .foregroundStyle(.secondary)
          }
        } header: {
          Text("Today only")
        } footer: {
          HStack(alignment: .firstTextBaseline) {
            Text(
              "Never changes your regular schedule. Applies to work starting today, or running now, and ends with it."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            Spacer()
            Button("Edit Regular Schedule…") { navigation.pane = .schedule }
              .controlSize(.small)
              .dayleftGlassButtonStyle()
          }
        }

        if choice == .different {
          SessionsEditor(
            sessions: $sessions, title: "Today's sessions", now: model.nowTimeOfDay,
            note: model.endsWorkNow(sessions) ? "Applying this ends today's work now." : nil)
        }
      }
      .formStyle(.grouped)

      Divider()
      HStack {
        Spacer()
        Button("Revert", action: load)
          .disabled(!hasChanges)
          .dayleftGlassButtonStyle()
        Button("Apply", action: apply)
          .keyboardShortcut(.defaultAction)
          .disabled(!hasChanges)
          .dayleftGlassButtonStyle(prominent: true)
      }
      .padding(12)
    }
    .onAppear(perform: load)
    .onChange(of: model.adjustableChange) { load() }
    .onChange(of: navigation.openCount) { load() }
  }

  private var regularText: String {
    guard let regular = model.regularSessionsForAdjustableDay else {
      return
        "Today isn't a workday in your regular schedule. Choose Different hours to work anyway."
    }
    return "Today follows your regular schedule: \(formatter.sessionsSummary(regular))."
  }

  private var hasChanges: Bool {
    switch choice {
    case .regular: model.adjustableChange != nil
    case .different: model.adjustableChange != .sessions(sessions)
    case .dayOff: model.adjustableChange != .dayOff
    }
  }

  /// Today's regular sessions, or the first plan's on a day off, as a starting draft.
  private static func regularOrDefault(_ model: TimerModel) -> WorkSessions {
    model.regularSessionsForAdjustableDay ?? model.settings.schedule.plans[0].sessions
  }

  /// Resets the draft to the saved change for the adjustable day.
  private func load() {
    switch model.adjustableChange {
    case .sessions(let custom):
      choice = .different
      sessions = custom
    case .dayOff:
      choice = .dayOff
      sessions = Self.regularOrDefault(model)
    case nil:
      choice = .regular
      sessions = Self.regularOrDefault(model)
    }
  }

  private func apply() {
    switch choice {
    case .regular: model.updateOverride(nil)
    case .different: model.applyToday(.sessions(sessions))
    case .dayOff: model.applyToday(.dayOff)
    }
  }
}
