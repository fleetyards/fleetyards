# frozen_string_literal: true

module Locations
  # The shops at a place, each with how many things it sells or rents, by
  # kind. What they are is the shop's own page.
  class Shops
    Summary = Struct.new(:shop, :items_count, :counts)

    def initialize(location)
      @location = location
    end

    def call
      shops = Shop.where(location: @location).with_attached_image.order(:name).to_a
      counts = ItemPrice.where(shop_id: shops.map(&:id)).group(:shop_id, :item_type).distinct.count(:item_id)

      shops.filter_map do |shop|
        by_type = counts.select { |(shop_id, _type), _count| shop_id == shop.id }
          .map { |(_shop_id, type), count| {item_type: type, count:} }
          .sort_by { |entry| -entry[:count] }
        next if by_type.empty?

        Summary.new(shop, by_type.sum { |entry| entry[:count] }, by_type)
      end
    end
  end
end
