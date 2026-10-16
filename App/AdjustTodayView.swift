import DayleftCore
import DayleftPresentation
import SwiftUI

/// Changes only today's shift (or the one running now) without touching the usual hours.
struct AdjustTodayView: View {
  let model: TimerModel
  let close: () -> Void

  @State private var hours: ShiftHours
  @State private var dayOff: Bool

  init(model: TimerModel, close: @escaping () -> Void) {
    self.model = model
    self.close = close
    switch model.adjustableChange {
    case .hours(let custom):
      _hours = State(initialValue: custom)
      _dayOff = State(initialValue: false)
    case .dayOff:
      _hours = State(initialValue: model.settings.schedule.hours)
      _dayOff = State(initialValue: true)
    case nil:
      _hours = State(initialValue: model.settings.schedule.hours)
      _dayOff = State(initialValue: false)
    }
  }

  private var formatter: DayleftFormatter {
    DayleftFormatter(calendar: .autoupdatingCurrent, locale: .autoupdatingCurrent)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("ADJUST TODAY")
        .font(.caption.weight(.semibold))
        .tracking(1)
        .foregroundStyle(.secondary)

      Picker("Today", selection: $dayOff) {
        Text("Custom hours").tag(false)
        Text("Day off").tag(true)
      }
      .pickerStyle(.segmented)
      .labelsHidden()

      if dayOff {
        Text("Today's shift is skipped. Your usual hours apply to the next workday.")
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      } else {
        DayDial(
          hours: $hours, now: model.nowTimeOfDay,
          note: model.endsShiftNow(hours) ? "This ends today's shift now." : nil,
          formatter: formatter)
      }

      HStack {
        if model.adjustableChange != nil {
          Button("Use usual hours") {
            model.updateOverride(nil)
            close()
          }
        }
        Spacer()
        Button("Cancel", action: close)
          .keyboardShortcut(.cancelAction)
        Button("Apply") {
          model.applyToday(dayOff ? .dayOff : .hours(hours))
          close()
        }
        .keyboardShortcut(.defaultAction)
      }
    }
  }
}
