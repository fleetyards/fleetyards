# frozen_string_literal: true

module HangarPledgeItems
  # Replaces a user's paints, hangar flair, FPS equipment, CCUs and ship
  # components with the ones a hangar sync read. The pledge list is the whole truth: a melted or gifted
  # pledge simply stops being listed, so anything not in `items` goes.
  class Sync
    KINDS_BY_ITEM_TYPE = {"ccu" => "ccu", "skin" => "paint", "flair" => "flair", "equipment" => "equipment"}.freeze

    # RSI lists ship modules and ship parts alike as components; the modules are
    # fitted to a ship by the hangar sync, the parts are kept here.
    COMPONENT_ITEM_TYPE = "component"

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
        if type == COMPONENT_ITEM_TYPE
          next(::HangarModuleMapping.module?(item[:name]) ? nil : "ship_component")
        end
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

      # RSI's names for gear the game calls something else entirely, or that
      # the game's record names after another item.
      ALIASES = {
        "Scarecrow Helmet" => "The Hill Horror Helmet",
        "RRS Knife - Fallout" => 'TBF-4 "Balefire" Combat Knife',
        "CitizenCon 2948 Wearable In-Game Duster Jacket" => "Duotone Duster",
        "Luminalia Sweater" => "Good Gift Sweater"
      }.freeze

      SYNONYMS = {"trousers" => "pants"}.freeze

      TRUNCATION = /(\.\.\.|…)\z/

      def self.words(name)
        name.to_s.downcase.gsub(/[^[:alnum:]\s-]/, " ").split.grep(/[[:alnum:]]/)
          .map { |word| SYNONYMS.fetch(word, word) }.uniq
      end

      def initialize
        entries = Equipment.where.not(name: nil).order(:name, :id).pluck(:name, :id).uniq(&:first)
        @ids = entries.map(&:last)
        @names = entries.map { |name, _id| self.class.words(name) }
        @by_word = Hash.new { |hash, word| hash[word] = [] }
        @names.each_with_index { |words, index| words.each { |word| @by_word[word] << index } }
      end

      def include?(name)
        !find(name).nil?
      end

      # The id of the catalogued gear the name reads as, if any.
      def find(name)
        name = ALIASES.fetch(name.to_s.strip, name)
        words = self.class.words(name)
        prefix = words.pop if name.strip.match?(TRUNCATION)

        matches = candidates(words, prefix).select do |index|
          catalogued = @names[index]

          names_gear?(words, prefix, catalogued) || names_whole?(catalogued, words, prefix)
        end

        # The closest name wins: the same words, then the fewest.
        match = matches.min_by { |index| [(@names[index] == words) ? 0 : 1, @names[index].size, index] }
        @ids[match] if match
      end

      # Names sharing a word with the RSI one, or starting the word it was cut
      # off in: "Enjakte Kni..." shares no word with "Njakte Knife" but that.
      private def candidates(words, prefix)
        prefixed = prefix ? @by_word.keys.select { |word| word.start_with?(prefix) } : []

        (words + prefixed).flat_map { |word| @by_word.fetch(word, []) }.uniq
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

    # RSI names a ship part as the game does, but adds its size to some ("CF-117
    # Bulldog (S1)") and drops a word from others ("S2 Gimbal Mount" for
    # "VariPuck S2 Gimbal Mount"). The same name wins; otherwise the shortest
    # catalogued name holding every word of RSI's, so a plain repeater is
    # picked over its named variants.
    class ComponentCatalogue
      SIZE = /\(s\d+\)/i

      def self.words(name)
        name.to_s.downcase.gsub(SIZE, " ").gsub(/[^[:alnum:]\s-]/, " ").split
      end

      def initialize
        @entries = Component.named.where(hidden: false).pluck(:id, :name)
          .map { |id, name| [id, name, self.class.words(name)] }
      end

      def find(name)
        same = @entries.find { |_id, catalogued, _words| catalogued.casecmp?(name.to_s.strip) }
        return same.first if same

        words = self.class.words(name)
        return if words.empty?

        @entries.select { |_id, _name, catalogued| (words - catalogued).empty? }
          .min_by { |_id, catalogued, catalogued_words| [catalogued_words.size, catalogued] }&.first
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

        PaintLinker.new.link(user.hangar_pledge_items.paints.where(id: kept.pluck("id")).to_a)

        kinds.index_with { |kind| kept.select { |row| row["kind"] == kind }.pluck("id") }
      end
    end

    # A pledge can hold the same poster twice, which RSI lists as two items.
    private def build_rows
      items.group_by { |item| [item[:kind], item[:id].to_s, item[:name].strip] }
        .map do |(kind, rsi_pledge_id, name), group|
          {
            component_id: (component_catalogue.find(name) if kind == "ship_component"),
            equipment_id: (equipment_catalogue.find(name) if kind == "equipment"),
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
            rsi_page: group.first[:page].presence&.to_i,
            meltable: ActiveModel::Type::Boolean.new.cast(group.first[:meltable]) || false
          }
        end
    end

    # Built only for a run that has items of their kind: each reads a whole
    # catalogue.
    private def component_catalogue
      @component_catalogue ||= ComponentCatalogue.new
    end

    private def equipment_catalogue
      @equipment_catalogue ||= EquipmentCatalogue.new
    end
  end
end
