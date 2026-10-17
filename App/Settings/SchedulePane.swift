import DayleftCore
import DayleftPresentation
import SwiftUI

/// The regular schedule: recurring hours and workdays. Changes apply immediately.
struct SchedulePane: View {
  let model: TimerModel

  private var formatter: DayleftFormatter {
    DayleftFormatter(calendar: .autoupdatingCurrent, locale: .autoupdatingCurrent)
  }

  private var schedule: Schedule { model.settings.schedule }

  var body: some View {
    Form {
      Section {
        DayDial(hours: hoursBinding, now: nil, note: nil, formatter: formatter)
          .frame(width: 320)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
      } header: {
        Text("Regular hours")
      } footer: {
        Text(
          "Every workday uses these hours unless you change today's work in Today. A cutoff before the start ends the next day."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
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
    }
    .formStyle(.grouped)
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
}
