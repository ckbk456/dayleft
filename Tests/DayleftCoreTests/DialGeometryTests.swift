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
}
