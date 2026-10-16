import DayleftCore
import Foundation

/// Text and progress for the menu bar and panel, derived from a `DayState`.
public struct DayPresentation: Equatable, Sendable {
  public struct Progress: Equatable, Sendable {
    public let elapsedFraction: Double
    public let startText: String
    public let endText: String
    public let accessibilityValue: String
  }

  public let menuBarText: String
  public let accessibilityLabel: String
  public let eyebrow: String
  public let headline: String
  public let detail: String
  public let progress: Progress?

  public init(state: DayState, now: Date, formatter: DayleftFormatter) {
    switch state {
    case .working(let window, let snapshot):
      let minutes = snapshot.remainingWholeMinutes
      let end = formatter.time(window.end)
      menuBarText = formatter.duration(minutes: minutes)
      accessibilityLabel =
        "Dayleft, \(formatter.spokenDuration(minutes: minutes)) left until \(end)"
      eyebrow = "WORKDAY"
      headline = menuBarText
      detail = "left until \(end)"
      progress = Self.progress(window, elapsed: snapshot.elapsedFraction, formatter: formatter)
    case .beforeStart(let next):
      let start = formatter.time(next.start)
      menuBarText = start
      accessibilityLabel = "Dayleft, workday starts at \(start)"
      eyebrow = "WORKDAY"
      headline = start
      detail = "starts today, ends \(formatter.relativeTime(next.end, now: now))"
      progress = Self.progress(next, elapsed: 0, formatter: formatter)
    case .finished(let window, let next):
      let nextText = formatter.relativeTime(next.start, now: now)
      menuBarText = "Done"
      accessibilityLabel = "Dayleft, done for today. Next start \(nextText)"
      eyebrow = "WORKDAY"
      headline = "Done"
      detail = "Next start \(nextText)"
      progress = Self.progress(window, elapsed: 1, formatter: formatter)
    case .dayOff(let next):
      let nextText = formatter.relativeTime(next.start, now: now)
      menuBarText = "Off"
      accessibilityLabel = "Dayleft, day off. Next start \(nextText)"
      eyebrow = "TODAY"
      headline = "Off"
      detail = "Next start \(nextText)"
      progress = nil
    }
  }

  private static func progress(_ window: WorkWindow, elapsed: Double, formatter: DayleftFormatter)
    -> Progress
  {
    Progress(
      elapsedFraction: elapsed, startText: formatter.time(window.start),
      endText: formatter.time(window.end),
      accessibilityValue: "\(Int((elapsed * 100).rounded(.down))) percent elapsed")
  }
}

/// Locale-aware formatting. The locale decides 12- or 24-hour time.
public struct DayleftFormatter: Sendable {
  public let calendar: Calendar
  public let locale: Locale

  public init(calendar: Calendar, locale: Locale) {
    self.calendar = calendar
    self.locale = locale
  }

  /// Compact duration, e.g. `3h 24m`, `9h 0m` or `45m`.
  public func duration(minutes: Int) -> String {
    minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
  }

  public func spokenDuration(minutes: Int) -> String {
    let hours = minutes / 60
    let rest = minutes % 60
    let hourText = hours == 1 ? "1 hour" : "\(hours) hours"
    let minuteText = rest == 1 ? "1 minute" : "\(rest) minutes"
    if hours == 0 { return minuteText }
    return rest == 0 ? hourText : "\(hourText) \(minuteText)"
  }

  public func time(_ date: Date) -> String {
    date.formatted(style.hour().minute())
  }

  public func time(_ time: TimeOfDay) -> String {
    let reference = calendar.date(
      from: DateComponents(year: 2001, month: 1, day: 1, hour: time.hour, minute: time.minute))!
    return self.time(reference)
  }

  /// Weekdays in the calendar's display order, starting from its first weekday.
  public var orderedWeekdays: [Weekday] {
    (0..<7).map { Weekday(rawValue: (calendar.firstWeekday - 1 + $0) % 7 + 1)! }
  }

  public func shortName(_ weekday: Weekday) -> String {
    var localized = calendar
    localized.locale = locale
    return localized.shortWeekdaySymbols[weekday.rawValue - 1]
  }

  /// `Every day`, `Weekdays`, `Weekends`, or the short names in display order.
  public func workdaysSummary(_ workdays: Set<Weekday>) -> String {
    if workdays.count == 7 { return "Every day" }
    if workdays == Weekday.workweek { return "Weekdays" }
    if workdays == [.saturday, .sunday] { return "Weekends" }
    return orderedWeekdays.filter(workdays.contains).map(shortName).joined(separator: ", ")
  }

  /// Hour-only label for dial marks, e.g. `6 AM` or `06`.
  public func hourLabel(_ hour: Int) -> String {
    let reference = calendar.date(
      from: DateComponents(year: 2001, month: 1, day: 1, hour: hour, minute: 0))!
    return reference.formatted(style.hour())
  }

  /// `9:00 AM`, `tomorrow 9:00 AM`, or `Monday 9:00 AM` relative to `now`.
  public func relativeTime(_ date: Date, now: Date) -> String {
    let today = LocalDay(containing: now, calendar: calendar)
    let day = LocalDay(containing: date, calendar: calendar)
    if day == today { return time(date) }
    if day == today.adding(days: 1, calendar: calendar) { return "tomorrow \(time(date))" }
    return "\(date.formatted(style.weekday(.wide))) \(time(date))"
  }

  private var style: Date.FormatStyle {
    Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
  }
}
