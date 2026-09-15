# frozen_string_literal: true

class AddStatusToMissions < ActiveRecord::Migration[8.1]
  def up
    # New missions start as drafts, so the create button can write one
    # immediately and hand the author straight to the editor without the fleet
    # seeing a half-written mission.
    add_column :missions, :status, :string, default: "draft", null: false

    # Everything that already exists was written before there was anything to
    # publish, and the fleet can see it today -- a default of "draft" would take
    # every one of them off the list.
    execute("UPDATE missions SET status = 'published'")

    add_index :missions, [:fleet_id, :status]
  end

  def down
    remove_index :missions, [:fleet_id, :status]
    remove_column :missions, :status
  end
end
