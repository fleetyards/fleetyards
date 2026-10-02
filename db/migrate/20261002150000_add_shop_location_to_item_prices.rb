# frozen_string_literal: true

# The shop and place a UEX item price names in its location string ("Casaba
# Outlet - Everus Harbor"), so a place can list the shops at it.
class AddShopLocationToItemPrices < ActiveRecord::Migration[8.1]
  def change
    add_reference :item_prices, :location, type: :uuid, foreign_key: {on_delete: :nullify}, index: true
    add_column :item_prices, :shop_name, :string
  end
end
