import DayleftPresentation
import Foundation

extension BuildInfo {
  /// The running app's identity, read once from its Info.plist.
  static let current = BuildInfo(infoDictionary: Bundle.main.infoDictionary ?? [:])
}
