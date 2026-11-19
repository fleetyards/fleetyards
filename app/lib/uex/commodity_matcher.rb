# frozen_string_literal: true

module Uex
  class CommodityMatcher
    # UEX commodity id => our Commodity sc_key, for the ones no name form
    # resolves. Maintained by hand, same as Uex::VehicleMatcher::MAPPINGS.
    #
    # Kept to cases where both sides clearly name the same good. UEX also lists
    # near-neighbours that are NOT the same thing — "Organics" is a bulk trade
    # good, not our mission-crate "Organs"; "SLAM" is the cut drug, not our
    # "Uncut SLAM" — and mapping those would attach a price to the wrong item.
    MAPPINGS = {
      181 => "items_commodities_constructionmaterialspowder",  # Construction Material Rubble
      182 => "items_commodities_constructionmaterialsscraps",  # Construction Material Pebbles
      183 => "items_commodities_constructionmaterialschunks",  # Construction Material Salvage
      137 => "items_commodities_lastaprene",                   # Lastaphrene, spelled with an h
      145 => "items_commodities_spiral",                       # Lunes, ours adds "(Spiral Fruit)"
      161 => "items_commodities_raw_silicon",                  # Silicon (Raw) vs our Raw Silicon
      210 => "items_commodities_raw_ouratite",                 # Ouratite (Raw) vs our Raw Ouratite
      125 => "items_commodities_raw_ice",                      # Ice (Raw) vs our Raw Ice
      162 => "items_commodities_stileron_ore",                 # Stileron (Raw), the game calls it (Ore)
      40 => "items_commodities_hephaestanite_raw"              # Hephaestanite (Raw), ours truncates to (R)
    }.freeze

    # Our commodities UEX has no row for: mission crates, harvestables, creature
    # parts and event items it does not trade. Left out of the unmapped report
    # so that report only shows what is new. The name match still runs over
    # them, so one that UEX starts listing maps itself.
    UNTRACKED = %w[
      items_commodities_amiantpod
      items_commodities_ammocrate
      items_commodities_biologicalsamples
      items_commodities_evafuel
      items_commodities_flareweedstalk
      items_commodities_fotiascrub
      items_commodities_gatalafungi
      items_commodities_genmodseeds
      items_commodities_hlx99hyperprocessors
      items_commodities_kopionhorn_savannah
      items_commodities_medgel
      items_commodities_medpens
      items_commodities_militarysupplies
      items_commodities_mixedmining
      items_commodities_mobyglass
      items_commodities_organs
      items_commodities_oxypens
      items_commodities_oza
      items_commodities_pingala
      items_commodities_pouchweed
      items_commodities_quasigrazeregg
      items_commodities_quasigrazeregg_boreal
      items_commodities_quasigrazeregg_grassland
      items_commodities_quasigrazeregg_jungle
      items_commodities_quasigrazeregg_tundra
      items_commodities_quasigrazertongue
      items_commodities_rs1odyseyspacesuits
      items_commodities_shipammo_size_8
      items_commodities_shipammo_size_9
      items_commodities_special_lunar_envelope
      items_commodities_special_lunar_envelope_1_ram_a
      items_commodities_stolengoods
      items_commodities_uncutslam
      items_commodities_valakkarfang
      items_commodities_valakkarfang_adult
      items_commodities_valakkarfang_adult_irradiated
      items_commodities_valakkarfang_apex
      items_commodities_valakkarfang_apex_irradiated
      items_commodities_valakkarfang_juvenile
      items_commodities_valakkarfang_juvenile_irradiated
      items_commodities_valakkaregg_irradiated
      items_commodities_valakkarpearl_apex_irradiated_tier1
      items_commodities_valakkarpearl_apex_irradiated_tier2
      items_commodities_valakkarpearl_apex_irradiated_tier3
      items_commodities_valakkarpearl_apex_irradiated_tier4
      items_commodities_valakkarpearl_apex_irradiated_tier5
      items_commodities_ventslug
      items_commodities_viruscultures
      items_commodities_yormandi_eye
      items_commodities_yormandi_tongue
    ].to_set.freeze

    # UEX id => the UEX id it duplicates. A commodity carries one uex_id, so a
    # second UEX row for the same good cannot go in MAPPINGS -- it would claim
    # the commodity from the canonical row. Its prices are read as the
    # canonical row's instead.
    DUPLICATES = {
      171 => 173 # Jaclium; the game only declares Jaclium (Ore), priced alike
    }.freeze

    attr_reader :misses

    def initialize
      commodities = Commodity.select(:id, :name, :sc_key).to_a

      @by_sc_key = commodities.index_by(&:sc_key)
      @by_name = commodities.index_by { |commodity| normalize(commodity.name) }
      @misses = []
    end

    def match(row)
      commodity = lookup(row)

      @misses << row if commodity.blank?

      commodity
    end

    private def lookup(row)
      mapped = MAPPINGS[row["id"]]

      # The hand-written mapping is an override: it wins over the name match so
      # a wrong collision can always be corrected.
      return @by_sc_key[mapped] if mapped.present?

      @by_name[normalize(row["name"])]
    end

    # Punctuation and case are the only things that differ between the two
    # catalogues for the names that do line up ("Agricium (Ore)" both sides,
    # "mobyGlass" ours). Anything further apart than that belongs in MAPPINGS
    # rather than in a rule inferred from one or two examples.
    private def normalize(value)
      value.to_s.downcase.gsub(/[^a-z0-9]/, "")
    end
  end
end
