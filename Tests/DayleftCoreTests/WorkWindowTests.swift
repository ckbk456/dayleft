import Foundation
import Testing

@testable import DayleftCore

struct WorkWindowTests {
  private let start = Date(timeIntervalSince1970: 9 * 3_600)
  private let end = Date(timeIntervalSince1970: 18 * 3_600)

  @Test func rejectsEmptyOrReversedWindows() {
    #expect(throws: WorkWindow.ValidationError.invalidBounds) {
      try WorkWindow(start: start, end: start)
    }
    #expect(throws: WorkWindow.ValidationError.invalidBounds) {
      try WorkWindow(start: end, end: start)
    }
  }

  @Test func rejectsNonfiniteBounds() {
    #expect(throws: WorkWindow.ValidationError.invalidBounds) {
      try WorkWindow(start: start, end: Date(timeIntervalSince1970: .infinity))
    }
    #expect(throws: WorkWindow.ValidationError.invalidBounds) {
      try WorkWindow(start: Date(timeIntervalSince1970: .nan), end: end)
    }
  }

  @Test func beforeWorkPreservesTheFullWorkBudget() throws {
    let window = try WorkWindow(start: start, end: end)
    let snapshot = window.snapshot(at: start.addingTimeInterval(-60))
    #expect(snapshot.phase == .upcoming)
    #expect(snapshot.remaining == 9 * 3_600)
    #expect(snapshot.elapsedFraction == 0)
  }

  @Test func exactStartIsWorking() throws {
    let snapshot = try WorkWindow(start: start, end: end).snapshot(at: start)
    #expect(snapshot.phase == .working)
    #expect(snapshot.remainingLabel == "9h 0m")
    #expect(snapshot.elapsedFraction == 0)
  }

  @Test func matchesTheApprovedExample() throws {
    let now = start.addingTimeInterval(5 * 3_600 + 36 * 60)
    let snapshot = try WorkWindow(start: start, end: end).snapshot(at: now)
    #expect(snapshot.phase == .working)
    #expect(snapshot.remaining == 3 * 3_600 + 24 * 60)
    #expect(snapshot.remainingLabel == "3h 24m")
    #expect(abs(snapshot.elapsedFraction - 0.622_222_222_2) < 0.000_001)
  }

  @Test func aLongClockJumpDoesNotRequireMissedTicks() throws {
    let window = try WorkWindow(start: start, end: end)
    _ = window.snapshot(at: start)
    let afterWake = window.snapshot(at: end.addingTimeInterval(3_600))
    #expect(afterWake.phase == .finished)
    #expect(afterWake.remaining == 0)
    #expect(afterWake.elapsedFraction == 1)
  }

  @Test func exactFinishIsFinished() throws {
    let snapshot = try WorkWindow(start: start, end: end).snapshot(at: end)
    #expect(snapshot.phase == .finished)
    #expect(snapshot.remainingLabel == "0m")
    #expect(snapshot.elapsedFraction == 1)
  }

  @Test func finalPartialMinuteRoundsUp() throws {
    let window = try WorkWindow(start: start, end: end)
    #expect(window.snapshot(at: end.addingTimeInterval(-0.5)).remainingLabel == "1m")
    #expect(window.snapshot(at: end.addingTimeInterval(-3_600.5)).remainingLabel == "1h 1m")
  }

  @Test func resolvedWindowCanCrossMidnight() throws {
    let nightStart = Date(timeIntervalSince1970: 22 * 3_600)
    let nightEnd = Date(timeIntervalSince1970: 26 * 3_600)
    let midnight = Date(timeIntervalSince1970: 24 * 3_600)
    let snapshot = try WorkWindow(start: nightStart, end: nightEnd).snapshot(at: midnight)
    #expect(snapshot.remainingLabel == "2h 0m")
    #expect(snapshot.elapsedFraction == 0.5)
  }

  @Test func daylightSavingUsesActualElapsedTime() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
    let start = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 1, minute: 30)))
    let end = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 3, minute: 30)))
    let now = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 3)))
    let snapshot = try WorkWindow(start: start, end: end).snapshot(at: now)
    #expect(snapshot.remaining == 30 * 60)
    #expect(snapshot.elapsedFraction == 0.5)
  }
}
