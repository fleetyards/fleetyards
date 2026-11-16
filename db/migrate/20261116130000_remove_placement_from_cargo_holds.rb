# frozen_string_literal: true

class RemovePlacementFromCargoHolds < ActiveRecord::Migration[8.1]
  def change
    # Holds are placed from the hull export alone.
    change_table :cargo_holds, bulk: true do |t|
      t.remove :offset_x, type: :decimal, precision: 15, scale: 2
      t.remove :offset_y, type: :decimal, precision: 15, scale: 2
      t.remove :offset_z, type: :decimal, precision: 15, scale: 2
      t.remove :rotation, type: :integer
    end
  end
end
