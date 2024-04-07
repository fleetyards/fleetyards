class CreateItemPrices < ActiveRecord::Migration[7.1]
  def change
    create_table :item_prices, id: :uuid do |t|
      t.integer :price_type
      t.decimal :price, precision: 15, scale: 2
      t.string :location
      t.string :location_url
      t.integer :time_range
      t.references :item, null: false, polymorphic: true, type: :uuid

      t.timestamps
    end
  end
end
