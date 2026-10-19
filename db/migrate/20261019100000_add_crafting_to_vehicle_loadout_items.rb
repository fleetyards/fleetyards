# frozen_string_literal: true

# A component in a loadout can be a crafted one: the recipe it was made from,
# and the material quality that went into each of that recipe's slots.
class AddCraftingToVehicleLoadoutItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :vehicle_loadout_items, :blueprint, type: :uuid, foreign_key: {on_delete: :nullify}
    add_column :vehicle_loadout_items, :crafted_qualities, :jsonb, default: {}, null: false
  end
end
