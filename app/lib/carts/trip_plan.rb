# frozen_string_literal: true

module Carts
  # Where to buy what a user has in their cart: each line at the place it is
  # pinned to, else the cheapest place selling it, and the lines grouped by
  # place so the trip reads as a list of stops.
  #
  # Commodities are priced per terminal and gear per shop, and some gear prices
  # name a place we could not match to either. A price's place is therefore the
  # shop's location, else the terminal's, else the name UEX gave it.
  class TripPlan
    # A line may be for an item or place a later build retired, so names come
    # off `last_build` as well as the current one.
    BUILDS = %i[build last_build].freeze
    PLACE = {location: [*BUILDS, {parent: BUILDS, system: BUILDS}]}.freeze
    ITEM_LINKS = [*BUILDS, {item_prices: {shop: PLACE, terminal: PLACE}}].freeze

    Line = Struct.new(:cart_item, :offers, :price) do
      def item = cart_item.item

      def unit_price = price&.price

      def total = unit_price && (unit_price * cart_item.quantity)

      def available? = price.present?

      def pinned? = price.present? && price.id == cart_item.item_price_id
    end

    Group = Struct.new(:key, :name, :location, :system_name, :lines) do
      def subtotal = lines.sum(&:total)
    end

    attr_reader :lines

    def initialize(cart_items)
      cart_items = cart_items.includes(:item).order(:created_at).to_a.select(&:item)
      items = cart_items.map(&:item)
      ActiveRecord::Associations::Preloader.new(records: items, associations: ITEM_LINKS).call

      @lines = cart_items.map { |cart_item| build_line(cart_item) }
    end

    def groups
      @groups ||= lines.select(&:available?)
        .group_by { |line| place_of(line.price)[:key] }
        .map { |key, place_lines| Group.new(**place_of(place_lines.first.price), key:, lines: place_lines) }
        .sort_by { |group| [group.system_name.to_s, group.name.to_s] }
    end

    def total
      lines.select(&:available?).sum(&:total)
    end

    def unavailable_count
      lines.count { |line| !line.available? }
    end

    private def build_line(cart_item)
      item = cart_item.item
      offers = item.sold_at.select(&:price)
      # Read off all of the item's prices, not just `offers`: those keep one
      # quote per place, and the pinned one may be a pricier quote at the same place.
      pinned = item.item_prices.find { |price| price.id == cart_item.item_price_id && price.sell? && price.price } if cart_item.item_price_id

      Line.new(cart_item:, offers:, price: pinned || offers.first)
    end

    private def place_of(price)
      location = price.shop&.location || price.terminal&.location

      if location
        {key: location.id, name: location.name, location:, system_name: location.system&.name}
      else
        {key: price.location, name: price.location, location: nil, system_name: price.terminal&.star_system}
      end
    end
  end
end
