# Timer and menu bar manual guide

Record each result with date, tester, commit, macOS version, Xcode version, and architecture.
Use System Settings → General → Date & Time to change the clock, time zone, and 24-hour time.

## Run setup — pending

- [ ] Build and run Dayleft from Xcode on My Mac (or the locally signed build); no Dock icon.
- [ ] The panel footer and the settings window's About pane show `version+commit` matching
      `git rev-parse --short HEAD`, with `.dirty` (orange) only when the build had uncommitted changes.
- [ ] The menu bar shows **both** the hourglass and the text. If only the icon appears, record
      it: the label interpolates the image into a single `Text` to avoid that.

## Day dial — pending

- [ ] Xcode previews (`App/Components/DayDial.swift`): day shift, overnight, minimum length.
- [ ] Dragging a handle snaps to 5 minutes and stops 15 minutes from the other handle without
      jumping across it; the arc crosses midnight correctly.
- [ ] Clicking or dragging the middle of the dial, its corners, or a gap between sessions changes
      nothing; only a handle or an arc responds.
- [ ] Focused handles move with arrow keys (5 minutes) and Shift-arrows (1 hour).
- [ ] The large Start and Cutoff times above the dial follow the handles, and the label of the
      handle being moved turns orange; the shift length below the dial is the only other change.
- [ ] Clicking a large time opens a field that types an exact time and moves its handle.
- [ ] VoiceOver reads "Start"/"Cutoff" with the time and adjusts them.
- [ ] Hour marks follow 12/24-hour settings; light and dark appearances are readable.

## Settings window — pending

- [ ] Panel rows open the Today and Regular Schedule panes; the gear button and ⌘, open the window.
      The panel closes, and the window comes to the front over other apps.
- [ ] A Dock icon and app menu appear only while the window is open; closing it (button or ⌘W)
      returns Dayleft to the menu bar only. The window never opens by itself at launch.
- [ ] Naming is consistent: "Regular schedule" for recurring hours/workdays, "Today's work" for
      today-only changes. On a non-workday, Today says so instead of quoting regular hours.
- [ ] Today: Revert and Apply stay disabled until the draft differs; reopening the window drops
      an unapplied draft; the dial is not cramped and its labels do not overlap.

## Sessions and day plans — pending

- [ ] Existing single-hours settings appear after updating as one plan with one session.
- [ ] Add Session centres up to an hour in the longest break; Remove keeps at least one; four
      is the maximum. Selecting a row highlights its arc and moves the handles to it; dragging
      a handle or another session's arc end selects that session; handles stop a 5-minute break from other sessions.
- [ ] A 07–11, 13–17, 20–00 day: during a session the menu bar counts down the session and the
      panel shows work left today; during a break the menu bar shows the next start and the
      panel says BREAK; the bar shows gaps; after midnight it shows `Done`/`Off` as expected.
- [ ] Day plans: add a Weekend plan, move Friday into it from Weekdays, remove a plan (its days
      become days off), and leave Wednesday in no plan; the panel and states follow.
- [ ] Today → Different hours edits several sessions for today only.

## MVP acceptance criteria — pending

1. [ ] First launch uses Monday–Friday 09:00–18:00 and shows the correct current state.
2. [ ] Menu bar text per state: remaining time while working, start time before work, `Done`
       after the cutoff until midnight or the next start, `Off` on a day off or non-workday.
3. [ ] The read-only panel shows remaining time, cutoff, the elapsed bar (labelled elapsed), the shift
       endpoints; compare with [the approved direction](../../docs/design/approved-menu-bar.png).
4. [ ] Settings changes apply immediately and persist after Quit and relaunch.
5. [ ] A today-only change or day off affects only today's shift and disappears when it ends.
6. [ ] A Friday 22:00–06:00 shift counts down across midnight into Saturday, then shows `Done`.
7. [ ] Sleep/wake, a manual clock change, a time-zone change, and midnight all refresh correctly.
8. [ ] Login launch is off by default; the switch matches System Settings → Login Items.
9. [ ] The dial and Settings work with the keyboard alone and with VoiceOver.
10. [ ] Light, dark, and Increase Contrast appearances are readable; 12- and 24-hour time work.
11. [ ] Nothing requires a network connection or an account.
12. [ ] Narrow or notched menu bars, multiple displays, and Spaces/full screen behave sensibly.

Provider and distribution guides should be introduced when their actual implementations exist.
