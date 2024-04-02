class CreateModelPrices < ActiveRecord::Migration[7.1]
  def change
    create_table :model_prices, id: :uuid do |t|
      t.integer :price_type
      t.decimal :price, precision: 15, scale: 2
      t.string :location
      t.string :location_url
      t.integer :time_range
      t.references :model, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
