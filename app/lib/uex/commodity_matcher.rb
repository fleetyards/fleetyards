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
