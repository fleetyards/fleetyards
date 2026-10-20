class AddDescriptionAndFiltersToHangarPlanSlots < ActiveRecord::Migration[8.1]
  def change
    add_column :hangar_plan_slots, :description, :text
    add_column :hangar_plan_slots, :filters, :jsonb, null: false, default: {}
  end
end
