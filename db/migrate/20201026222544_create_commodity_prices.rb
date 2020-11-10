class CreateCommodityPrices < ActiveRecord::Migration[6.0]
  def change
    create_table :commodity_prices, id: :uuid do |t|
      t.string :type
      t.references :shop_commodity, type: :uuid
      t.decimal :price, precision: 15, scale: 2
      t.integer :time_range

      t.timestamps
    end
  end
end
