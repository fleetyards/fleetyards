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
      3526 => "vgl_armor_light_core_01_01_10",
      # The game files misspell these, and UEX carries no uuid to match on.
      2918 => "987_pants_01_01_03",
      2924 => "987_shirt_03_01_18",
      4049 => "grin_toxic_jumpsuit_01_01_02",
      4107 => "alb_jacket_05_01_16"
    }.freeze

    # The whole build we are on, hidden records included. Weapon skins are hidden
    # from the catalogue but are real shop items, and leaving them out turned two
    # dozen of them into permanent "cannot place" lines nobody can act on.
    def initialize(scope: Equipment.with_facts(true))
      super

      @visible_by_name = @by_name.transform_values do |records|
        records.reject { |_, _, _, _, hidden| hidden }
      end
    end

    # UEX hands out the uuid of a hidden twin for some items -- the P4-AR, C54
    # and Custodian carry their contested-zone reward's, and armour its Carrack
    # or microTech edition's. Hidden equipment has no page, so a price on it is
    # one nobody sees while the record they do see shows none. Only where a
    # single visible record shares the name: two would be a guess. And only
    # where UEX uses that name too -- one of its own says it means the edition.
    private def resolve_ref(record, item)
      _, name, _, _, hidden = record
      return record if !hidden || name.blank?
      return record unless normalize(item["item_name"]) == normalize(name)

      visible = @visible_by_name[normalize(name)]
      visible&.one? ? visible.first : record
    end

    # The name the build we are on serves, which is the one a reader sees --
    # the column is only its fallback.
    private def pluck_records(scope)
      scope.pluck(
        Arel.sql("equipment.id"), Equipment.fact_sql(:name),
        Arel.sql("equipment.sc_ref"), Arel.sql("equipment.sc_key"), Equipment.fact_sql(:hidden)
      )
    end
  end
end
