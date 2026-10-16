import DayleftCore
import DayleftPresentation
import Foundation
import Testing

/// October 2026: Friday 16, Saturday 17, Monday 19.
struct DayPresentationTests {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
    return calendar
  }()

  private func at(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
    calendar.date(
      from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
  }

  private func present(_ now: Date, locale: String = "en_US", override: DayOverride? = nil)
    -> DayPresentation
  {
    let state = ScheduleResolver(calendar: calendar).state(
      at: now, schedule: .standard, override: override)
    return DayPresentation(
      state: state, now: now,
      formatter: DayleftFormatter(calendar: calendar, locale: Locale(identifier: locale)))
  }

  @Test func workingMatchesTheApprovedDesign() throws {
    let view = present(at(16, 14, 36), locale: "en_GB")
    #expect(view.menuBarText == "3h 24m")
    #expect(view.headline == "3h 24m")
    #expect(view.detail == "left until 18:00")
    let progress = try #require(view.progress)
    #expect(progress.startText == "09:00")
    #expect(progress.endText == "18:00")
    #expect(progress.accessibilityValue == "62 percent elapsed")
    #expect(view.accessibilityLabel == "Dayleft, 3 hours 24 minutes left until 18:00")
  }

  @Test func followsTwelveHourLocales() {
    let view = present(at(16, 14, 36))
    #expect(view.detail.hasPrefix("left until 6:00"))
    #expect(view.detail.hasSuffix("PM"))
  }

  @Test func beforeStartShowsTheStartTime() {
    let view = present(at(16, 7, 0), locale: "en_GB")
    #expect(view.menuBarText == "09:00")
    #expect(view.detail == "starts today, ends 18:00")
    #expect(view.progress?.elapsedFraction == 0)
  }

  @Test func finishedAndDayOffNameTheNextStart() {
    let done = present(at(16, 20, 0), locale: "en_GB")
    #expect(done.menuBarText == "Done")
    #expect(done.detail == "Next start Monday 09:00")
    #expect(done.progress?.elapsedFraction == 1)
    let off = present(at(17, 12, 0), locale: "en_GB")
    #expect(off.menuBarText == "Off")
    #expect(off.progress == nil)
    let thursday = present(at(15, 20, 0), locale: "en_GB")
    #expect(thursday.detail == "Next start tomorrow 09:00")
  }

  @Test func shortDurations() {
    let formatter = DayleftFormatter(calendar: calendar, locale: Locale(identifier: "en_US"))
    #expect(formatter.duration(minutes: 540) == "9h 0m")
    #expect(formatter.duration(minutes: 45) == "45m")
    #expect(formatter.spokenDuration(minutes: 61) == "1 hour 1 minute")
    #expect(formatter.spokenDuration(minutes: 120) == "2 hours")
    #expect(formatter.time(try! TimeOfDay(hour: 22, minute: 5)).hasPrefix("10:05"))
  }

  @Test func dialHourLabelsFollowTheLocale() {
    let british = DayleftFormatter(calendar: calendar, locale: Locale(identifier: "en_GB"))
    #expect(british.hourLabel(6) == "06")
    let american = DayleftFormatter(calendar: calendar, locale: Locale(identifier: "en_US"))
    #expect(american.hourLabel(18).hasPrefix("6"))
    #expect(american.hourLabel(18).hasSuffix("PM"))
  }

  @Test func summarizesWorkdays() {
    var mondayFirst = calendar
    mondayFirst.firstWeekday = 2
    let formatter = DayleftFormatter(calendar: mondayFirst, locale: Locale(identifier: "en_GB"))
    #expect(formatter.orderedWeekdays.first == .monday)
    #expect(formatter.orderedWeekdays.last == .sunday)
    #expect(formatter.workdaysSummary(Weekday.workweek) == "Weekdays")
    #expect(formatter.workdaysSummary(Set(Weekday.allCases)) == "Every day")
    #expect(formatter.workdaysSummary([.sunday, .tuesday]) == "Tue, Sun")
  }

  @Test func settingsFallBackToDefaults() throws {
    #expect(SettingsDocument.decode(nil) == SettingsDocument())
    #expect(SettingsDocument.decode(Data("not json".utf8)).schedule == .standard)
    let saved = SettingsDocument(
      schedule: try Schedule(
        hours: ShiftHours(
          start: TimeOfDay(hour: 22, minute: 0), cutoff: TimeOfDay(hour: 6, minute: 0)),
        workdays: [.saturday]),
      override: DayOverride(day: LocalDay(year: 2026, month: 10, day: 17), change: .dayOff))
    #expect(SettingsDocument.decode(saved.encoded()) == saved)
  }
}
