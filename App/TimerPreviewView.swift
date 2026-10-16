import AppKit
import DayleftCore
import SwiftUI

/// A fixed example of the approved design. Live scheduling is the next milestone.
struct TimerPreviewView: View {
  private let snapshot: WorkWindow.Snapshot = {
    let start = Date(timeIntervalSince1970: 9 * 3_600)
    let end = Date(timeIntervalSince1970: 18 * 3_600)
    // Fixed, valid fixture: 09:00–18:00 viewed at 14:36.
    let window = try! WorkWindow(start: start, end: end)
    return window.snapshot(at: start.addingTimeInterval(5 * 3_600 + 36 * 60))
  }()

  /// Temporary formatting until the presentation layer lands.
  private var remainingText: String {
    let minutes = snapshot.remainingWholeMinutes
    return minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 8) {
        Text("WORKDAY")
          .font(.caption.weight(.semibold))
          .tracking(1)
          .foregroundStyle(.secondary)
        Text(remainingText)
          .font(.system(size: 42, weight: .semibold, design: .rounded))
          .monospacedDigit()
        Text("left until 18:00")
          .foregroundStyle(.secondary)
      }

      VStack(spacing: 8) {
        ProgressView(value: snapshot.elapsedFraction)
          .tint(.orange)
          .accessibilityLabel("Workday elapsed")
          .accessibilityValue("62 percent")
        HStack {
          Text("09:00")
          Spacer()
          Text("18:00")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .monospacedDigit()
      }

      Divider()
      HStack {
        Text("Work hours")
        Spacer()
        Text("09:00–18:00")
          .foregroundStyle(.secondary)
          .monospacedDigit()
      }
      Divider()
      HStack {
        Text("Sample day")
          .font(.caption)
          .foregroundStyle(.secondary)
          .help("A fixed design preview. Live scheduling and settings are planned.")
        Spacer()
        Button("Quit") { NSApplication.shared.terminate(nil) }
          .keyboardShortcut("q")
          .buttonStyle(.plain)
      }
    }
    .padding(24)
    .frame(width: 340)
  }
}
