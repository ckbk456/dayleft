import DayleftPresentation
import Foundation
import Testing

struct BuildInfoTests {
  @Test func stampedBuildUsesSemVerBuildMetadata() throws {
    let info = BuildInfo(infoDictionary: [
      "CFBundleShortVersionString": "0.2.0", "CFBundleVersion": "2",
      "DayleftCommit": "abc1234", "DayleftBuiltAt": "2026-10-17T09:30:00Z",
    ])
    #expect(info.versionText == "0.2.0+abc1234")
    #expect(info.build == "2")
    #expect(!info.isDirty)
    let builtAt = try #require(info.builtAt)
    #expect(builtAt == Date(timeIntervalSince1970: 1_792_229_400))
  }

  @Test func dirtyBuildsSaySo() {
    let info = BuildInfo(infoDictionary: [
      "CFBundleShortVersionString": "0.2.0", "DayleftCommit": "abc1234.dirty",
    ])
    #expect(info.versionText == "0.2.0+abc1234.dirty")
    #expect(info.isDirty)
  }

  @Test func unstampedBuildsFallBackToTheVersion() {
    let info = BuildInfo(infoDictionary: [
      "CFBundleShortVersionString": "0.2.0", "DayleftCommit": "unknown",
    ])
    #expect(info.versionText == "0.2.0")
    #expect(info.commit == nil)
    #expect(info.builtAt == nil)
    #expect(BuildInfo(infoDictionary: [:]).versionText == "0.0.0")
  }
}
