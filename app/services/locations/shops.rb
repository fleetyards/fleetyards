# frozen_string_literal: true

module Locations
  # The shops at a place, each with how many things it sells or rents and
  # what kinds of thing they are. What they are is the shop's own page.
  class Shops
    Summary = Struct.new(:shop, :items_count, :categories)

    def initialize(location)
      @location = location
    end

    def call
      shops = Shop.where(location: @location).with_attached_image.order(:name).to_a
      items = ItemPrice.where(shop_id: shops.map(&:id)).includes(:item).group_by(&:shop_id)

      shops.filter_map do |shop|
        things = Array.wrap(items[shop.id]).filter_map(&:item).uniq
        next if things.empty?

        Summary.new(shop, things.size, ::Shops::Categories.for(things))
      end
    end
  end
end
