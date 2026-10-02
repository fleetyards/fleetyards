# frozen_string_literal: true

class AddDirectoryFieldsToFleets < ActiveRecord::Migration[8.1]
  def change
    add_column :fleets, :listed, :boolean
    add_column :fleets, :alignment, :string
    add_column :fleets, :primary_activity, :string
    add_column :fleets, :secondary_activity, :string
    add_column :fleets, :language, :string
    add_column :fleets, :commitment, :string
    add_column :fleets, :roleplay, :boolean
    add_column :fleets, :recruiting, :boolean
    add_column :fleets, :rsi_synced_at, :datetime
    add_column :fleets, :rsi_sync_attempted_at, :datetime

    add_index :fleet_memberships, :fleet_id,
      name: "index_fleet_memberships_on_fleet_id_accepted",
      where: "aasm_state = 'accepted' AND discarded_at IS NULL"
  end
end
