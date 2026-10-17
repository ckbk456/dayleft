import DayleftCore
import DayleftPresentation
import SwiftUI

/// Changes only today's shift (or the one running now) without touching the usual hours.
/// Edits are a draft until Apply, since a change can end the running shift immediately.
struct TodayPane: View {
  let model: TimerModel
  let navigation: SettingsNavigation

  private enum Choice: Hashable {
    case usual
    case custom
    case dayOff
  }

  @State private var choice: Choice = .usual
  @State private var hours: ShiftHours

  init(model: TimerModel, navigation: SettingsNavigation) {
    self.model = model
    self.navigation = navigation
    _hours = State(initialValue: model.settings.schedule.hours)
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
            }
          }
        }

        Section {
          Picker("Today's shift", selection: $choice) {
            Text("Usual hours").tag(Choice.usual)
            Text("Custom hours").tag(Choice.custom)
            Text("Day off").tag(Choice.dayOff)
          }
          .pickerStyle(.segmented)

          switch choice {
          case .usual:
            Text("Today follows your usual hours, \(usualHoursText).")
              .foregroundStyle(.secondary)
          case .custom:
            DayDial(
              hours: $hours, now: model.nowTimeOfDay,
              note: model.endsShiftNow(hours) ? "Applying this ends today's shift now." : nil,
              formatter: formatter
            )
            .frame(width: 280)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
          case .dayOff:
            Text("Today's shift is skipped. Your usual hours apply to the next workday.")
              .foregroundStyle(.secondary)
          }
        } header: {
          Text("Today only")
        } footer: {
          Text("Applies to the shift starting today, or the one running now, and ends with it.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .formStyle(.grouped)

      Divider()
      HStack {
        Spacer()
        Button("Revert", action: load)
          .disabled(!hasChanges)
        Button("Apply", action: apply)
          .keyboardShortcut(.defaultAction)
          .disabled(!hasChanges)
      }
      .padding(12)
    }
    .onAppear(perform: load)
    .onChange(of: model.adjustableChange) { load() }
    .onChange(of: navigation.openCount) { load() }
  }

  private var usualHoursText: String {
    let usual = model.settings.schedule.hours
    return "\(formatter.time(usual.start)) – \(formatter.time(usual.cutoff))"
  }

  private var hasChanges: Bool {
    switch choice {
    case .usual: model.adjustableChange != nil
    case .custom: model.adjustableChange != .hours(hours)
    case .dayOff: model.adjustableChange != .dayOff
    }
  }

  /// Resets the draft to the saved change for the adjustable shift.
  private func load() {
    switch model.adjustableChange {
    case .hours(let custom):
      choice = .custom
      hours = custom
    case .dayOff:
      choice = .dayOff
      hours = model.settings.schedule.hours
    case nil:
      choice = .usual
      hours = model.settings.schedule.hours
    }
  }

  private func apply() {
    switch choice {
    case .usual: model.updateOverride(nil)
    case .custom: model.applyToday(.hours(hours))
    case .dayOff: model.applyToday(.dayOff)
    }
  }
}
