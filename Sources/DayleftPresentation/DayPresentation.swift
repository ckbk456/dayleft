import DayleftCore
import Foundation

/// Text and progress for the menu bar and panel, derived from a `DayState`.
public struct DayPresentation: Equatable, Sendable {
  /// The day's work on one bar: sessions as segments, breaks as gaps.
  public struct Progress: Equatable, Sendable {
    /// A session's position along the bar, as fractions from the first start to the last end.
    public struct Segment: Equatable, Sendable {
      public let start: Double
      public let end: Double
    }

    public let segments: [Segment]
    /// The current time's position along the bar, clamped to 0...1.
    public let nowFraction: Double
    /// Share of the day's work time already done, clamped to 0...1.
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
  /// Work left across the day's remaining sessions, when more than one session is involved.
  public let dayNote: String?
  public let progress: Progress?

  /// - Parameter timeline: the day's windows (`ScheduleResolver.timeline`); when empty, the
  ///   state's own window is the whole day.
  public init(
    state: DayState, now: Date, formatter: DayleftFormatter, timeline: [WorkWindow] = []
  ) {
    switch state {
    case .working(let window, let snapshot):
      let day = timeline.isEmpty ? [window] : timeline
      let minutes = snapshot.remainingWholeMinutes
      let end = formatter.time(window.end)
      let later = day.filter { $0.start >= window.end }
      menuBarText = formatter.duration(minutes: minutes)
      eyebrow = "WORKDAY"
      headline = menuBarText
      if later.isEmpty {
        detail = "left until \(end)"
        accessibilityLabel =
          "Dayleft, \(formatter.spokenDuration(minutes: minutes)) left until \(end)"
        dayNote = nil
      } else {
        detail = "left in this session, until \(end)"
        accessibilityLabel =
          "Dayleft, \(formatter.spokenDuration(minutes: minutes)) left in this session, until \(end)"
        dayNote = Self.dayNote(day, now: now, formatter: formatter)
      }
      progress = Self.progress(day, now: now, formatter: formatter)
    case .onBreak(let previous, let next):
      let day = timeline.isEmpty ? [previous, next] : timeline
      let start = formatter.time(next.start)
      let breakMinutes = Int((next.start.timeIntervalSince(now) / 60).rounded(.up))
      menuBarText = start
      accessibilityLabel = "Dayleft, on a break until \(start)"
      eyebrow = "BREAK"
      headline = start
      detail = "next session in \(formatter.duration(minutes: max(breakMinutes, 0)))"
      dayNote = Self.dayNote(day, now: now, formatter: formatter)
      progress = Self.progress(day, now: now, formatter: formatter)
    case .beforeStart(let next):
      let day = timeline.isEmpty ? [next] : timeline
      let start = formatter.time(next.start)
      menuBarText = start
      accessibilityLabel = "Dayleft, workday starts at \(start)"
      eyebrow = "WORKDAY"
      headline = start
      detail = "starts today, ends \(formatter.relativeTime(day.last!.end, now: now))"
      dayNote = day.count > 1 ? Self.dayNote(day, now: now, formatter: formatter) : nil
      progress = Self.progress(day, now: now, formatter: formatter)
    case .finished(let window, let next):
      let day = timeline.isEmpty ? [window] : timeline
      let nextText = formatter.relativeTime(next.start, now: now)
      menuBarText = "Done"
      accessibilityLabel = "Dayleft, done for today. Next start \(nextText)"
      eyebrow = "WORKDAY"
      headline = "Done"
      detail = "Next start \(nextText)"
      dayNote = nil
      progress = Self.progress(day, now: now, formatter: formatter)
    case .dayOff(let next):
      let nextText = formatter.relativeTime(next.start, now: now)
      menuBarText = "Off"
      accessibilityLabel = "Dayleft, day off. Next start \(nextText)"
      eyebrow = "TODAY"
      headline = "Off"
      detail = "Next start \(nextText)"
      dayNote = nil
      progress = nil
    }
  }

  /// `6h 10m of work left today, in 3 sessions`.
  private static func dayNote(_ day: [WorkWindow], now: Date, formatter: DayleftFormatter)
    -> String
  {
    let remaining = day.reduce(0.0) { $0 + $1.snapshot(at: now).remaining }
    let minutes = Int((remaining / 60).rounded(.up))
    let sessions = day.filter { $0.end > now }.count
    let sessionText = sessions == 1 ? "1 session" : "\(sessions) sessions"
    return "\(formatter.duration(minutes: minutes)) of work left today, in \(sessionText)"
  }

  private static func progress(_ day: [WorkWindow], now: Date, formatter: DayleftFormatter)
    -> Progress
  {
    let first = day.first!.start
    let last = day.last!.end
    let span = last.timeIntervalSince(first)
    let segments = day.map {
      Progress.Segment(
        start: $0.start.timeIntervalSince(first) / span, end: $0.end.timeIntervalSince(first) / span
      )
    }
    let total = day.reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }
    let done = day.reduce(0.0) {
      $0 + $1.end.timeIntervalSince($1.start) * $1.snapshot(at: now).elapsedFraction
    }
    let elapsed = min(max(done / total, 0), 1)
    let nowFraction = min(max(now.timeIntervalSince(first) / span, 0), 1)
    return Progress(
      segments: segments, nowFraction: nowFraction.isFinite ? nowFraction : 0,
      elapsedFraction: elapsed.isFinite ? elapsed : 0, startText: formatter.time(first),
      endText: formatter.time(last),
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

  /// `09:00 – 18:00`.
  public func range(_ hours: ShiftHours) -> String {
    "\(time(hours.start)) – \(time(hours.cutoff))"
  }

  /// `09:00 – 18:00`, or `3 sessions, 07:00 – 00:00` from the first start to the last cutoff.
  public func sessionsSummary(_ sessions: WorkSessions) -> String {
    if sessions.count == 1 { return range(sessions.first) }
    return
      "\(sessions.count) sessions, \(time(sessions.first.start)) – \(time(sessions.last.cutoff))"
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
