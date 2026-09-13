# frozen_string_literal: true

class AddUnmatchedVehiclesActionToImports < ActiveRecord::Migration[8.1]
  # A sync moved every ship it could not find in the RSI pledge list onto the
  # wishlist, with no way to ask for anything else. The run now carries the
  # choice; `wishlist` is what every sync did before.
  def up
    add_column :imports, :unmatched_vehicles_action, :string, default: "wishlist", null: false
    add_column :imports, :unmatched_hangar_group_id, :uuid

    add_index :imports, :unmatched_hangar_group_id

    # Same reasoning as `hangar_group_id`: the group is a target the user picked
    # for one run, not a dependency of the record of that run.
    add_foreign_key :imports, :hangar_groups, column: :unmatched_hangar_group_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :imports, column: :unmatched_hangar_group_id

    remove_index :imports, :unmatched_hangar_group_id

    remove_column :imports, :unmatched_hangar_group_id
    remove_column :imports, :unmatched_vehicles_action
  end
end
