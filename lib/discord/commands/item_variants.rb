# frozen_string_literal: true

module Discord
  module Commands
    # The items a name cannot pick out, because more than one item of a
    # catalogue carries it -- both "Serac" coolers, both "BR-2 Shotgun"s. A
    # markdown token leaves those unnamed; the bot offers each one instead,
    # told apart by size and its game key, and keyed by id.
    #
    # Only names a handful of items share. Past that it is a generic ship part
    # -- 313 "Internal Tank"s -- that would crowd every other suggestion out.
    module ItemVariants
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
        # is not: the first item of a name keeps the bare one. The size leads
        # because it is the difference a reader can make sense of.
        def detail
          key = record.sc_key.to_s.downcase.presence || slug
          size = record.try(:size)

          [("S#{size}" if size.present?), key].compact.join(" · ")
        end
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

          scope.where("#{name} IN (?)", names).includes(:build).map { |record| Variant.new(prefix:, record:) }
        end
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
