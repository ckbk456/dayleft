# Timer and menu bar manual guide

Record each result with date, tester, commit, macOS version, Xcode version, and architecture.
Use System Settings → General → Date & Time to change the clock, time zone, and 24-hour time.

## Run setup — pending

- [ ] Build and run Dayleft from Xcode on My Mac (or the locally signed build); no Dock icon.
- [ ] The panel footer and Settings → About show `version+commit` matching `git rev-parse
      --short HEAD`, with `.dirty` (orange) only when the build had uncommitted changes.
- [ ] The menu bar shows **both** the hourglass and the text. If only the icon appears, record
      it: the label interpolates the image into a single `Text` to avoid that.

## Day dial — pending

- [ ] Xcode previews (`App/Components/DayDial.swift`): day shift, overnight, minimum length.
- [ ] Dragging snaps to 5 minutes, moves the nearest handle, and stops 15 minutes from the other
      handle without jumping across it; the arc crosses midnight correctly.
- [ ] Focused handles move with arrow keys (5 minutes) and Shift-arrows (1 hour).
- [ ] VoiceOver reads "Start"/"Cutoff" with the time and adjusts them; the time fields stay in sync.
- [ ] Hour marks follow 12/24-hour settings; light and dark appearances are readable.

## MVP acceptance criteria — pending

1. [ ] First launch uses Monday–Friday 09:00–18:00 and shows the correct current state.
2. [ ] Menu bar text per state: remaining time while working, start time before work, `Done`
       after the cutoff until midnight or the next start, `Off` on a day off or non-workday.
3. [ ] The panel shows remaining time, cutoff, the elapsed bar (labelled elapsed), and the shift
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
