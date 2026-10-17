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
    if #available(macOS 26, *) {
      glassBody
    } else {
      classicBody
    }
  }

  /// macOS 26 and later: the panel is already glass, so the rows and buttons float on it as
  /// interactive glass instead of being separated by dividers.
  @available(macOS 26, *)
  private var glassBody: some View {
    VStack(alignment: .leading, spacing: 14) {
      countdown
        .padding(.horizontal, 6)
        .padding(.top, 6)
      GlassEffectContainer(spacing: 6) {
        VStack(spacing: 6) {
          rows
        }
      }
      footer
    }
    .padding(14)
    .frame(width: 300)
  }

  private var classicBody: some View {
    VStack(alignment: .leading, spacing: 0) {
      countdown
        .padding(20)
      Divider()
      VStack(spacing: 2) {
        rows
      }
      .padding(6)
      Divider()
      footer
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
    .frame(width: 300)
  }

  @ViewBuilder private var rows: some View {
    PanelRow(title: "Today", value: todayText, highlighted: model.adjustableChange != nil) {
      open(.today)
    }
    PanelRow(title: "Regular schedule", value: regularText) {
      open(.schedule)
    }
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
        if let note = view.dayNote {
          Text(note)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
      .accessibilityElement(children: .combine)

      if let progress = view.progress {
        VStack(spacing: 6) {
          DayProgressBar(progress: progress)
            .accessibilityElement()
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
    .modifier(PanelIconButtons())
  }

  /// `06:30 – 16:55, Weekdays` for one plan, otherwise the number of day plans.
  private var regularText: String {
    let schedule = model.settings.schedule
    guard schedule.plans.count == 1 else { return "\(schedule.plans.count) day plans" }
    let plan = schedule.plans[0]
    return "\(formatter.sessionsSummary(plan.sessions)), \(formatter.workdaysSummary(plan.days))"
  }

  /// Today's work: a today-only change, a non-workday, or the regular hours.
  private var todayText: String {
    switch model.adjustableChange {
    case .sessions(let custom):
      return "\(formatter.sessionsSummary(custom)) (changed)"
    case .dayOff:
      return "Day off (changed)"
    case nil:
      guard let regular = model.regularSessionsForAdjustableDay else { return "Not a workday" }
      return formatter.sessionsSummary(regular)
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
      .modifier(PanelRowSurface(hovering: hovering, highlighted: highlighted))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { hovering = $0 }
    .accessibilityLabel("\(title), \(value)")
    .accessibilityHint("Opens Dayleft settings")
  }
}

/// A row's background: interactive glass on macOS 26 and later (tinted while today is changed),
/// otherwise a fill that appears on hover.
private struct PanelRowSurface: ViewModifier {
  let hovering: Bool
  let highlighted: Bool

  func body(content: Content) -> some View {
    if #available(macOS 26, *) {
      content
        .padding(.vertical, 3)
        .glassEffect(
          .regular.tint(highlighted ? .orange.opacity(0.35) : nil).interactive(),
          in: RoundedRectangle(cornerRadius: 12))
    } else {
      content
        .background(
          RoundedRectangle(cornerRadius: 6)
            .fill(hovering ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
        )
    }
  }
}

/// Footer icon buttons: round glass buttons on macOS 26 and later, borderless before.
private struct PanelIconButtons: ViewModifier {
  func body(content: Content) -> some View {
    if #available(macOS 26, *) {
      content
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.large)
    } else {
      content.buttonStyle(PanelIconButtonStyle())
    }
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

/// The day's sessions on one bar: breaks are gaps, and work before now is solid.
private struct DayProgressBar: View {
  let progress: DayPresentation.Progress

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      ZStack(alignment: .leading) {
        ForEach(Array(progress.segments.enumerated()), id: \.offset) { _, segment in
          let length = segment.end - segment.start
          // The part of this session before now.
          let done = min(max(progress.nowFraction - segment.start, 0), length)
          Capsule()
            .fill(Color.orange.opacity(0.28))
            .frame(width: max(length * width, 4))
            .offset(x: segment.start * width)
          if done > 0 {
            Capsule()
              .fill(Color.orange)
              .frame(width: max(done * width, 4))
              .offset(x: segment.start * width)
          }
        }
      }
    }
    .frame(height: 6)
  }
}
