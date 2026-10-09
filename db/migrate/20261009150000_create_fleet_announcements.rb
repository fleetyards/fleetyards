# frozen_string_literal: true

class CreateFleetAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_announcements, id: :uuid do |t|
      t.references :fleet, type: :uuid, null: false, foreign_key: true, index: false
      t.references :author, type: :uuid, foreign_key: {to_table: :users, on_delete: :nullify}
      t.text :body, null: false
      t.datetime :expires_at
      t.timestamps
    end

    add_index :fleet_announcements, %i[fleet_id created_at]
  end
end
