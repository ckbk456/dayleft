import DayleftCore
import DayleftPresentation
import SwiftUI

/// Changes only today's work (or the work running now); the regular schedule is never edited here.
/// Edits are a draft until Apply, since a change can end the running shift immediately.
struct TodayPane: View {
  let model: TimerModel
  let navigation: SettingsNavigation

  private enum Choice: Hashable {
    case regular
    case different
    case dayOff
  }

  @State private var choice: Choice = .regular
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
          Picker("Today's work", selection: $choice) {
            Text("Regular schedule").tag(Choice.regular)
            Text("Different hours").tag(Choice.different)
            Text("Day off").tag(Choice.dayOff)
          }
          .pickerStyle(.segmented)

          switch choice {
          case .regular:
            Text(
              model.adjustableDayIsWorkday
                ? "Today follows your regular schedule: \(regularHoursText)."
                : "Today isn't a workday in your regular schedule. Choose Different hours to work anyway."
            )
            .foregroundStyle(.secondary)
          case .different:
            Label(
              "These hours are for today only. Your regular schedule stays \(regularHoursText).",
              systemImage: "calendar.badge.clock"
            )
            .foregroundStyle(.secondary)
            DayDial(
              hours: $hours, now: model.nowTimeOfDay,
              note: model.endsShiftNow(hours) ? "Applying this ends today's work now." : nil,
              formatter: formatter
            )
            .frame(width: 320)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
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
          }
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

  /// `06:30 – 16:55, Weekdays`.
  private var regularHoursText: String {
    let schedule = model.settings.schedule
    let hours = "\(formatter.time(schedule.hours.start)) – \(formatter.time(schedule.hours.cutoff))"
    return "\(hours), \(formatter.workdaysSummary(schedule.workdays))"
  }

  private var hasChanges: Bool {
    switch choice {
    case .regular: model.adjustableChange != nil
    case .different: model.adjustableChange != .hours(hours)
    case .dayOff: model.adjustableChange != .dayOff
    }
  }

  /// Resets the draft to the saved change for the adjustable shift.
  private func load() {
    switch model.adjustableChange {
    case .hours(let custom):
      choice = .different
      hours = custom
    case .dayOff:
      choice = .dayOff
      hours = model.settings.schedule.hours
    case nil:
      choice = .regular
      hours = model.settings.schedule.hours
    }
  }

  private func apply() {
    switch choice {
    case .regular: model.updateOverride(nil)
    case .different: model.applyToday(.hours(hours))
    case .dayOff: model.applyToday(.dayOff)
    }
  }
}
