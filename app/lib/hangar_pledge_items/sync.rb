# frozen_string_literal: true

module HangarPledgeItems
  # Replaces a user's paints, hangar flair and FPS equipment with the ones a
  # hangar sync read. The pledge list is the whole truth: a melted or gifted
  # pledge simply stops being listed, so anything not in `items` goes.
  class Sync
    KINDS_BY_ITEM_TYPE = {"skin" => "paint", "flair" => "flair", "equipment" => "equipment"}.freeze

    # RSI gives the items it lists under "Also Contains" no kind at all, and
    # labels coins, statues and ship models "FPS Equipment" as often as gear.
    # An extra calling itself a paint is one. Otherwise only what the equipment
    # catalogue knows is gear, and everything else is kept with the flair: a
    # list of flair words would miss every new kind of decoration RSI sells.
    EXTRA_ITEM_TYPE = "extra"

    CATALOGUED_ITEM_TYPES = [EXTRA_ITEM_TYPE, "equipment"].freeze

    PAINT_WORDS = %w[paint livery].freeze

    attr_reader :user, :items, :kinds, :keep_unlisted

    # The kind each item would be stored as, or nil for one it cannot store.
    def self.kinds_for(items)
      catalogue = (EquipmentCatalogue.new if items.any? { |item| CATALOGUED_ITEM_TYPES.include?(item[:type].to_s) })

      items.map do |item|
        next unless item[:id].present? && item[:name].present?

        type = item[:type].to_s
        next KINDS_BY_ITEM_TYPE[type] unless CATALOGUED_ITEM_TYPES.include?(type)

        if type == EXTRA_ITEM_TYPE && EquipmentCatalogue.words(item[:name]).intersect?(PAINT_WORDS)
          "paint"
        elsif catalogue.include?(item[:name])
          "equipment"
        else
          "flair"
        end
      end
    end

    # RSI and the game files name one piece of gear in different words, orders
    # and spellings: "RSI Zeus ‘Solar’ Helmet" is "Zeus Exploration Helmet
    # Solar", "Enjakte Knife" is "Njakte Knife", "Doomsday Skullcap Helmet" is
    # "Skullcap Helmet". A name counts as gear when every word of it, less up
    # to a few leading brand words, is in a catalogue name, or every word of
    # one is in it. The words left must hold two, or one model code like
    # "P4-AR": one plain word would match far too much. RSI cuts long names
    # short with "...", leaving the last word a prefix.
    class EquipmentCatalogue
      MIN_WORDS = 2
      MAX_BRAND_WORDS = 3

      TRUNCATION = /(\.\.\.|…)\z/

      def self.words(name)
        name.to_s.downcase.gsub(/[^[:alnum:]\s-]/, " ").split.grep(/[[:alnum:]]/).uniq
      end

      def initialize
        @names = Equipment.where.not(name: nil).distinct.pluck(:name).map { |name| self.class.words(name) }
        @by_word = Hash.new { |hash, word| hash[word] = [] }
        @names.each_with_index { |words, index| words.each { |word| @by_word[word] << index } }
      end

      def include?(name)
        words = self.class.words(name)
        prefix = words.pop if name.strip.match?(TRUNCATION)

        words.flat_map { |word| @by_word.fetch(word, []) }.uniq.any? do |index|
          catalogued = @names[index]

          names_gear?(words, prefix, catalogued) || names_whole?(catalogued, words, prefix)
        end
      end

      # Every word of the RSI name is in the catalogued one, but for a few
      # leading brand words.
      private def names_gear?(words, prefix, catalogued)
        return false if prefix && catalogued.none? { |word| word.start_with?(prefix) }

        brand = missing(words, catalogued).size
        return false if brand > MAX_BRAND_WORDS || missing(words.first(brand), catalogued).size != brand

        rest = words.drop(brand)
        rest.size + (prefix ? 1 : 0) >= MIN_WORDS || rest.any? { |word| word.match?(/\d/) && word.match?(/[a-z]/) }
      end

      # Every word of the catalogued name is in the RSI one.
      private def names_whole?(catalogued, words, prefix)
        left = missing(catalogued, words)
        left.pop if prefix && left.size == 1 && left.last.start_with?(prefix)

        catalogued.size >= MIN_WORDS && left.empty?
      end

      private def missing(words, others)
        words.reject { |word| others.any? { |other| same_word?(word, other) } }
      end

      private def same_word?(word, other)
        word == other || word.delete_suffix("s") == other.delete_suffix("s") ||
          ([word.size, other.size].min >= 5 && DidYouMean::Levenshtein.distance(word, other) <= 1)
      end
    end

    # `kinds` the user chose not to sync are left exactly as stored, not
    # emptied: switching paints off is no statement that they are gone.
    #
    # `keep_unlisted` is for a pledge list read only in part: an item it could
    # not read is no statement that the pledge is gone either.
    #
    # `item_kinds` is `kinds_for(items)`, for a caller that already has it.
    def initialize(user, items, kinds: HangarPledgeItem::KINDS, keep_unlisted: false, item_kinds: nil)
      @user = user
      @kinds = kinds
      @keep_unlisted = keep_unlisted
      @items = items.zip(item_kinds || self.class.kinds_for(items))
        .select { |_item, kind| kinds.include?(kind) }
        .map { |item, kind| item.merge(kind:) }
    end

    # The ids stored for each kind it synced.
    def run
      return {} if kinds.empty?

      rows = build_rows

      # The user row as a mutex: two overlapping syncs would each delete against
      # their own list before either inserted, and leave the union of both.
      user.with_lock do
        kept = if rows.any?
          HangarPledgeItem.upsert_all(
            rows,
            unique_by: :index_hangar_pledge_items_on_user_kind_pledge_name,
            returning: %w[id kind]
          ).to_a
        else
          []
        end

        user.hangar_pledge_items.where(kind: kinds).where.not(id: kept.pluck("id")).delete_all unless keep_unlisted

        kinds.index_with { |kind| kept.select { |row| row["kind"] == kind }.pluck("id") }
      end
    end

    # A pledge can hold the same poster twice, which RSI lists as two items.
    private def build_rows
      items.group_by { |item| [item[:kind], item[:id].to_s, item[:name].strip] }
        .map do |(kind, rsi_pledge_id, name), group|
          {
            user_id: user.id,
            kind:,
            rsi_pledge_id:,
            name:,
            quantity: group.size,
            image_url: group.filter_map { |item| item[:image].presence }.first,
            pledge_name: group.first[:pledge_name].presence,
            pledge_value: group.first[:pledge_value].presence,
            pledge_item_count: group.first[:pledge_item_count].presence,
            pledge_created_on: group.first[:pledge_created_on].presence,
            meltable: ActiveModel::Type::Boolean.new.cast(group.first[:meltable]) || false
          }
        end
    end
  end
end
