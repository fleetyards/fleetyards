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

    # Every price at a shop, linked to the shop's place. Run after a price sync
    # and after a load of the places, which may have arrived after it.
    def self.relink(prices = ItemPrice.where(terminal_id: nil))
      matcher = new

      prices.distinct.pluck(:location).sum do |location|
        shop_name, location_id = matcher.match(location)

        prices.where(location:)
          .where("location_id IS DISTINCT FROM ? OR shop_name IS DISTINCT FROM ?", location_id, shop_name)
          .update_all(location_id:, shop_name:)
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

      # A shop is at a station or a city before an outpost of the same name.
      settled = candidates.reject { |place| place[:kind] == "outpost" }
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
