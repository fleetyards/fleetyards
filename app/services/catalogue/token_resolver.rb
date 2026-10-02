# frozen_string_literal: true

module Catalogue
  # Resolves the names a markdown text refers to with `[*Name*]` or
  # `[*type:Name*]` against the public catalogues, and hands the tokens that
  # depend on who reads them to `RestrictedTokenResolver`. Names are not unique -- every
  # ship with a manned turret adds another "Manned Turret" -- so a name resolves
  # only when exactly one listed item carries it; anything else stays plain text
  # rather than a guess.
  class TokenResolver
    CATALOGUES = {
      "component" => ::Component,
      "equipment" => ::Equipment,
      "commodity" => ::Commodity,
      "ship" => ::Model,
      "blueprint" => ::Blueprint,
      "mission" => ::GameMission,
      "location" => ::Location
    }.freeze

    # What a token without a prefix can mean. The rest are reached only by
    # their prefix: a blueprint carries the name of the item it crafts, and a
    # ship or a mission can share an item's name, so letting them answer a bare
    # name would turn tokens already written ambiguous. A place is reached by
    # its prefix too: "Lorville" is a city, but a name like "Crusader" is a
    # planet, a company and a ship maker at once.
    BARE = %w[component equipment commodity].freeze

    MAX_TOKENS = 100
    MAX_NAME_LENGTH = 200
    SEARCH_LIMIT = 20

    # `fleet_slug` is set for what lives under a fleet, whose page needs both.
    Match = Data.define(:token, :name, :type, :slug, :fleet_slug) do
      def initialize(fleet_slug: nil, **)
        super
      end
    end

    PREFIXES = [*CATALOGUES.keys, *RestrictedTokenResolver::PREFIXES].freeze

    def initialize(reader: nil, fleet_reader: reader)
      @restricted = RestrictedTokenResolver.new(reader:, fleet_reader:)
    end

    # What a reader can reach -- the same rows the catalogue pages list.
    def self.listed(prefix)
      case prefix
      when "component" then ::Component.with_facts(true).catalogued
      when "equipment" then ::Equipment.visible(true)
      when "commodity" then ::Commodity.with_facts(true)
      when "ship" then ::Model.visible.active
      when "blueprint" then ::Blueprint.with_facts(true)
      when "mission" then ::GameMission.with_facts(true).named
      when "location" then ::Location.listed.with_facts(true)
      end
    end

    def self.parse(token)
      prefix, name = token.to_s.split(":", 2)
      return [nil, token.to_s.strip] if name.nil? || !PREFIXES.include?(prefix.to_s.strip.downcase)

      [prefix.strip.downcase, name.strip]
    end

    def resolve(tokens)
      parsed = Array(tokens).map(&:to_s).uniq.first(MAX_TOKENS)
        .map { |token| [token, *self.class.parse(token)] }
        .reject { |_, _, name| name.blank? || name.length > MAX_NAME_LENGTH }

      restricted, catalogued = parsed.partition { |_, prefix, _| RestrictedTokenResolver::PREFIXES.include?(prefix) }

      rows = rows_named(catalogued.map { |_, _, name| name.downcase }.uniq)

      catalogued.filter_map do |token, prefix, name|
        candidates = rows.fetch(name.downcase, []).select { |row| prefix ? row[:prefix] == prefix : BARE.include?(row[:prefix]) }
        next unless candidates.one?

        row = candidates.first
        Match.new(token:, name: row[:name], type: CATALOGUES.fetch(row[:prefix]).name, slug: row[:slug])
      end + @restricted.resolve(restricted)
    end

    # Names that begin or contain `query`, each offered only when it resolves:
    # one item in its catalogue. A name another catalogue carries too gets its
    # prefix, so the inserted token cannot be read two ways. A query written
    # with a prefix searches that type alone.
    def search(query)
      prefix, query = self.class.parse(query)
      return [] if query.length < 2 || query.length > MAX_NAME_LENGTH

      prefixes = prefix ? [prefix] : PREFIXES

      escaped = ActiveRecord::Base.sanitize_sql_like(query.downcase)
      pattern = "%#{escaped}%"
      # Only names one item carries, chosen by the database, and those that
      # start with the query first -- the order the results are ranked in, so
      # the row budget cannot drop a better match for shorter, weaker ones.
      found = (CATALOGUES.keys & prefixes).flat_map do |prefix|
        name = name_sql(prefix)

        self.class.listed(prefix)
          .where("lower(#{name}) LIKE ?", pattern)
          .group(Arel.sql("lower(#{name})"))
          .having("count(*) = 1")
          .order(starts_with(name, escaped), Arel.sql("min(length(#{name}))"), Arel.sql("lower(#{name})"))
          .limit(SEARCH_LIMIT)
          .pluck(Arel.sql("min(#{name})"))
      end

      rows = rows_named(found.map(&:downcase).uniq)

      rows.flat_map do |lower, named|
        named.group_by { |row| row[:prefix] }.filter_map do |prefix, in_catalogue|
          next unless prefixes.include?(prefix) && in_catalogue.one?

          row = in_catalogue.first
          shared = named.any? { |other| other[:prefix] != prefix && BARE.include?(other[:prefix]) }
          token = (shared || !BARE.include?(prefix)) ? "#{prefix}:#{row[:name]}" : row[:name]
          [lower.start_with?(query.downcase) ? 0 : 1, row[:name].length, Match.new(token:, name: row[:name], type: CATALOGUES.fetch(prefix).name, slug: row[:slug])]
        end
      end.concat(@restricted.search(query, prefixes:))
        .sort_by { |starts, length, match| [starts, length, match.name] }.first(SEARCH_LIMIT).map(&:last)
    end

    # Every listed row carrying one of `names`, keyed by its lowered name.
    private def rows_named(names)
      return {} if names.empty?

      CATALOGUES.keys.flat_map do |prefix|
        self.class.listed(prefix)
          .where("lower(#{name_sql(prefix)}) IN (?)", names)
          .pluck(Arel.sql(name_sql(prefix)), Arel.sql("#{CATALOGUES.fetch(prefix).table_name}.slug"))
          .map { |name, slug| {prefix:, name:, slug:} }
      end.group_by { |row| row[:name].downcase }
    end

    private def starts_with(name, escaped)
      Arel.sql(ActiveRecord::Base.sanitize_sql_array(["CASE WHEN lower(#{name}) LIKE ? THEN 0 ELSE 1 END", "#{escaped}%"]))
    end

    # A ship's name is its row's; the game-file catalogues read theirs off the
    # build the listed scope joined.
    private def name_sql(prefix)
      return "models.name" if prefix == "ship"

      CATALOGUES.fetch(prefix).fact_sql(:name).to_s
    end
  end
end
