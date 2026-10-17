import AppKit
import DayleftCore
import DayleftPresentation
import Foundation
import Observation

/// Recomputes the day state from the clock at each boundary and on system time changes.
@Observable
@MainActor
final class TimerModel {
  private(set) var presentation: DayPresentation
  private(set) var state: DayState

  let settings: SettingsStore
  @ObservationIgnored private var refreshTask: Task<Void, Never>?
  @ObservationIgnored private var observers: [NSObjectProtocol] = []

  init(settings: SettingsStore) {
    self.settings = settings
    let snapshot = Self.compute(settings: settings, now: Date())
    state = snapshot.state
    presentation = snapshot.presentation
    observeSystemChanges()
    refresh()
  }

  func updateSchedule(_ schedule: Schedule) {
    settings.setSchedule(schedule)
    refresh()
  }

  func updateOverride(_ override: DayOverride?) {
    settings.setOverride(override)
    refresh()
  }

  // MARK: Today-only changes

  /// The day the Today pane edits: the running shift's, otherwise today.
  var adjustableDay: LocalDay {
    let calendar = Calendar.autoupdatingCurrent
    if case .working(let window, _) = state {
      return LocalDay(containing: window.start, calendar: calendar)
    }
    return LocalDay(containing: Date(), calendar: calendar)
  }

  /// The existing change for the adjustable shift, if any.
  var adjustableChange: DayOverride.Change? {
    guard let override = settings.override, override.day == adjustableDay else { return nil }
    return override.change
  }

  /// Whether the regular schedule has work on the adjustable day, ignoring today-only changes.
  var adjustableDayIsWorkday: Bool {
    settings.schedule.workdays.contains(adjustableDay.weekday(in: .autoupdatingCurrent))
  }

  var nowTimeOfDay: TimeOfDay {
    let parts = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: Date())
    return TimeOfDay(wrappingMinutes: (parts.hour ?? 0) * 60 + (parts.minute ?? 0))
  }

  /// Whether applying these hours would end (or skip) the adjustable shift immediately.
  func endsShiftNow(_ hours: ShiftHours) -> Bool {
    let candidate = DayOverride(day: adjustableDay, change: .hours(hours))
    let resolver = ScheduleResolver(calendar: .autoupdatingCurrent)
    guard
      let window = resolver.window(
        on: candidate.day, schedule: settings.schedule, override: candidate)
    else { return false }
    return window.end <= Date()
  }

  func applyToday(_ change: DayOverride.Change) {
    updateOverride(DayOverride(day: adjustableDay, change: change))
  }

  /// Recompute now, discard an expired today-only change, and schedule the next refresh.
  func refresh() {
    let now = Date()
    let resolver = ScheduleResolver(calendar: .autoupdatingCurrent)
    if let override = settings.override, resolver.isExpired(override, at: now) {
      settings.setOverride(nil)
    }
    let snapshot = Self.compute(settings: settings, now: now)
    state = snapshot.state
    presentation = snapshot.presentation
    let next = resolver.nextRefresh(
      after: now, schedule: settings.schedule, override: settings.override)
    refreshTask?.cancel()
    refreshTask = Task { [weak self] in
      // A small margin lands just after the boundary instead of just before it.
      let delay = max(next.timeIntervalSinceNow, 0) + 0.05
      try? await Task.sleep(for: .seconds(delay))
      guard !Task.isCancelled else { return }
      self?.refresh()
    }
  }

  private static func compute(settings: SettingsStore, now: Date) -> (
    state: DayState, presentation: DayPresentation
  ) {
    let calendar = Calendar.autoupdatingCurrent
    let state = ScheduleResolver(calendar: calendar).state(
      at: now, schedule: settings.schedule, override: settings.override)
    let formatter = DayleftFormatter(calendar: calendar, locale: .autoupdatingCurrent)
    return (state, DayPresentation(state: state, now: now, formatter: formatter))
  }

  /// The model lives for the app's lifetime, so observers are never removed.
  private func observeSystemChanges() {
    let refreshOnMain: @Sendable (Notification) -> Void = { [weak self] _ in
      MainActor.assumeIsolated { self?.refresh() }
    }
    let workspace = NSWorkspace.shared.notificationCenter
    observers.append(
      workspace.addObserver(
        forName: NSWorkspace.didWakeNotification, object: nil, queue: .main, using: refreshOnMain))
    for name in [
      Notification.Name.NSSystemClockDidChange, .NSSystemTimeZoneDidChange,
      .NSCalendarDayChanged, NSLocale.currentLocaleDidChangeNotification,
    ] {
      observers.append(
        NotificationCenter.default.addObserver(
          forName: name, object: nil, queue: .main, using: refreshOnMain))
    }
  }
}
