# frozen_string_literal: true

# A loadout is either a link to a build on another site or fleetyards' own,
# which records what is fitted, slot by slot. Every existing row is a link.
#
# A slot is a path of hardpoint names from the hull down, so a hardpoint that
# only exists on a fitted module or turret has a place too. What sits in it is
# polymorphic: a module now, a component once those categories are fitted.
#
# The loadout's foreign key cascades, because a vehicle's bulk delete removes
# its loadouts with `delete_all`.
class AddFleetyardsLoadouts < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicle_loadouts, :kind, :string, null: false, default: "link"

    create_table :vehicle_loadout_items, id: :uuid do |t|
      t.references :vehicle_loadout, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.string :slot_path, null: false
      t.references :item, type: :uuid, polymorphic: true, null: false
      t.timestamps
    end

    add_index :vehicle_loadout_items, [:vehicle_loadout_id, :slot_path], unique: true,
      name: "index_vehicle_loadout_items_on_loadout_and_slot_path"
  end
end
