import DayleftCore
import Foundation

func calendar(_ identifier: String) -> Calendar {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = TimeZone(identifier: identifier)!
  return calendar
}

func date(
  _ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, second: Int = 0,
  in calendar: Calendar
) -> Date {
  calendar.date(
    from: DateComponents(
      year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
}

func time(_ hour: Int, _ minute: Int) -> TimeOfDay {
  try! TimeOfDay(hour: hour, minute: minute)
}

func hours(_ start: (Int, Int), _ cutoff: (Int, Int)) -> ShiftHours {
  try! ShiftHours(start: time(start.0, start.1), cutoff: time(cutoff.0, cutoff.1))
}

func schedule(
  _ start: (Int, Int), _ cutoff: (Int, Int), on workdays: Set<Weekday> = Weekday.workweek
) -> Schedule {
  try! Schedule(hours: hours(start, cutoff), workdays: workdays)
}
