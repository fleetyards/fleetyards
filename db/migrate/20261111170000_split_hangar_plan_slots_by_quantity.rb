# frozen_string_literal: true

class SplitHangarPlanSlotsByQuantity < ActiveRecord::Migration[8.1]
  class Plan < ActiveRecord::Base
    self.table_name = "hangar_plans"
  end

  class Slot < ActiveRecord::Base
    self.table_name = "hangar_plan_slots"
  end

  class Candidate < ActiveRecord::Base
    self.table_name = "hangar_plan_candidates"
  end

  class Acquisition < ActiveRecord::Base
    self.table_name = "hangar_plan_acquisitions"
  end

  # A slot is one ship now. One that stood for several becomes that many slots
  # in a row, each with the shortlist; the n-th ship of the old slot keeps the
  # n-th start of every candidate, and the n-th start the slot held itself.
  # Upgrade steps belong to their start, so they move along with it.
  def up
    plan_ids = Slot.where("quantity > 1").distinct.pluck(:hangar_plan_id)

    plan_ids.each do |plan_id|
      position = 0
      Slot.where(hangar_plan_id: plan_id).order(:position, :created_at, :id).to_a.each do |slot|
        slot.update_columns(position:)
        position += 1
        next if slot.quantity <= 1

        candidates = Candidate.where(hangar_plan_slot_id: slot.id).order(:position, :created_at, :id).to_a
        routes = Acquisition.where(hangar_plan_candidate_id: candidates.map(&:id)).order(:created_at, :id)
          .group_by(&:hangar_plan_candidate_id)
        starts = Acquisition.where(hangar_plan_slot_id: slot.id).order(:created_at, :id).to_a

        (1...slot.quantity).each do |unit|
          copy = Slot.create!(hangar_plan_id: plan_id, label: slot.label, description: slot.description,
            filters: slot.filters, position:)
          position += 1

          candidates.each do |candidate|
            copied = Candidate.create!(hangar_plan_slot_id: copy.id, model_id: candidate.model_id,
              model_paint_id: candidate.model_paint_id, model_module_ids: candidate.model_module_ids,
              model_upgrade_ids: candidate.model_upgrade_ids, position: candidate.position)
            routes.fetch(candidate.id, [])[unit]&.update_columns(hangar_plan_candidate_id: copied.id)
          end
          starts[unit]&.update_columns(hangar_plan_slot_id: copy.id)
        end

        slot.update_columns(quantity: 1)
      end
    end

    Plan.where(id: plan_ids).update_all(updated_at: Time.current)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
