# frozen_string_literal: true

class AddDiscardToFleetsAndMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :fleets, :discarded_at, :datetime
    add_index :fleets, :discarded_at

    add_column :fleet_memberships, :discarded_at, :datetime
    add_index :fleet_memberships, :discarded_at

    remove_index :fleets, :fid, unique: true, name: "index_fleets_on_fid"
    add_index :fleets, :fid, unique: true, where: "discarded_at IS NULL",
      name: "index_fleets_on_fid"

    remove_index :fleet_memberships, %i[user_id fleet_id], unique: true,
      name: "index_fleet_memberships_on_user_id_and_fleet_id"
    add_index :fleet_memberships, %i[user_id fleet_id], unique: true,
      where: "discarded_at IS NULL",
      name: "index_fleet_memberships_on_user_id_and_fleet_id"
  end
end
