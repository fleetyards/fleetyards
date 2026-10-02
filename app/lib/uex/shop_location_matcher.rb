# frozen_string_literal: true

module Uex
  # The shop and the place a UEX item price names. UEX writes both into one
  # location string -- "Casaba Outlet - Everus Harbor", "Regal Luxury Rentals -
  # New Babbage Interstellar Spaceport - New Babbage" -- with the shop first
  # and the place, then any wider place, after it.
  #
  # 318 of the 323 shop strings in the UEX feed resolve. The rest name nothing
  # the starmap carries: "Frostbite", "Orison General Hospital", a string with
  # no separator.
  class ShopLocationMatcher
    SEPARATOR = /\s+-\s+/
    ROOM_KINDS = %w[outpost clinic district].freeze

    # Every price at a shop, linked to that shop, which is made the first time
    # UEX names it. Run after a price sync and after a load of the places,
    # which may have arrived after it.
    #
    # A moved link touches the price and what it prices: the catalogue caches
    # an item's prices, shop links and all, under the newest of those.
    # A shop no price names any more is gone from UEX, so it goes too.
    def self.relink(prices = ItemPrice.where(terminal_id: nil))
      matcher = new
      shops = {}
      now = Time.current

      moved = prices.distinct.pluck(:location).sum do |location|
        shop_name, location_id = matcher.match(location)
        shop_id = if location_id
          shops[[location_id, shop_name]] ||= Shop.find_or_create_by!(location_id:, name: shop_name).id
        end

        changed = prices.where(location:).where("shop_id IS DISTINCT FROM ?", shop_id)
        touch_items(changed, now)
        changed.update_all(shop_id:, updated_at: now)
      end

      Shop.where.missing(:item_prices).destroy_all

      moved
    end

    private_class_method def self.touch_items(prices, now)
      prices.distinct.pluck(:item_type, :item_id).group_by(&:first).each do |item_type, rows|
        item_type.safe_constantize&.where(id: rows.map(&:last))&.update_all(updated_at: now)
      end
    end

    # [shop name, place id], or nils when the place cannot be told.
    def match(value)
      parts = value.to_s.split(SEPARATOR).map(&:strip).compact_blank
      return [nil, nil] if parts.size < 2

      place = parts.drop(1).lazy.filter_map { |part| place_for(part) }.first
      place ? [parts.first, place[:id]] : [nil, nil]
    end

    private def place_for(part)
      name = normalize(part)
      system = part[/\(([^)]*)\)\s*\z/, 1]&.downcase

      candidates = places_named.fetch(name, [])
      candidates = places.select { |place| place[:name].start_with?(name) } if candidates.empty? && name.length >= 4
      candidates = candidates.select { |place| place[:system]&.start_with?(system) } if system && candidates.size > 1

      # A shop is at a station or a city before an outpost, or a room in one,
      # of the same name: "Seraphim" is Seraphim Station, not its clinic.
      settled = candidates.reject { |place| ROOM_KINDS.include?(place[:kind]) }
      candidates = settled if settled.any?

      place = candidates.uniq { |candidate| candidate[:id] }.one? ? candidates.first : nil
      place && rest_stop_at(place) || place
    end

    # "HUR-L1" names the point; the shops are in the rest stop at it.
    private def rest_stop_at(place)
      return unless place[:sc_key].match?(::Locations::Tree::LAGRANGE_KEY)

      stops = places.select { |candidate| candidate[:parent_id] == place[:id] && candidate[:sc_key].start_with?("RR_") }
      stops.first if stops.one?
    end

    # "Pyro Gateway (Stanton)" is Pyro Gateway; the bracket says which system.
    private def normalize(value)
      value.to_s.downcase.sub(/\s*\([^)]*\)\s*\z/, "").gsub(/[^a-z0-9]/, "")
    end

    private def places_named
      @places_named ||= places.group_by { |place| place[:name] }
    end

    private def places
      @places ||= begin
        systems = Location.current_version.where(kind: "system").pluck(:id, :name).to_h

        Location.current_version.where.not(kind: "system")
          .pluck(:id, :name, :kind, :sc_key, :parent_id, :system_id)
          .map do |id, name, kind, sc_key, parent_id, system_id|
            {id:, name: normalize(name), kind:, sc_key:, parent_id:, system: systems[system_id]&.downcase}
          end
      end
    end
  end
end
