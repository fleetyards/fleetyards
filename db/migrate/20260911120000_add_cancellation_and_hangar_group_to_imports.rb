# frozen_string_literal: true

class AddCancellationAndHangarGroupToImports < ActiveRecord::Migration[8.1]
  def up
    add_column :imports, :cancelled_at, :datetime
    add_column :imports, :cancel_requested_at, :datetime
    add_column :imports, :hangar_group_id, :uuid

    add_index :imports, :hangar_group_id

    # The group is a target the user picked for one run, not a dependency of the
    # record of that run. Deleting the group later must not take the history
    # with it, so the reference nullifies rather than cascading.
    add_foreign_key :imports, :hangar_groups, column: :hangar_group_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :imports, column: :hangar_group_id

    remove_index :imports, :hangar_group_id

    remove_column :imports, :hangar_group_id
    remove_column :imports, :cancel_requested_at
    remove_column :imports, :cancelled_at
  end
end
