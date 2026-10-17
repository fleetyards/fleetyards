# frozen_string_literal: true

# A loadout can take a slot's stock part out, which it records as an item with
# no part in it.
class AllowEmptyVehicleLoadoutItems < ActiveRecord::Migration[8.1]
  def change
    change_column_null :vehicle_loadout_items, :item_id, true
  end
end
