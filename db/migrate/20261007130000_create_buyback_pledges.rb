# frozen_string_literal: true

class CreateBuybackPledges < ActiveRecord::Migration[8.1]
  def change
    create_table :buyback_pledges, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.string :rsi_pledge_id, null: false
      t.string :kind, null: false
      t.string :name, null: false
      t.boolean :upgraded, null: false, default: false
      t.date :reclaimed_on
      t.string :contained
      t.string :image_url
      t.integer :upgrade_from_ship_id
      t.integer :upgrade_to_ship_id
      t.integer :upgrade_to_sku_id
      t.timestamps
    end

    add_index :buyback_pledges, [:user_id, :rsi_pledge_id], unique: true
  end
end
