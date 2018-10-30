class CreateShopCommodities < ActiveRecord::Migration[5.2]
  def change
    create_table :shop_commodities, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.uuid :shop_id
      t.string :name
      t.text :description
      t.decimal 'buy_price', precision: 15, scale: 2
      t.decimal 'sell_price', precision: 15, scale: 2
      t.decimal 'rent_price', precision: 15, scale: 2
      t.references :commodity_item, polymorphic: true, type: :uuid, index: { name: 'index_shop_commodities_on_item_type_and_item_id' }

      t.timestamps
    end
  end
end
