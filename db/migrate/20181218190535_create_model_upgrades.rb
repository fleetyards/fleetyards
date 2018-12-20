class CreateModelUpgrades < ActiveRecord::Migration[5.2]
  def change
    create_table :model_upgrades, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.boolean :active, default: false
      t.boolean :hidden, default: true
      t.string :store_image
      t.decimal :pledge_price, precision: 15, scale: 2

      t.timestamps
    end
  end
end
