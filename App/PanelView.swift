import AppKit
import DayleftPresentation
import SwiftUI

/// The menu bar panel from the approved design, driven by the live timer model.
struct PanelView: View {
  let model: TimerModel

  private var view: DayPresentation { model.presentation }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 8) {
        Text(view.eyebrow)
          .font(.caption.weight(.semibold))
          .tracking(1)
          .foregroundStyle(.secondary)
        Text(view.headline)
          .font(.system(size: 42, weight: .semibold, design: .rounded))
          .monospacedDigit()
        Text(view.detail)
          .foregroundStyle(.secondary)
      }
      .accessibilityElement(children: .combine)

      if let progress = view.progress {
        VStack(spacing: 8) {
          ProgressView(value: progress.elapsedFraction)
            .tint(.orange)
            .accessibilityLabel("Workday elapsed")
            .accessibilityValue(progress.accessibilityValue)
          HStack {
            Text(progress.startText)
            Spacer()
            Text(progress.endText)
          }
          .font(.caption)
          .foregroundStyle(.secondary)
          .monospacedDigit()
        }
      }

      Divider()
      HStack {
        Text("Work hours")
        Spacer()
        Text(workHoursText)
          .foregroundStyle(.secondary)
          .monospacedDigit()
      }
      Divider()
      HStack {
        Spacer()
        Button("Quit") { NSApplication.shared.terminate(nil) }
          .keyboardShortcut("q")
      }
    }
    .padding(24)
    .frame(width: 340)
  }

  private var workHoursText: String {
    let formatter = DayleftFormatter(calendar: .autoupdatingCurrent, locale: .autoupdatingCurrent)
    let hours = model.settings.schedule.hours
    return "\(formatter.time(hours.start)) – \(formatter.time(hours.cutoff))"
  }
}
