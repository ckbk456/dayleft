import SwiftUI

// Liquid Glass on macOS 26 and later, with the earlier button styles and fills on macOS 14 and 15.
// Views use these instead of checking availability themselves.

extension View {
  /// Glass buttons on macOS 26 and later; bordered buttons before.
  @ViewBuilder
  func dayleftGlassButtonStyle(prominent: Bool = false) -> some View {
    if #available(macOS 26, *) {
      if prominent { buttonStyle(.glassProminent) } else { buttonStyle(.glass) }
    } else {
      if prominent { buttonStyle(.borderedProminent) } else { buttonStyle(.bordered) }
    }
  }

  /// Marks the selected row of a list: orange-tinted glass on macOS 26 and later, an orange fill
  /// before. Unselected rows have no background.
  @ViewBuilder
  func dayleftSelection(_ isSelected: Bool) -> some View {
    let shape = RoundedRectangle(cornerRadius: 8)
    if !isSelected {
      self
    } else if #available(macOS 26, *) {
      glassEffect(.regular.tint(.orange.opacity(0.3)), in: shape)
    } else {
      background(Color.orange.opacity(0.16), in: shape)
    }
  }
}
