# frozen_string_literal: true

class LetHangarPlanSlotsHoldStarts < ActiveRecord::Migration[8.1]
  def change
    add_reference :hangar_plan_acquisitions, :hangar_plan_slot, type: :uuid, foreign_key: {on_delete: :cascade}
    change_column_null :hangar_plan_acquisitions, :hangar_plan_candidate_id, true
    change_column_null :hangar_plan_acquisitions, :start_model_id, true
    add_check_constraint :hangar_plan_acquisitions, "num_nonnulls(hangar_plan_candidate_id, hangar_plan_slot_id) = 1",
      name: "hangar_plan_acquisitions_held_by_one"
  end
end
