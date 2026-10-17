import SwiftUI

/// App-wide preferences.
struct GeneralPane: View {
  let loginItem: LoginItem

  var body: some View {
    Form {
      Section {
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
      } footer: {
        Text("Dayleft lives in the menu bar. This window only changes its settings.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
  }

  private var loginBinding: Binding<Bool> {
    Binding(get: { loginItem.isEnabled }, set: { loginItem.setEnabled($0) })
  }
}
