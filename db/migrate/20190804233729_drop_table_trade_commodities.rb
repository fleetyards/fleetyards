class DropTableTradeCommodities < ActiveRecord::Migration[5.2]
  def up
    drop_table :trade_commodities
  end

  def down
    create_table "trade_commodities", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.uuid "trade_hub_id"
      t.uuid "commodity_id"
      t.decimal "buy_price", precision: 15, scale: 2, default: "0.0"
      t.decimal "sell_price", precision: 15, scale: 2, default: "0.0"
      t.boolean "buy"
      t.boolean "sell"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["trade_hub_id"], name: "index_trade_commodities_on_trade_hub_id"
    end
  end
end
