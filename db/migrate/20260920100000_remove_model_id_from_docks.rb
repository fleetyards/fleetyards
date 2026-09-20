# frozen_string_literal: true

# The other half of the polymorphic parent. `model_id` was kept behind in
# 20260911150000 so the containers still serving the old code had a column to
# select from while the pre-deploy migration ran; that release has long since
# gone out, and nothing reads it any more.
#
# The column is dropped rather than left to rot: every dock already carries
# `parent_type` / `parent_id`, and a second, quietly stale answer to "whose dock
# is this" is the shape the 391 orphans grew out of.
class RemoveModelIdFromDocks < ActiveRecord::Migration[8.1]
  def up
    remove_column :docks, :model_id
  end

  def down
    add_column :docks, :model_id, :uuid

    # A module dock has no model to point at, so the column comes back holding
    # what it can express and nothing else -- the same asymmetry that made the
    # forward migration's rollback refuse.
    execute("UPDATE docks SET model_id = parent_id WHERE parent_type = 'Model'")
  end
end
