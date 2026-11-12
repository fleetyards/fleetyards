# frozen_string_literal: true

class AddBundledWithToHangarPlanAcquisitions < ActiveRecord::Migration[8.1]
  def change
    add_reference :hangar_plan_acquisitions, :bundled_with, type: :uuid, index: true,
      foreign_key: {to_table: :hangar_plan_acquisitions, on_delete: :cascade}
  end
end
