# frozen_string_literal: true

module Uex
  # Which `Equipment` a UEX item is, if any. Armour sets and clothing repeat a
  # piece name across colourways, each with a record of its own, so a name alone
  # often cannot say which one the shop stocks.
  class EquipmentMatcher < ItemMatcher
    # UEX item id => our Equipment sc_key, for the ones no rule resolves.
    # Maintained by hand, the same as Uex::ComponentMatcher::MAPPINGS.
    MAPPINGS = {
      # Each of these weapon skins has a hidden `_tow` twin under the same name.
      # The plain record is the one the catalogue lists.
      1231 => "behr_rifle_ballistic_01_white02",
      1591 => "behr_smg_ballistic_01_white02",
      1672 => "klwe_rifle_energy_01_white02",
      # Both Nightstalker records are hidden, so the catalogue cannot decide
      # this one; the plain record is taken to match the three above.
      1238 => "ksar_smg_energy_01_black02",
      # UEX spaces the size ("Emod Stabilizer 1"); the game files do not.
      538 => "arma_barrel_stab_s1",
      62 => "arma_barrel_stab_s2",
      539 => "arma_barrel_stab_s3",
      # UEX spells the colourway "Gray", the game files "Grey".
      1968 => "vgl_armor_light_arms_01_01_10",
      3524 => "vgl_armor_light_helmet_01_01_07",
      3526 => "vgl_armor_light_core_01_01_10"
    }.freeze

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
