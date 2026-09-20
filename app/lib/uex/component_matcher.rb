# frozen_string_literal: true

module Uex
  # Which `Component` a UEX item is, if any.
  #
  # Two things make this unlike the commodity matcher. There is no `uex_id`
  # column to join on, so every run resolves from scratch; and a component name
  # is not unique -- the game files carry a row per mount, so twelve components
  # are called "VariPuck S3 Gimbal Mount" and only one of them is the thing a
  # shop sells.
  class ComponentMatcher
    # UEX item id => our Component sc_key, for the ones no rule resolves.
    # Maintained by hand, the same as Uex::CommodityMatcher::MAPPINGS.
    #
    # Only where both sides plainly name the same part. Where several of ours
    # share the name and none is obviously the shop's, the row is reported as
    # ambiguous rather than guessed at: a wrong entry here prices a ship-bespoke
    # mount nobody can buy.
    MAPPINGS = {
      # "RN-7s" is the MISC standard nozzle; the other three of that name are
      # arm-only nozzles bolted to a Starfarer or a Starlite.
      776 => "fuel_nozzle_misc_nozzlestandard",
      # The other "Greycat ROC Ore Pod" is the game files' template entry.
      4396 => "cargo_groundvehiclemining_pod_roc"
    }.freeze

    attr_reader :misses, :ambiguous, :stale_mappings

    def initialize(scope: Component.with_facts(true).catalogued)
      components = scope.pluck(:id, :name, :sc_ref, :sc_key)

      @by_sc_key = components.index_by { |_, _, _, sc_key| sc_key }
      @by_sc_ref = components.select { |_, _, sc_ref, _| sc_ref.present? }
        .index_by { |_, _, sc_ref, _| sc_ref.downcase }
      @by_name = components.group_by { |_, name, _, _| normalize(name) }

      @misses = []
      @ambiguous = []
      @stale_mappings = []
    end

    # The component id, or nil with the row recorded for the report.
    def match(item)
      mapped = MAPPINGS[item["id_item"]]

      if mapped.present?
        component = @by_sc_key[mapped]

        # The hand-written mapping is an override, so a wrong resolution can
        # always be corrected without changing a rule.
        return component.first if component.present?

        # An entry naming an sc_key the catalogue no longer has. Recorded rather
        # than fallen through: the mapping exists *because* the rules cannot be
        # trusted for this item, so trying them again is the guess it was written
        # to prevent -- and silently returning nil would drop the price from
        # every report as well as from the catalogue.
        @stale_mappings << [item, mapped]
        return nil
      end

      uuid = item["item_uuid"].to_s.downcase
      by_ref = @by_sc_ref[uuid] if uuid.present?

      # `sc_ref` is the game file's own id on both sides, so it names one
      # component and names the right one. Tried first for that reason.
      return by_ref.first if by_ref.present?

      candidates = @by_name[normalize(item["item_name"])]

      if candidates.blank?
        @misses << item
        return nil
      end

      # A name several components answer to cannot say which of them the shop
      # stocks, and the wrong choice puts a price on a mount that is welded to
      # one ship. Reported so a `MAPPINGS` entry can settle it.
      if candidates.size > 1
        @ambiguous << [item, candidates.map { |_, name, _, sc_key| sc_key }]
        return nil
      end

      candidates.first.first
    end

    # Punctuation and case are the only things that differ for the names that do
    # line up. Anything further apart belongs in MAPPINGS rather than in a rule
    # inferred from a couple of examples.
    private def normalize(value)
      value.to_s.downcase.gsub(/[^a-z0-9]+/, " ").strip
    end
  end
end
