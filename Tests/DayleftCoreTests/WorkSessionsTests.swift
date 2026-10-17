import DayleftCore
import Foundation
import Testing

/// Dates are in October 2026: Friday 16, Saturday 17, Monday 19, Wednesday 21.
struct WorkSessionsTests {
  private let la = calendar("America/Los_Angeles")
  private var resolver: ScheduleResolver { ScheduleResolver(calendar: la) }

  /// The example day: doctor in the morning, coding at night, breaks 11–13 and 17–20.
  private let split = sessions(((7, 0), (11, 0)), ((13, 0), (17, 0)), ((20, 0), (0, 0)))

  private func window(_ day: Int, _ start: (Int, Int), _ endDay: Int, _ end: (Int, Int))
    -> WorkWindow
  {
    try! WorkWindow(
      start: date(2026, 10, day, start.0, start.1, in: la),
      end: date(2026, 10, endDay, end.0, end.1, in: la))
  }

  private func state(_ schedule: Schedule, _ day: Int, _ hour: Int, _ minute: Int) -> DayState {
    resolver.state(at: date(2026, 10, day, hour, minute, in: la), schedule: schedule, override: nil)
  }

  private var splitSchedule: Schedule {
    try! Schedule(plans: [DayPlan(name: "Split", days: Weekday.workweek, sessions: split)])
  }

  // MARK: Rules

