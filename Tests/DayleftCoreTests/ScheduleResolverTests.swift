import DayleftCore
import Foundation
import Testing

/// Dates are in October 2026 unless stated: Friday 16, Saturday 17, Sunday 18, Monday 19.
struct ScheduleResolverTests {
  private let la = calendar("America/Los_Angeles")
  private var resolver: ScheduleResolver { ScheduleResolver(calendar: la) }
  private let everyDay = Set(Weekday.allCases)

  private func state(
    _ schedule: Schedule, _ day: Int, _ hour: Int, _ minute: Int, override: DayOverride? = nil
  ) -> DayState {
    resolver.state(
      at: date(2026, 10, day, hour, minute, in: la), schedule: schedule, override: override)
  }

  private func window(_ start: Date, _ end: Date) -> WorkWindow {
    try! WorkWindow(start: start, end: end)
  }

  private var friday: WorkWindow {
    window(date(2026, 10, 16, 9, 0, in: la), date(2026, 10, 16, 18, 0, in: la))
  }
  private var monday: WorkWindow {
    window(date(2026, 10, 19, 9, 0, in: la), date(2026, 10, 19, 18, 0, in: la))
  }

  // MARK: Standard workweek

  @Test func approvedExampleIsWorking() throws {
    guard case .working(let active, let snapshot) = state(.standard, 16, 14, 36) else {
      Issue.record("Expected working")
      return
    }
    #expect(active == friday)
    #expect(snapshot.remainingWholeMinutes == 204)
    #expect(abs(snapshot.elapsedFraction - 0.622_222) < 0.000_001)
  }

