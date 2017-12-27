class CreateTradeCommodities < ActiveRecord::Migration[5.1]
  def change
    create_table :trade_commodities, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.uuid :trade_hub_id
      t.uuid :commodity_id
      t.decimal :buy_price, precision: 15, scale: 2, default: 0.0, null: false
      t.decimal :sell_price, precision: 15, scale: 2, default: 0.0, null: false
      t.boolean :buy
      t.boolean :sell

      t.timestamps
    end
  end
end
