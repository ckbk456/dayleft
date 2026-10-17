import AppKit
import DayleftCore
import DayleftPresentation
import SwiftUI

/// The menu bar panel: a read-only detail view of today. Editing happens in the settings window.
struct PanelView: View {
  let model: TimerModel
  let openSettings: (SettingsPane?) -> Void

  @Environment(\.dismiss) private var dismiss

  private var view: DayPresentation { model.presentation }

  private var formatter: DayleftFormatter {
    DayleftFormatter(calendar: .autoupdatingCurrent, locale: .autoupdatingCurrent)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      countdown
        .padding(20)
      Divider()
      VStack(spacing: 2) {
        PanelRow(title: "Today", value: todayText, highlighted: model.adjustableChange != nil) {
          open(.today)
        }
        PanelRow(
          title: "Usual hours",
          value: "\(usualHoursText), \(formatter.workdaysSummary(model.settings.schedule.workdays))"
        ) {
          open(.schedule)
        }
      }
      .padding(6)
      Divider()
      footer
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
    .frame(width: 300)
  }

  private var countdown: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 6) {
        Text(view.eyebrow)
          .font(.caption.weight(.semibold))
          .tracking(1)
          .foregroundStyle(.secondary)
        Text(view.headline)
          .font(.system(size: 40, weight: .semibold, design: .rounded))
          .monospacedDigit()
        Text(view.detail)
          .foregroundStyle(.secondary)
      }
      .accessibilityElement(children: .combine)

      if let progress = view.progress {
        VStack(spacing: 6) {
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
    }
  }

  private var footer: some View {
    HStack(spacing: 4) {
      Button {
        open(nil)
      } label: {
        Image(systemName: "gearshape")
      }
      .help("Settings")
      .accessibilityLabel("Settings")
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

      Button {
        NSApplication.shared.terminate(nil)
      } label: {
        Image(systemName: "power")
      }
      .help("Quit Dayleft")
      .accessibilityLabel("Quit Dayleft")
      .keyboardShortcut("q")
    }
    .buttonStyle(PanelIconButtonStyle())
  }

  private var usualHoursText: String {
    let hours = model.settings.schedule.hours
    return "\(formatter.time(hours.start)) – \(formatter.time(hours.cutoff))"
  }

  /// Today's shift: a today-only change, a non-workday, or the usual hours.
  private var todayText: String {
    switch model.adjustableChange {
    case .hours(let custom):
      return "\(formatter.time(custom.start)) – \(formatter.time(custom.cutoff)) (changed)"
    case .dayOff:
      return "Day off (changed)"
    case nil:
      if case .dayOff = model.state { return "Not a workday" }
      return usualHoursText
    }
  }

  private func open(_ pane: SettingsPane?) {
    dismiss()
    openSettings(pane)
  }
}

/// A full-width row that highlights on hover and opens the matching settings pane.
private struct PanelRow: View {
  let title: String
  let value: String
  var highlighted = false
  let action: () -> Void

  @State private var hovering = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Text(title)
        Spacer(minLength: 12)
        Text(value)
          .foregroundStyle(highlighted ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
          .monospacedDigit()
          .lineLimit(1)
          .truncationMode(.middle)
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(hovering ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { hovering = $0 }
    .accessibilityLabel("\(title), \(value)")
    .accessibilityHint("Opens Dayleft settings")
  }
}

/// Borderless icon buttons for the panel footer, highlighted while pressed.
private struct PanelIconButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 13, weight: .medium))
      .foregroundStyle(.secondary)
      .frame(width: 28, height: 24)
      .background(
        RoundedRectangle(cornerRadius: 5)
          .fill(configuration.isPressed ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
      )
      .contentShape(Rectangle())
  }
}
