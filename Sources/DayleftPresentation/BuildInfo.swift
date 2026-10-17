import Foundation

/// Identifies the running build from its Info.plist: the semantic version plus the source commit
/// recorded by `scripts/stamp_build_info.sh`.
public struct BuildInfo: Equatable, Sendable {
  /// Semantic version, `CFBundleShortVersionString` (e.g. `0.2.0`).
  public let version: String
  /// Monotonic build number, `CFBundleVersion`.
  public let build: String
  /// Short commit, suffixed `.dirty` when built with uncommitted changes; nil if unstamped.
  public let commit: String?
  public let builtAt: Date?

  public init(infoDictionary: [String: Any]) {
    version = infoDictionary["CFBundleShortVersionString"] as? String ?? "0.0.0"
    build = infoDictionary["CFBundleVersion"] as? String ?? "0"
    let stamped = infoDictionary["DayleftCommit"] as? String
    commit = stamped?.isEmpty == false && stamped != "unknown" ? stamped : nil
    builtAt = (infoDictionary["DayleftBuiltAt"] as? String).flatMap {
      try? Date($0, strategy: .iso8601)
    }
  }

  /// SemVer with build metadata, e.g. `0.2.0+abc1234` or `0.2.0+abc1234.dirty`.
  public var versionText: String {
    commit.map { "\(version)+\($0)" } ?? version
  }

  /// Whether the build includes changes that are not in its recorded commit.
  public var isDirty: Bool { commit?.hasSuffix(".dirty") ?? false }
}
