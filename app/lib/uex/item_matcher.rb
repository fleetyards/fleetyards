# frozen_string_literal: true

module Uex
  # Which of our catalogue records a UEX item is, if any.
  #
  # Two things make this unlike the commodity matcher. There is no `uex_id`
  # column to join on, so every run resolves from scratch; and a name is not
  # unique -- the game files carry a row per mount or per colourway, so a name
  # can answer to a dozen records when only one of them is the thing a shop
  # sells.
  #
  # Subclasses supply MAPPINGS (UEX item id => our sc_key, for the ones no rule
  # resolves) and the scope a match may land in.
  class ItemMatcher
    MAPPINGS = {}.freeze

    attr_reader :misses, :ambiguous, :stale_mappings

    def initialize(scope:)
      records = pluck_records(scope)

      @by_sc_key = records.index_by { |_, _, _, sc_key| sc_key }
      @by_sc_ref = records.select { |_, _, sc_ref, _| sc_ref.present? }
        .index_by { |_, _, sc_ref, _| sc_ref.downcase }
      @by_name = records.group_by { |_, name, _, _| normalize(name) }

      @misses = []
      @ambiguous = []
      @stale_mappings = []
    end

    # The record id, or nil with the row recorded for the report.
    def match(item)
      mapped = self.class::MAPPINGS[item["id_item"]]

      if mapped.present?
        record = @by_sc_key[mapped]

        # The hand-written mapping is an override, so a wrong resolution can
        # always be corrected without changing a rule.
        return record.first if record.present?

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

      # `sc_ref` is the game file's own id on both sides, so it names one record
      # and names the right one. Tried first for that reason.
      return (visible_namesake(by_ref) || by_ref).first if by_ref.present?

      candidates = @by_name[normalize(item["item_name"])]

      if candidates.blank?
        @misses << item
        return nil
      end

      # A name several records answer to cannot say which of them the shop
      # stocks. Reported so a `MAPPINGS` entry can settle it.
      if candidates.size > 1
        @ambiguous << [item, candidates.map { |_, _, _, sc_key| sc_key }]
        return nil
      end

      candidates.first.first
    end

    # UEX hands out the uuid of a hidden twin for some items -- the P4-AR, C54
    # and Custodian carry their contested-zone reward's, and armour its Carrack
    # or microTech edition's. A hidden record has no page, so a price on it is
    # one nobody sees while the record they do see shows none. Only where a
    # single visible record shares the name: two would be a guess.
    private def visible_namesake(record)
      _, name, _, _, hidden = record
      return unless hidden

      visible = @by_name[normalize(name)].reject { |_, _, _, _, namesake_hidden| namesake_hidden }
      visible.first if visible.one?
    end

    private def pluck_records(scope)
      scope.pluck(:id, :name, :sc_ref, :sc_key, scope.model.fact_sql(:hidden))
    end

    # Punctuation and case are the only things that differ for the names that do
    # line up. Anything further apart belongs in MAPPINGS rather than in a rule
    # inferred from a couple of examples.
    private def normalize(value)
      value.to_s.downcase.gsub(/[^a-z0-9]+/, " ").strip
    end
  end
end
