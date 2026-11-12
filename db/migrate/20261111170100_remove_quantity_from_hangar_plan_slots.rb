# frozen_string_literal: true

class RemoveQuantityFromHangarPlanSlots < ActiveRecord::Migration[8.1]
  def change
    remove_column :hangar_plan_slots, :quantity, :integer, default: 1, null: false
  end
end
