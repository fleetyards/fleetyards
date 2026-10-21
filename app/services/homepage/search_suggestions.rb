# frozen_string_literal: true

module Homepage
  # What the homepage offers to search for: one ship, one place and one item,
  # drawn from the catalogue at random each visit. Each is a name the search
  # answers, taken from the same listed rows it searches.
  class SearchSuggestions
    # Places a reader would recognise by name. A nav point or an anomaly is
    # real, but tells a newcomer nothing -- and stations are mostly named by
    # code ("PYR1 L2"), so they are left out with them.
    LOCATION_KINDS = %w[planet moon city spaceport].freeze

    # Components people come looking for; the rest are mostly paints, doors
    # and thrusters.
    COMPONENT_CATEGORIES = %w[weapons shieldgenerator quantumdrive powerplant cooler].freeze

    def call
      [ship, place, item].compact
    end

    private def ship
      random_name(::Catalogue::TokenResolver.listed("ship"), "ship")
    end

    private def place
      name = ::Catalogue::TokenResolver.name_sql("location")
      # A name with a digit in it is a designation, not a name.
      scope = ::Catalogue::TokenResolver.listed("location")
        .where(Location.fact_sql(:kind).in(LOCATION_KINDS))
        .where("#{name} !~ '[0-9]'")

      random_name(scope, "location")
    end

    # A component or a commodity, a coin toss between them, so a visit is as
    # likely to suggest ore as a gun.
    private def item
      component = -> {
        scope = ::Catalogue::TokenResolver.listed("component")
          .where(Component.fact_sql(:category).in(COMPONENT_CATEGORIES))

        random_name(scope, "component")
      }
      commodity = -> { random_name(::Catalogue::TokenResolver.listed("commodity"), "commodity") }

      first, second = [component, commodity].shuffle

      first.call || second.call
    end

    private def random_name(scope, prefix)
      scope.reorder(Arel.sql("random()")).limit(1).pick(Arel.sql(::Catalogue::TokenResolver.name_sql(prefix)))
    end
  end
end
