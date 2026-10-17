import DayleftCore
import DayleftPresentation
import SwiftUI

/// A 24-hour dial for choosing a shift's start and cutoff. Midnight is at the top.
///
/// The chosen times are the large labels above the dial, each marked with its handle's icon; the
/// shift length is secondary text below it, so nothing big changes except the time being moved.
/// Drag anywhere to move the nearest handle, focus a handle and use the arrow keys (Shift for an
/// hour), adjust handles with VoiceOver, or click a time to type it exactly.
struct DayDial: View {
  @Binding var hours: ShiftHours
  /// Current time of day, drawn as a marker; the part of the shift before it is shown elapsed.
  var now: TimeOfDay?
  /// Optional message under the dial, e.g. that a change ends today's shift now.
  var note: String?
  let formatter: DayleftFormatter

  @State private var dragging: DialGeometry.Handle?
  @State private var typing: DialGeometry.Handle?
  @FocusState private var focusedHandle: DialGeometry.Handle?

  private let ringWidth: CGFloat = 18
  private let handleSize: CGFloat = 28

  var body: some View {
    VStack(spacing: 16) {
      HStack(alignment: .bottom) {
        endpoint(.start)
        Spacer()
        Image(systemName: "arrow.right")
          .font(.title3)
          .foregroundStyle(.tertiary)
          .padding(.bottom, 8)
          .accessibilityHidden(true)
        Spacer()
        endpoint(.cutoff)
      }

      GeometryReader { proxy in
        let side = min(proxy.size.width, proxy.size.height)
        let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
        let radius = side / 2 - handleSize / 2 - 6
        ZStack {
          ring(center: center, radius: radius)
          marks(center: center, radius: radius)
          if let now {
            marker(at: now, center: center, radius: radius)
          }
          handle(.start, center: center, radius: radius)
          handle(.cutoff, center: center, radius: radius)
        }
        .contentShape(Rectangle())
        .gesture(dragGesture(center: center))
      }
      .aspectRatio(1, contentMode: .fit)
      .accessibilityElement(children: .contain)
      .accessibilityLabel(
        "Work hours dial, \(formatter.spokenDuration(minutes: hours.durationMinutes))")

      Text(lengthText)
        .font(.callout)
        .foregroundStyle(.secondary)
        .monospacedDigit()
        .accessibilityHidden(true)

      if let note {
        Label(note, systemImage: "exclamationmark.circle")
          .font(.callout)
          .foregroundStyle(.orange)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  /// `8h 0m shift` or `8h 0m shift, ends the next day`.
  private var lengthText: String {
    let length = "\(formatter.duration(minutes: hours.durationMinutes)) shift"
    return hours.crossesMidnight ? "\(length), ends the next day" : length
  }

  // MARK: Chosen times

  /// The large time for one handle; it highlights while that handle moves and opens a field to
  /// type an exact time when clicked.
  private func endpoint(_ handle: DialGeometry.Handle) -> some View {
    let active = dragging == handle || focusedHandle == handle || typing == handle
    let alignment: HorizontalAlignment = handle == .start ? .leading : .trailing
    return VStack(alignment: alignment, spacing: 2) {
      Label(title(handle), systemImage: symbol(handle))
        .font(.caption.weight(.semibold))
        .textCase(.uppercase)
        .foregroundStyle(active ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
      Button {
        typing = handle
      } label: {
        Text(formatter.time(time(handle)))
          .font(.system(size: 30, weight: .semibold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(.primary)
          .contentTransition(.numericText())
      }
      .buttonStyle(.plain)
      .help("Click to type an exact \(title(handle).lowercased()) time")
      .popover(isPresented: typingBinding(handle), arrowEdge: .bottom) {
        DatePicker(
          title(handle), selection: dateBinding(for: handle), displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.field)
        .padding(12)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(title(handle)) \(formatter.time(time(handle)))")
    .accessibilityHint("Activate to type a time")
  }

  private func title(_ handle: DialGeometry.Handle) -> String {
    handle == .start ? "Start" : "Cutoff"
  }

  private func symbol(_ handle: DialGeometry.Handle) -> String {
    handle == .start ? "play.fill" : "stop.fill"
  }

  private func time(_ handle: DialGeometry.Handle) -> TimeOfDay {
    handle == .start ? hours.start : hours.cutoff
  }

  private func typingBinding(_ handle: DialGeometry.Handle) -> Binding<Bool> {
    Binding(get: { typing == handle }, set: { if !$0, typing == handle { typing = nil } })
  }

  // MARK: Drawing

  private func ring(center: CGPoint, radius: CGFloat) -> some View {
    let arc = DialGeometry.arc(for: hours)
    let elapsed = elapsedSweep
    return ZStack {
      Circle()
        .stroke(.quaternary, lineWidth: ringWidth)
        .frame(width: radius * 2, height: radius * 2)
        .position(center)
      // Like the panel's bar: elapsed work is solid, the rest of the shift is lighter.
      ArcShape(startDegrees: arc.start, sweepDegrees: arc.sweep)
        .stroke(
          Color.orange.opacity(elapsed > 0 ? 0.45 : 1),
          style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
        )
        .frame(width: radius * 2, height: radius * 2)
        .position(center)
      if elapsed > 0 {
        ArcShape(startDegrees: arc.start, sweepDegrees: elapsed)
          .stroke(Color.orange, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
          .frame(width: radius * 2, height: radius * 2)
          .position(center)
      }
    }
    .accessibilityHidden(true)
  }

  private func marks(center: CGPoint, radius: CGFloat) -> some View {
    ZStack {
      ForEach(0..<24, id: \.self) { hour in
        let major = hour % 6 == 0
        Capsule()
          .fill(major ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tertiary))
          .frame(width: major ? 2 : 1, height: major ? 8 : 5)
          .offset(y: -(radius - ringWidth / 2 - 9))
          .rotationEffect(.degrees(Double(hour) * 15))
          .position(center)
      }
      ForEach(Array(stride(from: 0, to: 24, by: 3)), id: \.self) { hour in
        Text(formatter.hourLabel(hour))
          .font(hour % 6 == 0 ? .caption.weight(.medium) : .caption2)
          .foregroundStyle(hour % 6 == 0 ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tertiary))
          .monospacedDigit()
          .position(point(atDegrees: Double(hour) * 15, center: center, radius: radius - 38))
      }
    }
    .accessibilityHidden(true)
  }

  private func marker(at time: TimeOfDay, center: CGPoint, radius: CGFloat) -> some View {
    Circle()
      .fill(.primary)
      .frame(width: 6, height: 6)
      .position(
        point(
          atDegrees: DialGeometry.angle(for: time), center: center,
          radius: radius + ringWidth / 2 + 7)
      )
      .accessibilityHidden(true)
  }

  private func handle(_ handle: DialGeometry.Handle, center: CGPoint, radius: CGFloat) -> some View
  {
    let time = handle == .start ? hours.start : hours.cutoff
    let focused = focusedHandle == handle
    let active = dragging == handle || focused
    return Circle()
      .fill(handle == .start ? Color.white : Color.orange)
      .overlay(Circle().stroke(Color.orange, lineWidth: 2.5))
      .overlay(
        Image(systemName: symbol(handle))
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(handle == .start ? Color.orange : Color.white)
      )
      .scaleEffect(active ? 1.12 : 1)
      .animation(.snappy(duration: 0.15), value: active)
      .overlay(
        Circle()
          .stroke(Color.accentColor, lineWidth: 3)
          .padding(-5)
          .opacity(focused && dragging == nil ? 1 : 0)
      )
      .shadow(radius: 1.5)
      .frame(width: handleSize, height: handleSize)
      .position(point(atDegrees: DialGeometry.angle(for: time), center: center, radius: radius))
      .focusable()
      .focused($focusedHandle, equals: handle)
      .focusEffectDisabled()
      .onKeyPress(keys: [.upArrow, .rightArrow, .downArrow, .leftArrow]) { press in
        let step = press.modifiers.contains(.shift) ? 60 : ShiftHours.stepMinutes
        let forward = press.key == .upArrow || press.key == .rightArrow
        nudge(handle, by: forward ? step : -step)
        return .handled
      }
      .accessibilityElement()
      .accessibilityLabel(handle == .start ? "Start" : "Cutoff")
      .accessibilityValue(formatter.time(time))
      .accessibilityAdjustableAction { direction in
        switch direction {
        case .increment: nudge(handle, by: ShiftHours.stepMinutes)
        case .decrement: nudge(handle, by: -ShiftHours.stepMinutes)
        @unknown default: break
        }
      }
  }

  // MARK: Interaction

  private func dragGesture(center: CGPoint) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        let angle = DialGeometry.angle(
          dx: value.location.x - center.x, dy: value.location.y - center.y)
        let handle =
          dragging
          ?? DialGeometry.nearestHandle(
            to: DialGeometry.angle(
              dx: value.startLocation.x - center.x, dy: value.startLocation.y - center.y),
            hours: hours)
        dragging = handle
        focusedHandle = handle
        hours = DialGeometry.moving(handle, of: hours, to: DialGeometry.time(atAngle: angle))
      }
      .onEnded { _ in dragging = nil }
  }

  private func nudge(_ handle: DialGeometry.Handle, by minutes: Int) {
    let current = handle == .start ? hours.start : hours.cutoff
    hours = DialGeometry.moving(handle, of: hours, to: current.adding(minutes: minutes))
  }

  private func dateBinding(for handle: DialGeometry.Handle) -> Binding<Date> {
    Binding(
      get: {
        let time = handle == .start ? hours.start : hours.cutoff
        return formatter.calendar.date(
          from: DateComponents(year: 2001, month: 1, day: 1, hour: time.hour, minute: time.minute))!
      },
      set: { date in
        let parts = formatter.calendar.dateComponents([.hour, .minute], from: date)
        let typed = TimeOfDay(wrappingMinutes: (parts.hour ?? 0) * 60 + (parts.minute ?? 0))
        hours = DialGeometry.moving(handle, of: hours, to: typed)
      })
  }

  // MARK: Geometry helpers

  private var elapsedSweep: Double {
    guard let now else { return 0 }
    let minutes = hours.start.minutes(until: now)
    guard minutes < hours.durationMinutes else { return 0 }
    return Double(minutes) / Double(TimeOfDay.minutesPerDay) * 360
  }

  private func point(atDegrees degrees: Double, center: CGPoint, radius: CGFloat) -> CGPoint {
    let radians = degrees * .pi / 180
    return CGPoint(x: center.x + radius * sin(radians), y: center.y - radius * cos(radians))
  }
}

/// A clockwise arc measured from the top of its frame.
private struct ArcShape: Shape {
  var startDegrees: Double
  var sweepDegrees: Double

  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.addArc(
      center: CGPoint(x: rect.midX, y: rect.midY), radius: min(rect.width, rect.height) / 2,
      startAngle: .degrees(startDegrees - 90), endAngle: .degrees(startDegrees + sweepDegrees - 90),
      clockwise: false)
    return path
  }
}

#Preview("Day shift") {
  @Previewable @State var hours = try! ShiftHours(
    start: TimeOfDay(hour: 9, minute: 0), cutoff: TimeOfDay(hour: 18, minute: 0))
  DayDial(
    hours: $hours, now: try! TimeOfDay(hour: 14, minute: 36), note: nil,
    formatter: DayleftFormatter(calendar: .current, locale: .current)
  )
  .frame(width: 300)
  .padding()
}

#Preview("Overnight, 24-hour, dark") {
  @Previewable @State var hours = try! ShiftHours(
    start: TimeOfDay(hour: 22, minute: 0), cutoff: TimeOfDay(hour: 6, minute: 0))
  DayDial(
    hours: $hours, now: nil, note: "This ends today's shift now.",
    formatter: DayleftFormatter(calendar: .current, locale: Locale(identifier: "en_GB"))
  )
  .frame(width: 300)
  .padding()
  .preferredColorScheme(.dark)
}

#Preview("Minimum length") {
  @Previewable @State var hours = try! ShiftHours(
    start: TimeOfDay(hour: 23, minute: 45), cutoff: TimeOfDay(hour: 0, minute: 0))
  DayDial(
    hours: $hours, now: nil, note: nil,
    formatter: DayleftFormatter(calendar: .current, locale: .current)
  )
  .frame(width: 300)
  .padding()
}
