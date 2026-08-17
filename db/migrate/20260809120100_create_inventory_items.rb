# frozen_string_literal: true

class CreateInventoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_items, id: :uuid do |t|
      t.references :inventory, type: :uuid, null: false, foreign_key: true
      t.string :item_type
      t.uuid :item_id
      t.string :name, null: false
      t.integer :category, null: false, default: 0
      t.integer :entry_type, null: false, default: 0
      t.decimal :quantity, precision: 15, scale: 2, null: false, default: 0
      t.integer :unit, null: false, default: 0
      t.integer :quality, default: 0
      t.text :notes
      t.timestamps
    end
  end
end
