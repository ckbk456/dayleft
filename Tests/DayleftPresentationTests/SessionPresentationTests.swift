import DayleftCore
import DayleftPresentation
import Foundation
import Testing

/// Friday 16 October 2026 with sessions 07–11, 13–17, and 20–00.
struct SessionPresentationTests {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
    return calendar
  }()

  private var formatter: DayleftFormatter {
    DayleftFormatter(calendar: calendar, locale: Locale(identifier: "en_GB"))
  }

  private func time(_ hour: Int, _ minute: Int = 0) -> TimeOfDay {
    try! TimeOfDay(hour: hour, minute: minute)
  }

  private var split: WorkSessions {
    try! WorkSessions([
      ShiftHours(start: time(7), cutoff: time(11)), ShiftHours(start: time(13), cutoff: time(17)),
      ShiftHours(start: time(20), cutoff: time(0)),
    ])
  }

  private var schedule: Schedule {
    try! Schedule(plans: [DayPlan(name: "Split", days: Weekday.workweek, sessions: split)])
  }

  private func present(_ hour: Int, _ minute: Int = 0) -> DayPresentation {
    let now = calendar.date(
      from: DateComponents(year: 2026, month: 10, day: 16, hour: hour, minute: minute))!
    let resolver = ScheduleResolver(calendar: calendar)
    let state = resolver.state(at: now, schedule: schedule, override: nil)
    let timeline = resolver.timeline(for: state, schedule: schedule, override: nil)
    return DayPresentation(state: state, now: now, formatter: formatter, timeline: timeline)
  }

  @Test func workingCountsDownTheSessionAndNotesTheDay() {
    let view = present(9, 30)
    #expect(view.menuBarText == "1h 30m")
    #expect(view.detail == "left in this session, until 11:00")
    #expect(view.dayNote == "9h 30m of work left today, in 3 sessions")
    #expect(
      view.accessibilityLabel
        == "Dayleft, 1 hour 30 minutes left in this session, until 11:00")
  }

  @Test func theLastSessionReadsLikeASingleShift() {
    let view = present(21)
    #expect(view.detail == "left until 00:00")
    #expect(view.dayNote == nil)
  }

  @Test func breaksShowTheNextStart() {
    let view = present(11, 40)
    #expect(view.menuBarText == "13:00")
    #expect(view.eyebrow == "BREAK")
    #expect(view.detail == "next session in 1h 20m")
    #expect(view.dayNote == "8h 0m of work left today, in 2 sessions")
    #expect(view.accessibilityLabel == "Dayleft, on a break until 13:00")
  }

  @Test func progressDrawsSessionsWithGaps() throws {
    let progress = try #require(present(12).progress)
    #expect(progress.startText == "07:00")
    #expect(progress.endText == "00:00")
    #expect(progress.segments.count == 3)
    // 17 hours from 07:00 to midnight; the afternoon session sits at 6/17...10/17.
    #expect(abs(progress.segments[1].start - 6.0 / 17) < 0.000_001)
    #expect(abs(progress.segments[1].end - 10.0 / 17) < 0.000_001)
    #expect(abs(progress.nowFraction - 5.0 / 17) < 0.000_001)
    // 4 of 12 work hours are done.
    #expect(abs(progress.elapsedFraction - 1.0 / 3) < 0.000_001)
    #expect(progress.accessibilityValue == "33 percent elapsed")
  }

  @Test func summarizesSessions() {
    #expect(formatter.sessionsSummary(split) == "3 sessions, 07:00 – 00:00")
    #expect(
      formatter.sessionsSummary(WorkSessions(try! ShiftHours(start: time(9), cutoff: time(18))))
        == "09:00 – 18:00")
  }

  @Test func migratesSingleHoursSettings() throws {
    let legacy = Data(
      #"""
      {"schedule":{"hours":{"start":390,"cutoff":1015},"workdays":[2,3,5]},
       "override":{"day":{"year":2026,"month":10,"day":17},"change":{"hours":{"_0":{"start":600,"cutoff":660}}}}}
      """#.utf8)
    let document = SettingsDocument.decode(nil, legacy: legacy)
    #expect(document.schedule.plans.count == 1)
    #expect(document.schedule.workdays == [.monday, .tuesday, .thursday])
    #expect(
      document.schedule.sessions(on: .monday)
        == WorkSessions(try ShiftHours(start: time(6, 30), cutoff: time(16, 55))))
    #expect(
      document.override
        == DayOverride(
          day: LocalDay(year: 2026, month: 10, day: 17),
          change: .hours(try ShiftHours(start: time(10), cutoff: time(11)))))
    let dayOff = Data(
      #"""
      {"schedule":{"hours":{"start":540,"cutoff":1080},"workdays":[2]},
       "override":{"day":{"year":2026,"month":10,"day":19},"change":{"dayOff":{}}}}
      """#.utf8)
    #expect(SettingsDocument.decode(nil, legacy: dayOff).override?.change == .dayOff)
    // Current settings win over legacy ones; round trips keep plans and sessions.
    let current = SettingsDocument(schedule: schedule)
    #expect(SettingsDocument.decode(current.encoded(), legacy: legacy) == current)
  }
}
