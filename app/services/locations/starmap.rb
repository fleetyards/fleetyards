# frozen_string_literal: true

module Locations
  # Every place in a system the game puts on its starmap, at its position: what
  # the starmap page draws a system and its bodies from. One flat list, since
  # the page groups it by level itself.
  #
  # Places the game places more than once, or not at all, have no position and
  # are left out; so are the asteroid clusters it generates.
  class Starmap
    Place = Struct.new(:location, :lagrange_point, :gateway)

    attr_reader :system

    def initialize(location)
      @system = location.system || location
    end

    def call
      places.map do |place|
        Place.new(
          location: place,
          lagrange_point: place.sc_key.match?(::Locations::Tree::LAGRANGE_KEY),
          gateway: place.sc_key.match?(::Locations::Tree::GATEWAY_KEY)
        )
      end
    end

    private def places
      Location.listed.current_version
        .with_facts
        .where(system_id: system.id)
        .where("#{Location.fact_sql(:position)} IS NOT NULL")
        .includes(:parent, :build, :last_build, surfaces: ::LocationSurface::ROLES.map { |role| {"#{role}_attachment": :blob} })
        .order(:sc_key)
    end
  end
end
