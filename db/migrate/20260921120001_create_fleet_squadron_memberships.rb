# frozen_string_literal: true

class CreateFleetSquadronMemberships < ActiveRecord::Migration[7.2]
  def change
    create_table :fleet_squadron_memberships, id: :uuid do |t|
      t.references :fleet_squadron, type: :uuid, null: false, foreign_key: true, index: false
      t.references :fleet_membership, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end

    add_index :fleet_squadron_memberships, [:fleet_squadron_id, :fleet_membership_id],
      unique: true, name: "index_fleet_squadron_memberships_on_squadron_and_membership"
  end
end
