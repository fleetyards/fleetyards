# frozen_string_literal: true

class CreateGameEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :game_events, id: :uuid do |t|
      t.string :title, null: false
      t.text :description
      t.string :location
      t.string :url
      t.integer :category, null: false, default: 0
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.boolean :published, null: false, default: false

      t.timestamps
    end

    add_index :game_events, :starts_at
    add_index :game_events, :published
  end
end
