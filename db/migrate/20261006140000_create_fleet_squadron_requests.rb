# frozen_string_literal: true

class CreateFleetSquadronRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_squadron_requests, id: :uuid do |t|
      t.references :fleet_squadron, type: :uuid, null: false, foreign_key: true, index: false
      t.references :fleet_membership, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end

    add_index :fleet_squadron_requests, [:fleet_squadron_id, :fleet_membership_id],
      unique: true, name: "index_fleet_squadron_requests_on_squadron_and_membership"
  end
end
