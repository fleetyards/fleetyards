# frozen_string_literal: true

module HangarPledgeItems
  # Replaces a user's paints, hangar flair and FPS equipment with the ones a
  # hangar sync read. The pledge list is the whole truth: a melted or gifted
  # pledge simply stops being listed, so anything not in `items` goes.
  class Sync
    KINDS_BY_ITEM_TYPE = {"skin" => "paint", "flair" => "flair", "equipment" => "equipment"}.freeze

    # RSI gives the items it lists under "Also Contains" no kind at all: FPS
    # gear, posters, trophies and hangars read alike. The ones the equipment
    # catalogue knows are gear, and everything else is kept with the flair.
    EXTRA_ITEM_TYPE = "extra"

    attr_reader :user, :items, :kinds, :keep_unlisted

    # The kind each item would be stored as, or nil for one it cannot store.
    def self.kinds_for(items)
      catalogue = (EquipmentCatalogue.new if items.any? { |item| item[:type].to_s == EXTRA_ITEM_TYPE })

      items.map do |item|
        next unless item[:id].present? && item[:name].present?

        type = item[:type].to_s
        next KINDS_BY_ITEM_TYPE[type] unless type == EXTRA_ITEM_TYPE

        catalogue.include?(item[:name]) ? "equipment" : "flair"
      end
    end

    # RSI and the game files name one piece of gear in different words, orders
    # and quotes: "Tailwind ‘Drake’ Helmet" is "Tailwind Flight Helmet Drake",
    # "Doomsday Skullcap Helmet" is "Skullcap Helmet". A name counts as gear
    # when every word of it is in a catalogue name, or every word of one is in
    # it. One word alone would match far too much, and a poster or model of
    # a catalogued helmet names that helmet too.
    class EquipmentCatalogue
      MIN_WORDS = 2

      FLAIR_WORDS = %w[
        poster posters model models trophy plushie plush coin statue statuette
        figure figurine banner flag globe painting print fishtank
        collectible display miniature
      ].freeze

      def self.words(name)
        name.to_s.downcase.gsub(/[^[:alnum:]\s-]/, " ").split.uniq
      end

      def initialize
        @names = Equipment.where.not(name: nil).distinct.pluck(:name).map { |name| self.class.words(name) }
        @by_word = Hash.new { |hash, word| hash[word] = [] }
        @names.each_with_index { |words, index| words.each { |word| @by_word[word] << index } }
      end

      def include?(name)
        words = self.class.words(name)
        return false if words.intersect?(FLAIR_WORDS)

        words.flat_map { |word| @by_word.fetch(word, []) }.uniq.any? do |index|
          catalogued = @names[index]

          (words.size >= MIN_WORDS && (words - catalogued).empty?) ||
            (catalogued.size >= MIN_WORDS && (catalogued - words).empty?)
        end
      end
    end

    # `kinds` the user chose not to sync are left exactly as stored, not
    # emptied: switching paints off is no statement that they are gone.
    #
    # `keep_unlisted` is for a pledge list read only in part: an item it could
    # not read is no statement that the pledge is gone either.
    def initialize(user, items, kinds: HangarPledgeItem::KINDS, keep_unlisted: false)
      @user = user
      @kinds = kinds
      @keep_unlisted = keep_unlisted
      @items = items.zip(self.class.kinds_for(items))
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
