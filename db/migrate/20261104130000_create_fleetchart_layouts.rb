# frozen_string_literal: true

class CreateFleetchartLayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :fleetchart_layouts, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.jsonb :placements, null: false, default: []
      t.boolean :colored, null: false, default: true
      t.string :share_token

      t.timestamps

      t.index [:user_id, :name], unique: true
      t.index :share_token, unique: true
    end
  end
end
