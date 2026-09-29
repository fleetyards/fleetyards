# frozen_string_literal: true

class CreateFleetFidClaims < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_fid_claims, id: :uuid do |t|
      t.references :claimant, type: :uuid, null: false, foreign_key: {to_table: :fleets, on_delete: :cascade}
      t.references :holder, type: :uuid, foreign_key: {to_table: :fleets, on_delete: :nullify}
      t.uuid :created_by
      t.string :fid, null: false
      t.string :state, null: false, default: "open"
      t.string :cancel_reason
      t.datetime :ends_at, null: false
      t.datetime :completed_at
      t.datetime :cancelled_at
      t.string :holder_previous_fid
      t.string :holder_new_fid

      t.timestamps
    end

    add_index :fleet_fid_claims, :fid, unique: true, where: "state = 'open'", name: "index_fleet_fid_claims_on_open_fid"
    add_index :fleet_fid_claims, %i[state ends_at]
  end
end
