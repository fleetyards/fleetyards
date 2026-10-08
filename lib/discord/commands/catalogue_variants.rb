# frozen_string_literal: true

module Discord
  module Commands
    # The entries a name cannot pick out, because more than one entry of a
    # catalogue carries it -- both "Serac" coolers, both "Outpost 54"s on
    # Aberdeen. A markdown token leaves those unnamed; the bot offers each one
    # instead, told apart by what it sits in or by size and game key, and keyed
    # by id.
    #
    # Only names a handful of items share. Past that it is a generic ship part
    # -- 313 "Internal Tank"s -- that would crowd every other suggestion out.
    module CatalogueVariants
      MAX_CARRIERS = 5
      NAMES_PER_CATALOGUE = 10

      # Ids rather than slugs: a component's slug runs to 96 characters, and
      # Discord refuses a choice value over 100.
      VALUE = /\A(?<prefix>[a-z]+)~(?<id>\h{8}-\h{4}-\h{4}-\h{4}-\h{12})\z/

      Variant = Data.define(:prefix, :record) do
        def value = "#{prefix}~#{record.id}"

        def name = record.name

        def slug = record.slug

        # The game key is the one thing two carriers never share -- the slug
        # is not: the first of a name keeps the bare one. What a reader can make
        # sense of leads (LEADS): an item's size, a place's parent -- which alone
        # is not enough, as both Outpost 54s sit on Aberdeen.
        def detail
          key = record.sc_key.to_s.downcase.presence || slug

          [CatalogueVariants.lead(prefix).label.call(record).presence, key].compact.join(" · ")
        end
      end

      # What leads a variant's detail, and what reading it needs loaded.
      Lead = Data.define(:label, :preload)

      SIZE_LEAD = Lead.new(label: ->(record) { record.try(:size).presence&.then { |size| "S#{size}" } }, preload: nil)

      # A place's parent names it through its build.
      LEADS = {
        "location" => Lead.new(label: ->(record) { record.parent&.name }, preload: {parent: :build})
      }.freeze

      def self.lead(prefix)
        LEADS.fetch(prefix, SIZE_LEAD)
      end

      # A query written with a prefix searches that type alone, as the
      # resolver's own search does. Names that start with the query come
      # first, then shorter ones, so the name budget cannot drop a better
      # match for weaker ones.
      def self.search(query, within:)
        typed, query = ::Catalogue::TokenResolver.parse(query)
        return [] if query.length < 2 || query.length > ::Catalogue::TokenResolver::MAX_NAME_LENGTH

        escaped = ActiveRecord::Base.sanitize_sql_like(query.downcase)
        prefixes = typed ? within & [typed] : within

        prefixes.flat_map do |prefix|
          scope = ::Catalogue::TokenResolver.listed(prefix)
          name = Arel.sql("lower(#{model(prefix).fact_sql(:name)})")
          starts_with = Arel.sql(ActiveRecord::Base.sanitize_sql_array(["CASE WHEN #{name} LIKE ? THEN 0 ELSE 1 END", "#{escaped}%"]))

          names = scope.where("#{name} LIKE ?", "%#{escaped}%")
            .group(name)
            .having("count(*) BETWEEN 2 AND ?", MAX_CARRIERS)
            .order(starts_with, Arel.sql("length(#{name})"), name)
            .limit(NAMES_PER_CATALOGUE)
            .pluck(name)
          next [] if names.empty?

          variants(prefix, scope.where("#{name} IN (?)", names))
        end
      end

      # How many listed items carry exactly the name `query` gives, per
      # catalogue -- what is left to say about one too common to offer.
      def self.carriers(query, within:)
        typed, query = ::Catalogue::TokenResolver.parse(query)
        return {} if query.blank? || query.length > ::Catalogue::TokenResolver::MAX_NAME_LENGTH

        (typed ? within & [typed] : within).to_h { |prefix| [prefix, named(prefix, query).count] }
          .select { |_, count| count.positive? }
      end

      # The listed items of one catalogue that carry exactly `name`.
      def self.named(prefix, name)
        ::Catalogue::TokenResolver.listed(prefix).where("lower(#{model(prefix).fact_sql(:name)}) = ?", name.downcase)
      end

      # The listed entries of one catalogue carrying exactly `name`, each told
      # apart by its detail and in its order, so a list of them reads the same
      # every time.
      def self.variants_named(prefix, name)
        variants(prefix, named(prefix, name)).sort_by(&:detail)
      end

      # Each of `rows` as a variant, with what its name and detail read loaded.
      def self.variants(prefix, rows)
        rows = rows.includes(:build)
        rows = rows.includes(lead(prefix).preload) if lead(prefix).preload
        rows.map { |record| Variant.new(prefix:, record:) }
      end

      # The variant a picked suggestion's value names, if it still is listed.
      def self.find(value, within:)
        parts = VALUE.match(value.to_s.strip)
        return nil if parts.nil? || within.exclude?(parts[:prefix])

        record = ::Catalogue::TokenResolver.listed(parts[:prefix])
          .find_by(model(parts[:prefix]).table_name => {id: parts[:id]})

        record && Variant.new(prefix: parts[:prefix], record:)
      end

      def self.model(prefix)
        ::Catalogue::TokenResolver::CATALOGUES.fetch(prefix)
      end
    end
  end
end
