# frozen_string_literal: true

module Locations
  # Every place in a system the game puts on its starmap, at its position: what
  # the starmap page draws a system and its bodies from. One flat list, since
  # the page groups it by level itself.
  #
  # A place the build being served has but does not place -- the 5.0 PTU export
  # carries Nyx II and III without a position yet -- is drawn where the latest
  # build that does place it puts it. Places the game places more than once, or
  # never, have no position and are left out; so are the asteroid clusters it
  # generates.
  class Starmap
    Place = Struct.new(:location, :lagrange_point, :gateway, :position, :radius)

    attr_reader :system

    def initialize(location)
      @system = location.system || location
    end

    def call
      places.filter_map do |place|
        fallback = place.position ? nil : placed_build(place)
        position = place.position || fallback&.position
        next if position.blank?

        Place.new(
          location: place,
          lagrange_point: place.sc_key.match?(::Locations::Tree::LAGRANGE_KEY),
          gateway: place.sc_key.match?(::Locations::Tree::GATEWAY_KEY),
          position:,
          radius: fallback ? fallback.radius : place.radius
        )
      end
    end

    private def placed_build(place)
      place.builds.select(&:position).max_by(&:created_at)
    end

    private def places
      placed_anywhere = LocationBuild.where.not(position: nil).select(:location_id)

      Location.listed.current_version
        .with_facts
        .where(system_id: system.id)
        .where("#{Location.fact_sql(:position)} IS NOT NULL OR locations.id IN (?)", placed_anywhere)
        .includes(:parent, :build, :last_build, :builds, surfaces: ::LocationSurface::ROLES.map { |role| {"#{role}_attachment": :blob} })
        .order(:sc_key)
    end
  end
end
