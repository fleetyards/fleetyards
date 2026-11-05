# frozen_string_literal: true

class CreateOutfitStoredItems < ActiveRecord::Migration[8.1]
  def change
    create_table :outfit_stored_items, id: :uuid do |t|
      t.references :outfit, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.references :equipment, type: :uuid, null: false, foreign_key: true
      t.integer :holder, null: false
      t.integer :quantity, null: false, default: 1

      t.timestamps
    end

    add_index :outfit_stored_items, [:outfit_id, :holder, :equipment_id], unique: true
  end
end
