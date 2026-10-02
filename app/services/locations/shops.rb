# frozen_string_literal: true

module Locations
  # The shops at a place, from the UEX prices whose location string names it,
  # each with what it sells or rents and at what price. The game files carry no
  # shops, so these are UEX's.
  class Shops
    Shop = Struct.new(:name, :items)
    Item = Struct.new(:item, :prices)

    def initialize(location)
      @location = location
    end

    def call
      ItemPrice.where(location_id: @location.id).where.not(shop_name: nil)
        .includes(:item)
        .group_by(&:shop_name)
        .map { |name, prices| Shop.new(name, items(prices)) }
        .sort_by { |shop| shop.name.downcase }
    end

    private def items(prices)
      prices.group_by(&:item).filter_map do |item, rows|
        next if item.nil?

        Item.new(item, rows.sort_by { |row| [ItemPrice.price_types[row.price_type], row.time_range.to_s] })
      end.sort_by { |entry| entry.item.name.to_s.downcase }
    end
  end
end
