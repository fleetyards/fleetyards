class CreateCommodityPrices < ActiveRecord::Migration[5.1]
  def change
    create_table :commodity_prices, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string :key
      t.json :data

      t.timestamps
    end
  end
end
