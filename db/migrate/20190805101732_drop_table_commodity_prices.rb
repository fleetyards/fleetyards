class DropTableCommodityPrices < ActiveRecord::Migration[5.2]
  def up
    drop_table :commodity_prices
  end

  def down
    create_table "commodity_prices", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string "key"
      t.json "data"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
