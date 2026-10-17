import AppKit
import DayleftCore
import DayleftPresentation
import SwiftUI

/// The menu bar panel from the approved design, driven by the live timer model.
struct PanelView: View {
  let model: TimerModel

  @Environment(\.openSettings) private var openSettings
  @State private var adjusting = false

  private var view: DayPresentation { model.presentation }

  private var formatter: DayleftFormatter {
    DayleftFormatter(calendar: .autoupdatingCurrent, locale: .autoupdatingCurrent)
  }

  var body: some View {
    Group {
      if adjusting {
        AdjustTodayView(model: model) { adjusting = false }
      } else {
        overview
      }
    }
    .padding(24)
    .frame(width: 340)
  }

  private var overview: some View {
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

      VStack(spacing: 12) {
        Divider()
        Button(action: showSettings) {
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text("Work hours")
              Text(formatter.workdaysSummary(model.settings.schedule.workdays))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(workHoursText)
              .foregroundStyle(.secondary)
              .monospacedDigit()
            Image(systemName: "chevron.right")
              .foregroundStyle(.secondary)
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.primary)
        .accessibilityLabel("Work hours, \(workHoursText). Open Settings")

        if let todayText {
          Text(todayText)
            .font(.caption)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        Divider()
      }

      Button {
        adjusting = true
      } label: {
        Text("Adjust today…")
          .frame(maxWidth: .infinity)
      }
      .controlSize(.large)

      Divider()
      HStack {
        Button(action: showSettings) {
          Label("Settings", systemImage: "gearshape")
        }
        .keyboardShortcut(",")
        Spacer()
        Text(BuildInfo.current.versionText)
          .font(.caption2)
          .foregroundStyle(
            BuildInfo.current.isDirty ? AnyShapeStyle(.orange) : AnyShapeStyle(.tertiary)
          )
          .monospacedDigit()
          .textSelection(.enabled)
          .help("Dayleft version and source commit")
        Spacer()
        Button("Quit") { NSApplication.shared.terminate(nil) }
          .keyboardShortcut("q")
      }
      .buttonStyle(.borderless)
    }
  }

  private var workHoursText: String {
    let hours = model.settings.schedule.hours
    return "\(formatter.time(hours.start)) – \(formatter.time(hours.cutoff))"
  }

  private var todayText: String? {
    switch model.adjustableChange {
    case .hours(let custom):
      return "Today: \(formatter.time(custom.start)) – \(formatter.time(custom.cutoff))"
    case .dayOff:
      return "Today: day off"
    case nil:
      return nil
    }
  }

  private func showSettings() {
    // A menu bar app is not active by default; activate so Settings comes to the front.
    NSApplication.shared.activate()
    openSettings()
  }
}
