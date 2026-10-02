# frozen_string_literal: true

# The shops UEX lists, each at a place: the game files carry none. UEX names
# shop and place in one string on a price ("Casaba Outlet - Everus Harbor"),
# which is where these come from, and a price points at its shop.
class CreateShops < ActiveRecord::Migration[8.1]
  def change
    create_table :shops, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.references :location, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.timestamps
    end

    add_index :shops, :slug, unique: true
    add_index :shops, [:location_id, :name], unique: true

    add_reference :item_prices, :shop, type: :uuid, foreign_key: {on_delete: :nullify}, index: true
  end
end
