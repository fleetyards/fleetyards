# frozen_string_literal: true

module Uex
  # Which `Equipment` a UEX item is, if any. Armour sets and clothing repeat a
  # piece name across colourways, each with a record of its own, so a name alone
  # often cannot say which one the shop stocks.
  class EquipmentMatcher < ItemMatcher
    # UEX item id => our Equipment sc_key, for the ones no rule resolves.
    # Maintained by hand, the same as Uex::ComponentMatcher::MAPPINGS.
    MAPPINGS = {}.freeze

    # The whole build we are on, hidden records included. Weapon skins are hidden
    # from the catalogue but are real shop items, and leaving them out turned two
    # dozen of them into permanent "cannot place" lines nobody can act on.
    def initialize(scope: Equipment.with_facts(true))
      super
    end

    # The name the build we are on serves, which is the one a reader sees --
    # the column is only its fallback.
    private def pluck_records(scope)
      scope.pluck(
        Arel.sql("equipment.id"), Equipment.fact_sql(:name),
        Arel.sql("equipment.sc_ref"), Arel.sql("equipment.sc_key")
      )
    end
  end
end
