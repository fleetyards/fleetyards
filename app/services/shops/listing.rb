# frozen_string_literal: true

module Shops
  # What a shop sells or rents, each thing once with every price it has there:
  # a ship can be both bought and rented at one counter.
  class Listing
    Item = Struct.new(:item, :prices)

    # The catalogue each item type is listed in, by its token prefix: a shop
    # shows only what that catalogue lists, so every row has a page to open.
    PREFIXES = {"Equipment" => "equipment", "Component" => "component", "Model" => "ship", "Commodity" => "commodity"}.freeze

    # Only the items their catalogue lists. A type without one is kept whole.
    def self.listed(items)
      items.group_by { |item| item.class.name }.flat_map do |type, group|
        prefix = PREFIXES[type]
        next group unless prefix

        ids = ::Catalogue::TokenResolver.listed(prefix).where(id: group.map(&:id)).pluck(:id).to_set
        group.select { |item| ids.include?(item.id) }
      end
    end

    def initialize(shop)
      @shop = shop
    end

    def call
      by_item = @shop.item_prices.includes(:item).group_by(&:item)
      listed = self.class.listed(by_item.keys.compact).to_set

      by_item.filter_map do |item, rows|
        next unless listed.include?(item)

        Item.new(item, rows.sort_by { |row| [ItemPrice.price_types[row.price_type], row.time_range.to_s] })
      end.sort_by { |entry| [entry.item.class.name, entry.item.name.to_s.downcase] }
    end
  end
end
