# frozen_string_literal: true

class CreateFleetEventAdmins < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_event_admins, id: :uuid do |t|
      t.references :fleet_event, type: :uuid, foreign_key: true, null: false
      t.references :user, type: :uuid, foreign_key: true, null: false
      t.string :role, null: false, default: "admin"
      t.uuid :granted_by_id
      t.timestamps
    end

    add_index :fleet_event_admins, [:fleet_event_id, :user_id], unique: true
  end
end
