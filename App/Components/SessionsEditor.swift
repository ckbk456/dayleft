import DayleftCore
import DayleftPresentation
import SwiftUI

/// Form sections for editing a day's sessions: the dial, then a list of sessions with add,
/// remove, and selection. Selecting a row highlights its arc and gives it the dial's handles.
struct SessionsEditor: View {
  @Binding var sessions: WorkSessions
  var title: String = "Sessions"
  var now: TimeOfDay?
  var note: String?

  @State private var selection = 0

  private var formatter: DayleftFormatter {
    DayleftFormatter(calendar: .autoupdatingCurrent, locale: .autoupdatingCurrent)
  }

  var body: some View {
    Section {
      DayDial(
        sessions: $sessions, selection: clampedSelection, now: now, note: note,
        formatter: formatter
      )
      .frame(width: 320)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
    } header: {
      Text(title)
    }

    Section {
      ForEach(Array(sessions.all.enumerated()), id: \.offset) { index, session in
        SessionRow(
          name: "Session \(index + 1)", range: formatter.range(session),
          length: formatter.duration(minutes: session.durationMinutes),
          nextDay: session.crossesMidnight, isSelected: index == clampedSelection.wrappedValue
        ) {
          selection = index
        }
      }
    } footer: {
      HStack(spacing: 8) {
        Button {
          if let added = sessions.addingSession() {
            sessions = added.sessions
            selection = added.index
          }
        } label: {
          Label("Add Session", systemImage: "plus")
        }
        .disabled(sessions.addingSession() == nil)
        .help(addHelp)

        Button {
          if let removed = sessions.removing(at: clampedSelection.wrappedValue) {
            sessions = removed
            selection = max(clampedSelection.wrappedValue - 1, 0)
          }
        } label: {
          Label("Remove Session", systemImage: "minus")
        }
        .disabled(sessions.count == 1)
        .help("Remove the selected session")

        Spacer()
        Text("Breaks between sessions are not counted as work.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .controlSize(.small)
    }
  }

  private var addHelp: String {
    sessions.count >= WorkSessions.maximumCount
      ? "Up to \(WorkSessions.maximumCount) sessions a day"
      : "Add a session in the longest break"
  }

  /// The selection, kept in range when sessions are removed elsewhere.
  private var clampedSelection: Binding<Int> {
    Binding(
      get: { min(selection, sessions.count - 1) },
      set: { selection = $0 })
  }
}

/// One session in the list; the selected row matches the bright arc on the dial.
private struct SessionRow: View {
  let name: String
  let range: String
  let length: String
  let nextDay: Bool
  let isSelected: Bool
  let select: () -> Void

  var body: some View {
    Button(action: select) {
      HStack(spacing: 10) {
        Capsule()
          .fill(Color.orange.opacity(isSelected ? 1 : 0.38))
          .frame(width: 4, height: 18)
        Text(name)
          .fontWeight(isSelected ? .semibold : .regular)
        Spacer()
        Text(range + (nextDay ? " (+1 day)" : ""))
          .monospacedDigit()
        Text(length)
          .monospacedDigit()
          .foregroundStyle(.secondary)
          .frame(minWidth: 56, alignment: .trailing)
      }
      .padding(.vertical, 4)
      .padding(.horizontal, 6)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(isSelected ? AnyShapeStyle(Color.orange.opacity(0.16)) : AnyShapeStyle(.clear))
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(name), \(range), \(length)")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}
