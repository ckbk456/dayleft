import AppKit
import DayleftPresentation
import SwiftUI

/// Identifies exactly which build is running.
struct AboutPane: View {
  private let build = BuildInfo.current

  var body: some View {
    Form {
      Section {
        HStack(spacing: 14) {
          Image(systemName: "hourglass")
            .font(.system(size: 34, weight: .medium))
            .foregroundStyle(.orange)
          VStack(alignment: .leading, spacing: 2) {
            Text("Dayleft")
              .font(.title2.weight(.semibold))
            Text("How much of your workday is left.")
              .foregroundStyle(.secondary)
          }
        }
        .padding(.vertical, 4)
      }

      Section("Build") {
        LabeledContent("Version") {
          Text(build.versionText)
            .monospacedDigit()
            .textSelection(.enabled)
        }
        LabeledContent("Build number", value: build.build)
        if let builtAt = build.builtAt {
          LabeledContent("Built", value: builtAt.formatted(date: .abbreviated, time: .shortened))
        }
        if build.isDirty {
          Text("Built with uncommitted changes, so the commit alone does not identify it.")
            .font(.caption)
            .foregroundStyle(.orange)
        }
        HStack {
          Spacer()
          Button("Copy Version") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(build.versionText, forType: .string)
          }
        }
      }
    }
    .formStyle(.grouped)
  }
}
