# frozen_string_literal: true

class CreateFleetSquadronAssignments < ActiveRecord::Migration[8.0]
  # Which squadrons a record is for. Polymorphic because the three things that
  # carry one -- an event, a contract, an inventory -- have nothing else in
  # common, and a column on each would be three columns that mean the same and
  # drift apart.
  def change
    create_table :fleet_squadron_assignments, id: :uuid do |t|
      t.references :fleet_squadron, null: false, foreign_key: true, type: :uuid
      t.references :assignable, null: false, polymorphic: true, type: :uuid

      t.timestamps
    end

    add_index :fleet_squadron_assignments,
      %i[fleet_squadron_id assignable_type assignable_id],
      unique: true,
      name: "index_fleet_squadron_assignments_uniqueness"
  end
end
