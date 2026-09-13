# frozen_string_literal: true

# Who is working a contract. The first claimant is its `lead`; everyone else
# asks, and the lead answers.
#
# **One accepted lead, enforced by a partial unique index.** Two members
# claiming the same open contract at the same moment is the obvious race, and a
# validation loses it -- both transactions read no lead and both write one.
# Withdrawn and removed rows are excluded from the index so a contract released
# and re-claimed does not collide with its own history.
class CreateFleetContractAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_contract_assignments, id: :uuid do |t|
      t.references :fleet_contract, type: :uuid, null: false,
        foreign_key: {to_table: :fleet_contracts, on_delete: :cascade}
      t.references :user, type: :uuid, null: false,
        foreign_key: {to_table: :users, on_delete: :cascade}
      t.references :approved_by, type: :uuid, null: true,
        foreign_key: {to_table: :users, on_delete: :nullify}

      t.integer :role, null: false, default: 1
      t.string :aasm_state, null: false, default: "requested"

      t.datetime :requested_at
      t.datetime :accepted_at
      t.datetime :declined_at
      t.datetime :withdrawn_at
      t.datetime :removed_at

      t.timestamps
    end

    # One row per person per contract, whatever state it is in -- asking twice
    # is the same request, not a second one.
    add_index :fleet_contract_assignments, [:fleet_contract_id, :user_id], unique: true

    add_index :fleet_contract_assignments, :fleet_contract_id,
      unique: true,
      where: "role = 0 AND aasm_state = 'accepted'",
      name: "index_fleet_contract_assignments_on_accepted_lead"

    add_index :fleet_contract_assignments, [:fleet_contract_id, :aasm_state],
      name: "index_fleet_contract_assignments_on_contract_and_state"
  end
end
