import DayleftCore
import Foundation
import Testing

struct DialGeometryTests {
  @Test func midnightIsAtTheTopRunningClockwise() {
    #expect(DialGeometry.angle(for: time(0, 0)) == 0)
    #expect(DialGeometry.angle(for: time(6, 0)) == 90)
    #expect(DialGeometry.angle(for: time(18, 0)) == 270)
    #expect(DialGeometry.angle(dx: 0, dy: -1) == 0)
    #expect(DialGeometry.angle(dx: 1, dy: 0) == 90)
    #expect(DialGeometry.angle(dx: 0, dy: 1) == 180)
    #expect(DialGeometry.angle(dx: -1, dy: 0) == 270)
  }

  @Test func anglesSnapToTheShiftStep() {
    #expect(DialGeometry.time(atAngle: 359.9) == time(0, 0))
    #expect(DialGeometry.time(atAngle: -90) == time(18, 0))
    #expect(DialGeometry.time(atAngle: 135.6) == time(9, 0))
    #expect(DialGeometry.time(atAngle: 136.4) == time(9, 5))
  }

  @Test func arcsCanCrossMidnight() {
    let arc = DialGeometry.arc(for: hours((22, 0), (6, 0)))
    #expect(arc.start == 330)
    #expect(arc.sweep == 120)
  }

  @Test func picksTheNearestHandle() {
    let shift = hours((22, 0), (6, 0))
    #expect(DialGeometry.nearestHandle(to: 340, hours: shift) == .start)
    #expect(DialGeometry.nearestHandle(to: 80, hours: shift) == .cutoff)
    #expect(DialGeometry.nearestHandle(to: 210, hours: shift) == .start)
  }

  @Test func movingAHandleSnapsAndKeepsTheMinimumGap() {
    let shift = hours((9, 0), (18, 0))
    #expect(DialGeometry.moving(.start, of: shift, to: time(8, 2)) == hours((8, 0), (18, 0)))
    #expect(DialGeometry.moving(.start, of: shift, to: time(17, 55)) == hours((17, 45), (18, 0)))
    #expect(DialGeometry.moving(.cutoff, of: shift, to: time(9, 5)) == hours((9, 0), (9, 15)))
    // Arriving from the far side stops there instead of jumping across the other handle.
    let long = hours((9, 0), (8, 0))
    #expect(DialGeometry.moving(.cutoff, of: long, to: time(8, 55)) == hours((9, 0), (8, 45)))
    #expect(DialGeometry.moving(.cutoff, of: shift, to: time(2, 0)) == hours((9, 0), (2, 0)))
  }

  @Test func clicksHitOnlyHandlesAndArcs() throws {
    let split = try WorkSessions([hours((7, 0), (11, 0)), hours((13, 0), (17, 0))])
    func target(atDegrees degrees: Double, distance: Double, selected: Int = 0)
      -> DialGeometry.Target?
    {
      let radians = degrees * .pi / 180
      return DialGeometry.target(
        dx: distance * sin(radians), dy: -distance * cos(radians), radius: 100, ringReach: 19,
        handleReach: 18, in: split, selected: selected)
    }
    let start = DialGeometry.angle(for: time(7, 0))
    // On a handle, even from just inside the ring.
    #expect(target(atDegrees: start, distance: 100) == .handle(index: 0, .start))
    #expect(target(atDegrees: start, distance: 88) == .handle(index: 0, .start))
    // An unselected session's handle still grabs it.
    #expect(target(atDegrees: start, distance: 100, selected: 1) == .handle(index: 0, .start))
    // On an arc away from its handles, only that session.
    #expect(target(atDegrees: DialGeometry.angle(for: time(15, 0)), distance: 105) == .session(1))
    // The middle of the dial, a gap, or past the ring: nothing.
    #expect(target(atDegrees: DialGeometry.angle(for: time(15, 0)), distance: 30) == nil)
    #expect(target(atDegrees: start, distance: 40) == nil)
    #expect(target(atDegrees: DialGeometry.angle(for: time(20, 0)), distance: 100) == nil)
    #expect(target(atDegrees: DialGeometry.angle(for: time(9, 0)), distance: 130) == nil)
  }

  @Test func overlappingHandlesPreferTheSelectedSession() throws {
    let close = try WorkSessions([hours((7, 0), (11, 0)), hours((11, 5), (15, 0))])
    let between = DialGeometry.angle(for: time(11, 3))
    func target(selected: Int) -> DialGeometry.Target? {
      let radians = between * .pi / 180
      return DialGeometry.target(
        dx: 100 * sin(radians), dy: -100 * cos(radians), radius: 100, ringReach: 19,
        handleReach: 18, in: close, selected: selected)
    }
    #expect(target(selected: 0) == .handle(index: 0, .cutoff))
    #expect(target(selected: 1) == .handle(index: 1, .start))
  }
}
