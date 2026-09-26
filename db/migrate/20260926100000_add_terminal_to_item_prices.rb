# frozen_string_literal: true

class AddTerminalToItemPrices < ActiveRecord::Migration[8.1]
  def change
    add_reference :item_prices, :terminal, type: :uuid, foreign_key: {on_delete: :nullify}
    add_column :item_prices, :scu, :integer
    add_column :item_prices, :source_updated_at, :datetime

    add_column :item_price_snapshots, :terminal_id, :uuid

    remove_index :item_price_snapshots,
      [:item_type, :item_id, :location, :price_type, :time_range, :recorded_on],
      name: "index_item_price_snapshots_on_item_and_day", unique: true, nulls_not_distinct: true
    add_index :item_price_snapshots,
      [:item_type, :item_id, :location, :terminal_id, :price_type, :time_range, :recorded_on],
      name: "index_item_price_snapshots_on_item_and_day", unique: true, nulls_not_distinct: true
  end
end
