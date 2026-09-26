# frozen_string_literal: true

class CreateTradeRoutes < ActiveRecord::Migration[8.1]
  def change
    create_table :trade_routes, id: :uuid do |t|
      t.references :commodity, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.references :origin_terminal, type: :uuid, null: false, foreign_key: {to_table: :terminals, on_delete: :cascade}
      t.references :destination_terminal, type: :uuid, null: false, foreign_key: {to_table: :terminals, on_delete: :cascade}
      t.decimal :price_origin, precision: 15, scale: 2, null: false
      t.decimal :price_destination, precision: 15, scale: 2, null: false
      t.integer :scu_origin, null: false, default: 0
      t.integer :scu_destination, null: false, default: 0
      t.integer :container_sizes_origin, array: true, null: false, default: []
      t.integer :container_sizes_destination, array: true, null: false, default: []
      t.decimal :distance, precision: 10, scale: 2
      t.datetime :origin_price_updated_at
      t.datetime :destination_price_updated_at

      t.timestamps
    end

    add_index :trade_routes, [:commodity_id, :origin_terminal_id, :destination_terminal_id], unique: true,
      name: "index_trade_routes_on_commodity_and_terminals"
  end
end