  @Test func exactStartWorksAndExactCutoffFinishes() {
    #expect(
      state(.standard, 16, 9, 0)
        == .working(window: friday, snapshot: friday.snapshot(at: friday.start)))
    #expect(state(.standard, 16, 18, 0) == .finished(window: friday, next: monday))
  }

  @Test func beforeStartShowsTodaysShift() {
    #expect(state(.standard, 16, 7, 0) == .beforeStart(next: friday))
  }

  @Test func doneLastsUntilMidnightThenNextStart() {
    #expect(
      state(.standard, 15, 23, 59)
        == .finished(
          window: window(date(2026, 10, 15, 9, 0, in: la), date(2026, 10, 15, 18, 0, in: la)),
          next: friday))
    #expect(state(.standard, 16, 0, 0) == .beforeStart(next: friday))
  }

  @Test func weekendIsOffUntilMonday() {
    #expect(state(.standard, 16, 23, 59) == .finished(window: friday, next: monday))
    #expect(state(.standard, 17, 0, 0) == .dayOff(next: monday))
    #expect(state(.standard, 18, 12, 0) == .dayOff(next: monday))
    #expect(state(.standard, 19, 0, 0) == .beforeStart(next: monday))
  }

  @Test func singleWorkdayFindsNextWeek() {
    let wednesdays = schedule((9, 0), (18, 0), on: [.wednesday])
    let next = window(date(2026, 10, 21, 9, 0, in: la), date(2026, 10, 21, 18, 0, in: la))
    #expect(state(wednesdays, 15, 12, 0) == .dayOff(next: next))
  }

  // MARK: Overnight shifts

  @Test func fridayNightShiftRunsIntoSaturday() throws {
    let nights = schedule((22, 0), (6, 0))
    let fridayNight = window(date(2026, 10, 16, 22, 0, in: la), date(2026, 10, 17, 6, 0, in: la))
    let mondayNight = window(date(2026, 10, 19, 22, 0, in: la), date(2026, 10, 20, 6, 0, in: la))
    guard case .working(let active, let snapshot) = state(nights, 17, 2, 0) else {
      Issue.record("Expected working")
      return
    }
    #expect(active == fridayNight)
    #expect(snapshot.remainingWholeMinutes == 240)
    #expect(state(nights, 17, 6, 0) == .finished(window: fridayNight, next: mondayNight))
    #expect(state(nights, 18, 0, 0) == .dayOff(next: mondayNight))
    #expect(state(nights, 19, 10, 0) == .beforeStart(next: mondayNight))
  }

  @Test func doneAfterAnOvernightShiftLastsUntilTheNextStart() {
    let nights = schedule((22, 0), (6, 0))
    let mondayNight = window(date(2026, 10, 19, 22, 0, in: la), date(2026, 10, 20, 6, 0, in: la))
    let tuesdayNight = window(date(2026, 10, 20, 22, 0, in: la), date(2026, 10, 21, 6, 0, in: la))
    #expect(state(nights, 20, 10, 0) == .finished(window: mondayNight, next: tuesdayNight))
    #expect(state(nights, 20, 21, 59) == .finished(window: mondayNight, next: tuesdayNight))
  }

  @Test func cutoffAtMidnightDoesNotCarryDoneIntoTheNextDay() {
    let evenings = schedule((18, 0), (0, 0))
    let mondayEvening = window(date(2026, 10, 19, 18, 0, in: la), date(2026, 10, 20, 0, 0, in: la))
    #expect(state(evenings, 17, 0, 0) == .dayOff(next: mondayEvening))
    let tuesdayEvening = window(date(2026, 10, 20, 18, 0, in: la), date(2026, 10, 21, 0, 0, in: la))
    #expect(state(evenings, 20, 0, 0) == .beforeStart(next: tuesdayEvening))
  }

  // MARK: Today-only changes

  @Test func customHoursApplyOnlyToTheirDay() throws {
    let today = LocalDay(year: 2026, month: 10, day: 16)
    let change = DayOverride(day: today, change: .hours(hours((10, 0), (12, 0))))
    let short = window(date(2026, 10, 16, 10, 0, in: la), date(2026, 10, 16, 12, 0, in: la))
    #expect(
      state(.standard, 16, 11, 0, override: change)
        == .working(
          window: short, snapshot: short.snapshot(at: date(2026, 10, 16, 11, 0, in: la))))
    #expect(
      state(.standard, 16, 12, 30, override: change) == .finished(window: short, next: monday))
    let thursday = window(date(2026, 10, 15, 9, 0, in: la), date(2026, 10, 15, 18, 0, in: la))
    #expect(
      state(.standard, 15, 9, 0, override: change)
        == .working(
          window: thursday, snapshot: thursday.snapshot(at: thursday.start)))
  }

  @Test func dayOffSkipsTodaysShift() {
    let change = DayOverride(day: LocalDay(year: 2026, month: 10, day: 16), change: .dayOff)
    #expect(state(.standard, 16, 10, 0, override: change) == .dayOff(next: monday))
  }

  @Test func yesterdaysOvernightShiftKeepsRunningBesideTodaysChange() throws {
    let nights = schedule((22, 0), (6, 0))
    let change = DayOverride(
      day: LocalDay(year: 2026, month: 10, day: 20), change: .hours(hours((5, 0), (9, 0))))
    let mondayNight = window(date(2026, 10, 19, 22, 0, in: la), date(2026, 10, 20, 6, 0, in: la))
    let tuesdayMorning = window(date(2026, 10, 20, 5, 0, in: la), date(2026, 10, 20, 9, 0, in: la))
    guard case .working(let first, _) = state(nights, 20, 5, 30, override: change),
      case .working(let second, let snapshot) = state(nights, 20, 6, 30, override: change)
    else {
      Issue.record("Expected working twice")
      return
    }
    #expect(first == mondayNight)
    #expect(second == tuesdayMorning)
    #expect(snapshot.remainingWholeMinutes == 150)
  }

  @Test func overridesExpireOnlyWhenTheyCanNoLongerMatter() {
    let overnight = DayOverride(
      day: LocalDay(year: 2026, month: 10, day: 16), change: .hours(hours((20, 0), (4, 0))))
    #expect(!resolver.isExpired(overnight, at: date(2026, 10, 17, 23, 59, in: la)))
    #expect(resolver.isExpired(overnight, at: date(2026, 10, 18, 0, 0, in: la)))
    let off = DayOverride(day: LocalDay(year: 2026, month: 10, day: 17), change: .dayOff)
    #expect(!resolver.isExpired(off, at: date(2026, 10, 18, 23, 59, in: la)))
    #expect(resolver.isExpired(off, at: date(2026, 10, 19, 0, 0, in: la)))
  }

  @Test func shorteningTheRunningShiftKeepsItFinished() {
    // Thursday's usual 22:00–06:00 shift, cut to end at 02:00 while running.
    let nights = schedule((22, 0), (6, 0))
    let change = DayOverride(
      day: LocalDay(year: 2026, month: 10, day: 15), change: .hours(hours((22, 0), (2, 0))))
    let short = window(date(2026, 10, 15, 22, 0, in: la), date(2026, 10, 16, 2, 0, in: la))
    let fridayNight = window(date(2026, 10, 16, 22, 0, in: la), date(2026, 10, 17, 6, 0, in: la))
    let afterCut = date(2026, 10, 16, 3, 0, in: la)
    #expect(!resolver.isExpired(change, at: afterCut))
    #expect(
      state(nights, 16, 3, 0, override: change) == .finished(window: short, next: fridayNight))
  }

  // MARK: Clock changes and calendars

  @Test func springForwardStartMovesToTheNextValidTime() throws {
    let resolver = ScheduleResolver(calendar: la)
    let day = LocalDay(year: 2026, month: 3, day: 8)
    let gapStart = try #require(
      resolver.window(on: day, schedule: schedule((2, 30), (10, 0), on: everyDay), override: nil))
    #expect(gapStart.start == date(2026, 3, 8, 3, 0, in: la))
    let spanning = try #require(
      resolver.window(on: day, schedule: schedule((1, 0), (5, 0), on: everyDay), override: nil))
    #expect(spanning.end.timeIntervalSince(spanning.start) == 3 * 3_600)
    #expect(
      resolver.window(on: day, schedule: schedule((2, 0), (2, 15), on: everyDay), override: nil)
        == nil)
  }

  @Test func fallBackUsesTheFirstRepeatedTime() throws {
    let resolver = ScheduleResolver(calendar: la)
    let repeated = try #require(
      resolver.window(
        on: LocalDay(year: 2026, month: 11, day: 1),
        schedule: schedule((1, 30), (5, 0), on: everyDay),
        override: nil))
    #expect(repeated.end.timeIntervalSince(repeated.start) == 4.5 * 3_600)
    let overnight = try #require(
      resolver.window(
        on: LocalDay(year: 2026, month: 10, day: 31),
        schedule: schedule((22, 0), (6, 0), on: everyDay),
        override: nil))
    #expect(overnight.end.timeIntervalSince(overnight.start) == 9 * 3_600)
  }

  @Test func southernHemisphereClockChanges() throws {
    let sydney = ScheduleResolver(calendar: calendar("Australia/Sydney"))
    let shift = schedule((2, 30), (4, 0), on: everyDay)
    let forward = try #require(
      sydney.window(on: LocalDay(year: 2026, month: 10, day: 4), schedule: shift, override: nil))
    #expect(forward.end.timeIntervalSince(forward.start) == 3_600)
    let back = try #require(
      sydney.window(on: LocalDay(year: 2026, month: 4, day: 5), schedule: shift, override: nil))
    #expect(back.end.timeIntervalSince(back.start) == 2.5 * 3_600)
  }

  @Test func timeZoneDecidesTheLocalDay() {
    let instant = date(2026, 10, 16, 14, 36, in: la)
    let tokyo = ScheduleResolver(calendar: calendar("Asia/Tokyo"))
    guard case .working = resolver.state(at: instant, schedule: .standard, override: nil) else {
      Issue.record("Expected working in Los Angeles")
      return
    }
    guard case .dayOff = tokyo.state(at: instant, schedule: .standard, override: nil) else {
      Issue.record("Expected Saturday off in Tokyo")
      return
    }
  }

  @Test func newYearAndLeapDay() {
    let nights = schedule((22, 0), (6, 0), on: everyDay)
    let newYear = resolver.state(
      at: date(2026, 12, 31, 23, 0, in: la), schedule: nights, override: nil)
    guard case .working(let active, _) = newYear else {
      Issue.record("Expected working")
      return
    }
    #expect(active.end == date(2027, 1, 1, 6, 0, in: la))
    let leap = resolver.state(
      at: date(2028, 2, 28, 20, 0, in: la), schedule: .standard, override: nil)
    guard case .finished(_, let next) = leap else {
      Issue.record("Expected finished")
      return
    }
    #expect(next.start == date(2028, 2, 29, 9, 0, in: la))
  }

  // MARK: Refresh scheduling

  @Test func refreshFollowsDisplayedMinutesAndBoundaries() {
    func refresh(_ day: Int, _ hour: Int, _ minute: Int, second: Int = 0) -> Date {
      resolver.nextRefresh(
        after: date(2026, 10, day, hour, minute, second: second, in: la), schedule: .standard,
        override: nil)
    }
    #expect(refresh(16, 14, 36) == date(2026, 10, 16, 14, 37, in: la))
    #expect(refresh(16, 14, 36, second: 30) == date(2026, 10, 16, 14, 37, in: la))
    #expect(refresh(16, 17, 59, second: 30) == date(2026, 10, 16, 18, 0, in: la))
    #expect(refresh(16, 7, 0) == date(2026, 10, 16, 9, 0, in: la))
    #expect(refresh(16, 20, 0) == date(2026, 10, 17, 0, 0, in: la))
    #expect(refresh(17, 12, 0) == date(2026, 10, 18, 0, 0, in: la))
  }
}
