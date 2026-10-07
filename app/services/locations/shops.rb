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
      selling(Shop.where(location: @location).with_attached_image.order(:name).to_a).map do |shop, things|
        Summary.new(shop, things.size, ::Shops::Categories.for(things))
      end
    end

    # The same shops, without what they sell.
    def shops
      selling(Shop.where(location: @location).order(:name).to_a).keys
    end

    # Each shop that sells something its catalogue lists, with those things.
    private def selling(shops)
      items = ItemPrice.where(shop_id: shops.map(&:id)).includes(:item).group_by(&:shop_id)
      listed = ::Shops::Listing.listed(items.values.flatten.filter_map(&:item).uniq).to_set

      shops.each_with_object({}) do |shop, found|
        things = Array.wrap(items[shop.id]).filter_map(&:item).uniq.select { |item| listed.include?(item) }
        found[shop] = things if things.any?
      end
    end
  end
end
