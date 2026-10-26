# frozen_string_literal: true

module Carts
  # Where to buy what a user has in their cart: each line at the place it is
  # pinned to, else where the strategy sends it, and the lines grouped by place
  # so the trip reads as a list of stops. `cheapest` sends every line to its
  # cheapest place; `stops` and `distance` trade price for a shorter trip.
  #
  # Commodities are priced per terminal and gear per shop, and some gear prices
  # name a place we could not match to either. A price's place is therefore the
  # shop's location, else the terminal's, else the name UEX gave it.
  class TripPlan
    # A line may be for an item or place a later build retired, so names come
    # off `last_build` as well as the current one.
    BUILDS = %i[build last_build].freeze
    PLACE = {location: [*BUILDS, {parent: [*BUILDS, {parent: BUILDS}], system: BUILDS}]}.freeze

    STRATEGIES = %w[cheapest stops distance].freeze

    # Locations carry no coordinates, so `distance` counts hops in the location
    # tree: another place on the same planet or moon, another planet or moon,
    # another system.
    HOP_COST = {place: 1, body: 3, system: 10}.freeze
    BODY_KINDS = %w[planet moon].freeze
    ITEM_LINKS = [*BUILDS, {item_prices: {shop: PLACE, terminal: PLACE}}].freeze

    Line = Struct.new(:cart_item, :offers, :price) do
      def item = cart_item.item

      def unit_price = price&.price

      def total = unit_price && (unit_price * cart_item.quantity)

      def available? = price.present?

      def pinned? = price.present? && price.id == cart_item.item_price_id

      def cheapest? = price.present? && price.id == offers.first&.id
    end

    Group = Struct.new(:key, :name, :location, :system_name, :lines) do
      def subtotal = lines.sum(&:total)
    end

    attr_reader :lines, :strategy

    def initialize(cart_items, strategy: nil)
      @strategy = STRATEGIES.include?(strategy.to_s) ? strategy.to_s : "cheapest"
      cart_items = cart_items.includes(:item).order(:created_at).to_a.select(&:item)
      items = cart_items.map(&:item)
      ActiveRecord::Associations::Preloader.new(records: items, associations: ITEM_LINKS).call

      @lines = cart_items.map { |cart_item| build_line(cart_item) }
      shorten_trip unless @strategy == "cheapest"
    end

    def groups
      @groups ||= lines.select(&:available?)
        .group_by { |line| place_of(line.price)[:key] }
        .map { |_key, place_lines| Group.new(**place_of(place_lines.first.price), lines: place_lines) }
        .sort_by { |group| [group.system_name.to_s, body_name(group.location), group.name.to_s] }
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

    # Greedy set cover: keep adding the place that serves the most lines still
    # without one for the least added trip, then send every line to its
    # cheapest place on the trip. Pinned lines stay put and seed the trip.
    private def shorten_trip
      trip = lines.select(&:pinned?).map { |line| trip_keys(line.price) }.uniq
      open = lines.select { |line| line.available? && !line.pinned? }.to_set

      offers_by_place = Hash.new { |hash, key| hash[key] = [] }
      lines_by_place = Hash.new { |hash, key| hash[key] = Set.new }
      open.each do |line|
        line.offers.each do |offer|
          place = trip_keys(offer)[:place]
          offers_by_place[place] << offer
          lines_by_place[place] << line
        end
      end
      trip.each { |keys| open -= lines_by_place[keys[:place]] }

      until open.empty?
        place, = offers_by_place.min_by do |candidate, offers|
          served = (lines_by_place[candidate] & open).size
          next [Float::INFINITY] if served.zero?

          [(trip_cost(trip + [trip_keys(offers.first)]) - trip_cost(trip)).fdiv(served), offers.sum(&:price)]
        end
        trip |= [trip_keys(offers_by_place[place].first)]
        open -= lines_by_place[place]
      end

      on_trip = trip.map { |keys| keys[:place] }.to_set
      lines.each do |line|
        next if line.pinned? || !line.available?

        line.price = line.offers.select { |offer| on_trip.include?(trip_keys(offer)[:place]) }.min_by(&:price) || line.price
      end
    end

    private def trip_cost(trip)
      return trip.size if strategy == "stops"

      systems = trip.map { |keys| keys[:system] }.uniq.size
      bodies = trip.map { |keys| keys[:body] }.uniq.size

      (HOP_COST[:place] * trip.size) + (HOP_COST[:body] * bodies) + (HOP_COST[:system] * [systems - 1, 0].max)
    end

    private def trip_keys(price)
      @trip_keys ||= {}
      @trip_keys[price.id] ||= begin
        place = place_of(price)
        body = body_of(place[:location])
        {place: place[:key], body: body&.id || place[:key], system: place[:system_name]}
      end
    end

    # The planet or moon a place is on or orbits; a place on neither, such as
    # a Lagrange station, is a body of its own.
    private def body_of(location)
      return if location.blank?

      ancestors = [location, location.parent, location.parent&.parent].compact
      ancestors.find { |entry| entry.kind.in?(BODY_KINDS) } || location
    end

    private def body_name(location)
      body_of(location)&.name.to_s
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
