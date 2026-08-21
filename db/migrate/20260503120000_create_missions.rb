# frozen_string_literal: true

class CreateMissions < ActiveRecord::Migration[7.2]
  def change
    create_table :missions, id: :uuid do |t|
      t.references :fleet, type: :uuid, null: false, foreign_key: true, index: false
      t.uuid :created_by_id, null: false
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.datetime :archived_at
      t.timestamps
    end

    add_index :missions, [:fleet_id, :slug], unique: true
    add_index :missions, [:fleet_id, :archived_at]
    add_foreign_key :missions, :users, column: :created_by_id
  end
end
