import DayleftCore
import DayleftPresentation
import SwiftUI

/// The regular schedule: day plans, each with its weekdays and sessions. Changes apply
/// immediately.
struct SchedulePane: View {
  let model: TimerModel

  @State private var selectedPlanID: DayPlan.ID?

  private var formatter: DayleftFormatter {
    DayleftFormatter(calendar: .autoupdatingCurrent, locale: .autoupdatingCurrent)
  }

  private var schedule: Schedule { model.settings.schedule }

  private var plan: DayPlan {
    schedule.plans.first { $0.id == selectedPlanID } ?? schedule.plans[0]
  }

  var body: some View {
    Form {
      Section {
        ForEach(schedule.plans) { plan in
          PlanRow(
            name: plan.name.isEmpty ? "Untitled" : plan.name,
            days: plan.days.isEmpty ? "No days" : formatter.workdaysSummary(plan.days),
            sessions: formatter.sessionsSummary(plan.sessions),
            isSelected: plan.id == self.plan.id
          ) {
            selectedPlanID = plan.id
          }
        }
      } header: {
        Text("Day plans")
      } footer: {
        HStack(spacing: 8) {
          Button(action: addPlan) {
            Label("Add Day Plan", systemImage: "plus")
          }
          .disabled(schedule.plans.count >= Schedule.maximumPlans)
          Button(action: removePlan) {
            Label("Remove Day Plan", systemImage: "minus")
          }
          .disabled((try? Schedule(plans: schedule.plans.filter { $0.id != plan.id })) == nil)
          .help("Remove the selected day plan; its days become days off")
          Spacer()
          Text("Days in no plan are days off.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .controlSize(.small)
        .dayleftGlassButtonStyle()
      }

      Section {
        TextField("Name", text: nameBinding, prompt: Text("e.g. Weekend"))
        HStack(spacing: 6) {
          ForEach(formatter.orderedWeekdays, id: \.self) { day in
            Toggle(formatter.shortName(day), isOn: dayBinding(day))
              .toggleStyle(.button)
              .help(dayHelp(day))
          }
        }
        .frame(maxWidth: .infinity)
      } header: {
        Text("Days")
      } footer: {
        Text("Turning on a day that belongs to another plan moves it here.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      SessionsEditor(sessions: sessionsBinding, title: "Sessions in \(planName)")
        .id(plan.id)
    }
    .formStyle(.grouped)
  }

  private var planName: String { plan.name.isEmpty ? "this plan" : plan.name }

  private func dayHelp(_ day: Weekday) -> String {
    guard let owner = schedule.plan(on: day), owner.id != plan.id else { return "" }
    return "Currently in \(owner.name.isEmpty ? "another plan" : owner.name)"
  }

  // MARK: Editing

  private func update(_ edit: (inout DayPlan) -> Void) {
    var updated = plan
    edit(&updated)
    if let schedule = try? schedule.updating(updated) {
      model.updateSchedule(schedule)
    }
  }

  private var nameBinding: Binding<String> {
    Binding(get: { plan.name }, set: { name in update { $0.name = name } })
  }

  private var sessionsBinding: Binding<WorkSessions> {
    Binding(get: { plan.sessions }, set: { sessions in update { $0.sessions = sessions } })
  }

  private func dayBinding(_ day: Weekday) -> Binding<Bool> {
    Binding(
      get: { plan.days.contains(day) },
      set: { isOn in
        let updated =
          isOn
          ? try? schedule.assigning(day, to: plan.id)
          : try? schedule.updating(
            DayPlan(
              id: plan.id, name: plan.name, days: plan.days.subtracting([day]),
              sessions: plan.sessions))
        if let updated { model.updateSchedule(updated) }
      })
  }

  private func addPlan() {
    let plan = DayPlan(
      name: "Day plan \(schedule.plans.count + 1)", days: [],
      sessions: WorkSessions(
        try! ShiftHours(
          start: TimeOfDay(hour: 9, minute: 0), cutoff: TimeOfDay(hour: 17, minute: 0))))
    if let updated = try? Schedule(plans: schedule.plans + [plan]) {
      model.updateSchedule(updated)
      selectedPlanID = plan.id
    }
  }

  private func removePlan() {
    let removedID = plan.id
    if let updated = try? Schedule(plans: schedule.plans.filter { $0.id != removedID }) {
      model.updateSchedule(updated)
      selectedPlanID = updated.plans.first?.id
    }
  }
}

/// One day plan in the list; the selected plan is edited below.
private struct PlanRow: View {
  let name: String
  let days: String
  let sessions: String
  let isSelected: Bool
  let select: () -> Void

  var body: some View {
    Button(action: select) {
      HStack(spacing: 10) {
        VStack(alignment: .leading, spacing: 2) {
          Text(name)
            .fontWeight(isSelected ? .semibold : .regular)
          Text(days)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Text(sessions)
          .monospacedDigit()
          .foregroundStyle(.secondary)
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .foregroundStyle(isSelected ? AnyShapeStyle(.orange) : AnyShapeStyle(.tertiary))
      }
      .padding(.vertical, 4)
      .padding(.horizontal, 6)
      .dayleftSelection(isSelected)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(name), \(days), \(sessions)")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}
