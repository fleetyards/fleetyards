# frozen_string_literal: true

class CreateHangarPledgeItems < ActiveRecord::Migration[8.1]
  def change
    create_table :hangar_pledge_items, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.string :rsi_pledge_id, null: false
      t.string :kind, null: false
      t.string :name, null: false
      t.integer :quantity, null: false, default: 1
      t.string :image_url
      t.string :pledge_name
      t.decimal :pledge_value, precision: 15, scale: 2
      t.integer :pledge_item_count
      t.date :pledge_created_on
      t.boolean :meltable, null: false, default: false
      t.timestamps
    end

    add_index :hangar_pledge_items, [:user_id, :kind, :rsi_pledge_id, :name], unique: true,
      name: "index_hangar_pledge_items_on_user_kind_pledge_name"
  end
end
