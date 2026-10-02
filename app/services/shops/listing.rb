# frozen_string_literal: true

module Shops
  # What a shop sells or rents, each thing once with every price it has there:
  # a ship can be both bought and rented at one counter.
  class Listing
    Item = Struct.new(:item, :prices)

    def initialize(shop)
      @shop = shop
    end

    def call
      @shop.item_prices.includes(:item).group_by(&:item).filter_map do |item, rows|
        next if item.nil?

        Item.new(item, rows.sort_by { |row| [ItemPrice.price_types[row.price_type], row.time_range.to_s] })
      end.sort_by { |entry| [entry.item.class.name, entry.item.name.to_s.downcase] }
    end
  end
end