  @Test func sessionsAreSortedAndMayNotOverlapOrTouch() throws {
    let unsorted = try WorkSessions([hours((13, 0), (17, 0)), hours((7, 0), (11, 0))])
    #expect(unsorted.all.map(\.start) == [time(7, 0), time(13, 0)])
    #expect(throws: ScheduleError.sessionsOverlap) {
      try WorkSessions([hours((7, 0), (11, 0)), hours((10, 0), (12, 0))])
    }
    #expect(throws: ScheduleError.sessionsOverlap) {
      try WorkSessions([hours((7, 0), (11, 0)), hours((11, 0), (12, 0))])
    }
    #expect(throws: ScheduleError.noSessions) { try WorkSessions([]) }
    #expect(throws: ScheduleError.tooManySessions) {
      try WorkSessions([
        hours((1, 0), (2, 0)), hours((3, 0), (4, 0)), hours((5, 0), (6, 0)),
        hours((7, 0), (8, 0)), hours((9, 0), (10, 0)),
      ])
    }
  }

  @Test func onlyTheLastSessionCrossesMidnightAndTheDayFitsIn24Hours() {
    #expect(split.last.crossesMidnight)
    // Ending at 07:00 the next day would run into the 07:00 start.
    #expect(throws: ScheduleError.sessionsOverlap) {
      try WorkSessions([hours((7, 0), (11, 0)), hours((20, 0), (7, 0))])
    }
    #expect((try? WorkSessions([hours((7, 0), (11, 0)), hours((20, 0), (6, 55))])) != nil)
  }

  @Test func addsIntoTheLongestBreakAndRemoves() throws {
    let day = sessions(((9, 0), (12, 0)), ((13, 0), (18, 0)))
    let added = try #require(day.addingSession())
    // The longest break is 18:00–09:00; an hour is centred in it.
    #expect(added.sessions.all[added.index] == hours((1, 0), (2, 0)))
    #expect(added.index == 0)
    let removed = try #require(added.sessions.removing(at: added.index))
    #expect(removed == day)
    #expect(WorkSessions(hours((9, 0), (17, 0))).removing(at: 0) == nil)
    #expect(split.totalMinutes == 12 * 60)
  }

  @Test func dayPlansOwnDistinctDays() throws {
    let weekend = DayPlan(
      name: "Weekend", days: [.saturday, .sunday], sessions: sessions(((10, 0), (14, 0))))
    let schedule = try Schedule(plans: [Schedule.standard.plans[0], weekend])
    #expect(schedule.workdays == Set(Weekday.allCases))
    #expect(schedule.sessions(on: .sunday) == weekend.sessions)
    #expect(throws: ScheduleError.overlappingDays) {
      try Schedule(plans: [
        Schedule.standard.plans[0],
        DayPlan(name: "Fri", days: [.friday], sessions: weekend.sessions),
      ])
    }
    // Moving Friday to the weekend plan takes it from Weekdays.
    let moved = try schedule.assigning(.friday, to: weekend.id)
    #expect(moved.plan(on: .friday)?.id == weekend.id)
    #expect(moved.plans[0].days == [.monday, .tuesday, .wednesday, .thursday])
    // A Wednesday off is simply a day in no plan.
    let noWednesday = try Schedule(
      hours: hours((9, 0), (17, 0)), workdays: Weekday.workweek.subtracting([.wednesday]))
    guard
      case .dayOff = resolver.state(
        at: date(2026, 10, 21, 12, 0, in: la), schedule: noWednesday, override: nil)
    else {
      Issue.record("Expected Wednesday off")
      return
    }
    #expect(throws: ScheduleError.noWorkdays) {
      try Schedule(plans: [DayPlan(name: "Empty", days: [], sessions: weekend.sessions)])
    }
  }

  // MARK: States

  @Test func breaksSitBetweenTodaysSessions() {
    let morning = window(16, (7, 0), 16, (11, 0))
    let afternoon = window(16, (13, 0), 16, (17, 0))
    let night = window(16, (20, 0), 17, (0, 0))
    #expect(state(splitSchedule, 16, 6, 0) == .beforeStart(next: morning))
    #expect(state(splitSchedule, 16, 12, 0) == .onBreak(previous: morning, next: afternoon))
    #expect(state(splitSchedule, 16, 18, 0) == .onBreak(previous: afternoon, next: night))
    guard case .working(let active, let snapshot) = state(splitSchedule, 16, 21, 30) else {
      Issue.record("Expected working")
      return
    }
    #expect(active == night)
    #expect(snapshot.remainingWholeMinutes == 150)
    // The last session ends at midnight, so Friday is done until Monday.
    #expect(
      state(splitSchedule, 17, 8, 0) == .dayOff(next: window(19, (7, 0), 19, (11, 0))))
  }

  @Test func yesterdaysNightSessionEndingIsNotABreak() {
    let nights = try! Schedule(
      plans: [
        DayPlan(
          name: "Nights", days: Set(Weekday.allCases),
          sessions: sessions(((1, 0), (3, 0)), ((22, 0), (0, 30))))
      ])
    // 00:15 on Saturday: Friday's 22:00 session is still running.
    guard case .working(let active, _) = state(nights, 17, 0, 15) else {
      Issue.record("Expected working")
      return
    }
    #expect(active == window(16, (22, 0), 17, (0, 30)))
    // 00:45: Friday's work ended today, so Saturday shows Done until its 01:00 start, as for
    // any overnight shift; a break is only between sessions of the same day.
    #expect(
      state(nights, 17, 0, 45)
        == .finished(window: window(16, (22, 0), 17, (0, 30)), next: window(17, (1, 0), 17, (3, 0)))
    )
  }

  @Test func timelineAndRemainingWorkCoverTheWholeDay() {
    let now = date(2026, 10, 16, 12, 0, in: la)
    let state = resolver.state(at: now, schedule: splitSchedule, override: nil)
    let timeline = resolver.timeline(for: state, schedule: splitSchedule, override: nil)
    #expect(timeline.count == 3)
    #expect(resolver.remainingWork(in: timeline, at: now) == 8 * 3_600)
    guard
      case .dayOff = resolver.state(
        at: date(2026, 10, 17, 12, 0, in: la), schedule: splitSchedule, override: nil)
    else {
      Issue.record("Expected day off")
      return
    }
  }

  @Test func todaysSessionsReplaceTheDayPlan() {
    let change = DayOverride(
      day: LocalDay(year: 2026, month: 10, day: 16),
      change: .sessions(sessions(((8, 0), (10, 0)), ((15, 0), (16, 0)))))
    let first = window(16, (8, 0), 16, (10, 0))
    let second = window(16, (15, 0), 16, (16, 0))
    #expect(
      resolver.state(
        at: date(2026, 10, 16, 12, 0, in: la), schedule: .standard, override: change)
        == .onBreak(previous: first, next: second))
  }

  @Test func breaksRefreshEachDisplayedMinute() {
    let refresh = resolver.nextRefresh(
      after: date(2026, 10, 16, 12, 0, second: 30, in: la), schedule: splitSchedule,
      override: nil)
    #expect(refresh == date(2026, 10, 16, 12, 1, in: la))
  }

  // MARK: Dial

  @Test func movingAHandleStopsAtItsNeighbours() {
    // The afternoon start cannot move into the morning session or its break.
    let early = DialGeometry.moving(.start, ofSession: 1, in: split, to: time(10, 0))
    #expect(early.sessions.all[1] == hours((11, 5), (17, 0)))
    // The morning cutoff stops a break before the afternoon start.
    let late = DialGeometry.moving(.cutoff, ofSession: 0, in: split, to: time(15, 0))
    #expect(late.sessions.all[0] == hours((7, 0), (12, 55)))
    // A start moved past midnight becomes the first session.
    let wrapped = DialGeometry.moving(
      .start, ofSession: 0, in: sessions(((1, 0), (3, 0)), ((20, 0), (22, 0))), to: time(23, 0))
    #expect(wrapped.index == 1)
    #expect(wrapped.sessions.all[1] == hours((23, 0), (3, 0)))
    let nearest = DialGeometry.nearestHandle(to: DialGeometry.angle(for: time(13, 10)), in: split)
    #expect(nearest.index == 1)
    #expect(nearest.handle == .start)
    #expect(DialGeometry.session(at: DialGeometry.angle(for: time(22, 0)), in: split) == 2)
    #expect(DialGeometry.session(at: DialGeometry.angle(for: time(12, 0)), in: split) == nil)
  }
}
