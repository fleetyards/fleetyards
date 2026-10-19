# frozen_string_literal: true

class AddSourcePledgeItemKeyToInventoryItems < ActiveRecord::Migration[8.1]
  def change
    add_column :inventory_items, :source_pledge_item_key, :string
    add_index :inventory_items, :source_pledge_item_key
  end
end
