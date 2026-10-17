import DayleftCore
import DayleftPresentation
import SwiftUI

/// Recurring work hours, workdays, and login launch. Changes apply immediately.
struct SettingsView: View {
  let model: TimerModel
  let loginItem: LoginItem

  private var formatter: DayleftFormatter {
    DayleftFormatter(calendar: .autoupdatingCurrent, locale: .autoupdatingCurrent)
  }

  private var schedule: Schedule { model.settings.schedule }
  private var build: BuildInfo { .current }

  var body: some View {
    Form {
      Section("Work hours") {
        DayDial(hours: hoursBinding, now: nil, note: nil, formatter: formatter)
          .frame(width: 280)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
      }

      Section {
        HStack(spacing: 6) {
          ForEach(formatter.orderedWeekdays, id: \.self) { day in
            Toggle(formatter.shortName(day), isOn: workdayBinding(day))
              .toggleStyle(.button)
              .disabled(schedule.workdays == [day])
          }
        }
        .frame(maxWidth: .infinity)
      } header: {
        Text("Workdays")
      } footer: {
        Text("Days off show “Off” in the menu bar. Keep at least one workday.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section("General") {
        Toggle("Launch at login", isOn: loginBinding)
        if loginItem.status == .requiresApproval {
          HStack {
            Text("Approve Dayleft in Login Items to finish.")
              .font(.caption)
              .foregroundStyle(.secondary)
            Spacer()
            Button("Open Login Items") { loginItem.openSystemSettings() }
          }
        }
        if let error = loginItem.lastError {
          Text(error)
            .font(.caption)
            .foregroundStyle(.red)
        }
      }

      Section("About") {
        LabeledContent("Version") {
          Text(build.versionText)
            .monospacedDigit()
            .textSelection(.enabled)
        }
        LabeledContent("Build", value: build.build)
        if let builtAt = build.builtAt {
          LabeledContent("Built", value: builtAt.formatted(date: .abbreviated, time: .shortened))
        }
        if build.isDirty {
          Text("Built with uncommitted changes, so the commit alone does not identify it.")
            .font(.caption)
            .foregroundStyle(.orange)
        }
      }
    }
    .formStyle(.grouped)
    .frame(width: 400)
    .onAppear { loginItem.refresh() }
  }

  private var hoursBinding: Binding<ShiftHours> {
    Binding(
      get: { schedule.hours },
      set: { hours in
        if let updated = try? Schedule(hours: hours, workdays: schedule.workdays) {
          model.updateSchedule(updated)
        }
      })
  }

  private func workdayBinding(_ day: Weekday) -> Binding<Bool> {
    Binding(
      get: { schedule.workdays.contains(day) },
      set: { isOn in
        var workdays = schedule.workdays
        if isOn { workdays.insert(day) } else { workdays.remove(day) }
        if let updated = try? Schedule(hours: schedule.hours, workdays: workdays) {
          model.updateSchedule(updated)
        }
      })
  }

  private var loginBinding: Binding<Bool> {
    Binding(get: { loginItem.isEnabled }, set: { loginItem.setEnabled($0) })
  }
}
