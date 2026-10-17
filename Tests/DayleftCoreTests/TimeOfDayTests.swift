import DayleftCore
import Foundation
import Testing

struct TimeOfDayTests {
  @Test func validatesClockValues() {
    #expect(throws: ScheduleError.invalidTimeOfDay) { try TimeOfDay(hour: 24, minute: 0) }
    #expect(throws: ScheduleError.invalidTimeOfDay) { try TimeOfDay(hour: 9, minute: 60) }
    #expect(throws: ScheduleError.invalidTimeOfDay) { try TimeOfDay(minuteOfDay: -1) }
    #expect(time(23, 59).minuteOfDay == 1_439)
  }

  @Test func wrapsAndSnaps() {
    #expect(TimeOfDay(wrappingMinutes: -15) == time(23, 45))
    #expect(TimeOfDay(wrappingMinutes: 1_445) == time(0, 5))
    #expect(time(23, 58).snapped(to: 5) == time(0, 0))
    #expect(time(7, 2).snapped(to: 5) == time(7, 0))
    #expect(time(7, 3).snapped(to: 5) == time(7, 5))
    #expect(time(22, 0).minutes(until: time(6, 0)) == 480)
  }

  @Test func shiftHoursRequireStepAndMinimumLength() {
    #expect(throws: ScheduleError.shiftTooShort) {
      try ShiftHours(start: time(9, 0), cutoff: time(9, 0))
    }
    #expect(throws: ScheduleError.shiftTooShort) {
      try ShiftHours(start: time(9, 0), cutoff: time(9, 10))
    }
    #expect(throws: ScheduleError.offStep) {
      try ShiftHours(start: time(9, 1), cutoff: time(18, 0))
    }
    #expect(hours((23, 45), (0, 0)).durationMinutes == 15)
    #expect(hours((9, 5), (9, 0)).durationMinutes == 1_435)
  }

  @Test func overnightShiftsCrossMidnight() {
    #expect(hours((22, 0), (6, 0)).crossesMidnight)
    #expect(hours((18, 0), (0, 0)).crossesMidnight)
    #expect(!hours((9, 0), (18, 0)).crossesMidnight)
  }

  @Test func scheduleNeedsAWorkday() {
    #expect(throws: ScheduleError.noWorkdays) {
      try Schedule(hours: hours((9, 0), (18, 0)), workdays: [])
    }
    #expect(Schedule.standard.plans.count == 1)
    #expect(Schedule.standard.workdays == Weekday.workweek)
    #expect(Schedule.standard.sessions(on: .monday) == WorkSessions(hours((9, 0), (18, 0))))
  }

  @Test func codableRoundTripsAndRevalidates() throws {
    let value = DayOverride(
      day: LocalDay(year: 2026, month: 10, day: 16), change: .hours(hours((22, 0), (6, 0))))
    let data = try JSONEncoder().encode(value)
    #expect(try JSONDecoder().decode(DayOverride.self, from: data) == value)
    let restored = try JSONDecoder().decode(
      Schedule.self, from: JSONEncoder().encode(Schedule.standard))
    #expect(restored == .standard)

    let invalid = Data(#"{"start":540,"cutoff":540}"#.utf8)
    #expect(throws: ScheduleError.shiftTooShort) {
      try JSONDecoder().decode(ShiftHours.self, from: invalid)
    }
    #expect(throws: ScheduleError.noWorkdays) {
      try JSONDecoder().decode(
        Schedule.self,
        from: Data(
          #"{"plans":[{"id":"D4E7C3A0-5B1F-4C1E-9E0A-000000000009","name":"x","days":[],"sessions":[{"start":540,"cutoff":1080}]}]}"#
            .utf8))
    }
    #expect(throws: ScheduleError.sessionsOverlap) {
      try JSONDecoder().decode(
        WorkSessions.self,
        from: Data(#"[{"start":540,"cutoff":1080},{"start":600,"cutoff":700}]"#.utf8))
    }
  }
}
