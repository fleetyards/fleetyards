# frozen_string_literal: true

class CreateMissionShips < ActiveRecord::Migration[7.2]
  def change
    create_table :mission_ships, id: :uuid do |t|
      t.references :mission, type: :uuid, null: false, foreign_key: true
      t.references :model, type: :uuid, null: true, foreign_key: true
      t.string :title
      t.text :description
      t.string :classification
      t.string :focus
      t.string :min_size
      t.string :max_size
      t.integer :min_crew
      t.decimal :min_cargo
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :mission_ships, [:mission_id, :position]
  end
end
