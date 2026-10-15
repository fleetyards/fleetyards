# frozen_string_literal: true

# A loadout is either a link to a build on another site or fleetyards' own,
# which records what is fitted slot by slot. Every existing row is a link.
#
# Both foreign keys cascade: a vehicle's bulk delete removes its loadouts with
# `delete_all`, and a module removed from the catalogue cannot stay fitted.
class AddFleetyardsLoadouts < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicle_loadouts, :kind, :string, null: false, default: "link"

    create_table :vehicle_loadout_items, id: :uuid do |t|
      t.references :vehicle_loadout, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.string :slot, null: false
      t.references :model_module, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.timestamps
    end

    add_index :vehicle_loadout_items, [:vehicle_loadout_id, :slot], unique: true
  end
end
