# frozen_string_literal: true

module Catalogue
  # The tokens only some readers may follow: a fleet's contracts and events,
  # `[*contract:FID/Title*]` and `[*event:FID/Title*]`, and users,
  # `[*user:handle*]`. A token resolves only for a reader who would be let onto
  # the page it links to, so the link -- and the slug in it -- never reaches
  # anyone else, who reads the token's text instead.
  class RestrictedTokenResolver
    FLEET_TYPES = {
      "contract" => {
        model: ::FleetContract, policy: ::FleetContractPolicy,
        feature: "fleet_contracts", capability: :contracts
      },
      "event" => {
        model: ::FleetEvent, policy: ::FleetEventPolicy,
        feature: "fleet_mission_builder", capability: :events
      }
    }.freeze

    PREFIXES = [*FLEET_TYPES.keys, "user"].freeze

    TYPES = [*FLEET_TYPES.values.map { |type| type[:model].name }, ::User.name].freeze

    # What a token cannot hold, so a title carrying one cannot be offered.
    UNWRITABLE = /[*\]\n]/

    # `fleet_reader` is who the fleet tokens resolve for, which is nobody when
    # the request's OAuth token may not read fleets: the pages would refuse it.
    def initialize(reader:, fleet_reader: reader)
      @reader = reader
      @fleet_reader = fleet_reader
    end

    # `parsed` holds `[token, prefix, name]` triples.
    def resolve(parsed)
      users = parsed.select { |_, prefix, _| prefix == "user" }
      fleet_tokens = parsed.select { |_, prefix, _| FLEET_TYPES.key?(prefix) }

      resolve_users(users) + resolve_fleet_records(fleet_tokens)
    end

    # Ranked `[starts_with, length, match]` triples, for the catalogue search
    # to merge with its own.
    def search(query, prefixes: PREFIXES)
      found = []
      found.concat(search_users(query)) if prefixes.include?("user")
      FLEET_TYPES.each_key do |prefix|
        found.concat(search_fleet_records(prefix, query)) if prefixes.include?(prefix)
      end

      found
    end

    private def resolve_users(tokens)
      return [] if tokens.empty?

      readable = ::User.where(normalized_username: tokens.map { |_, _, name| name.downcase }.uniq)
        .with_hangar_readable_by(@reader)
        .pluck(:normalized_username, :username)
        .to_h

      tokens.filter_map do |token, _, name|
        username = readable[name.downcase]
        next unless username

        TokenResolver::Match.new(token:, name: username, type: ::User.name, slug: username)
      end
    end

    private def resolve_fleet_records(tokens)
      targets = tokens.filter_map do |token, prefix, name|
        fid, title = name.split("/", 2).map(&:strip)
        next if fid.blank? || title.blank?

        {token:, prefix:, fid: fid.downcase, title:}
      end
      return [] if targets.empty?

      fleets = readable_fleets.where(normalized_fid: targets.pluck(:fid).uniq).index_by(&:normalized_fid)

      targets.group_by { |target| [target[:prefix], fleets[target[:fid]]] }.flat_map do |(prefix, fleet), in_fleet|
        next [] unless fleet && fleet_type_open?(prefix, fleet)

        type = FLEET_TYPES.fetch(prefix)
        # Every record of the fleet that carries the title, not only those the
        # reader may see: a reader who cannot see the one the writer meant must
        # not be sent to another that shares its title.
        records = type[:model].where(fleet:)
          .where("lower(title) IN (?)", in_fleet.map { |target| target[:title].downcase }.uniq)
          .group_by { |record| record.title.downcase }

        in_fleet.filter_map do |target|
          candidates = records.fetch(target[:title].downcase, [])
          next unless candidates.one?

          record = candidates.first
          next unless visible?(type, record)

          TokenResolver::Match.new(token: target[:token], name: record.title, type: type[:model].name,
            slug: record.slug, fleet_slug: fleet.slug)
        end
      end
    end

    # The reader's friends and the people who share a fleet with them -- the
    # ones a writer means when naming somebody. Whether a token then links is
    # still the reader's question, asked again at lookup.
    private def search_users(query)
      return [] if @reader.blank?

      escaped = ActiveRecord::Base.sanitize_sql_like(query.downcase)
      fleet_ids = ::FleetMembership.kept.accepted.where(user: @reader, fleet: ::Fleet.kept).select(:fleet_id)
      fleet_mate_ids = ::FleetMembership.kept.accepted.where(fleet_id: fleet_ids).select(:user_id)

      ::User.where(id: ::Friendship.partner_ids_for(@reader)).or(::User.where(id: fleet_mate_ids))
        .where.not(id: @reader.id)
        .where("normalized_username LIKE ?", "%#{escaped}%")
        .order(starts_with("normalized_username", escaped), Arel.sql("length(normalized_username)"), :normalized_username)
        .limit(TokenResolver::SEARCH_LIMIT)
        .pluck(:username)
        .map do |username|
          ranked(username, query, TokenResolver::Match.new(token: "user:#{username}", name: username, type: ::User.name, slug: username))
        end
    end

    # A query may name the fleet the way the token does, `FID/Title`.
    private def search_fleet_records(prefix, query)
      fid, title = query.include?("/") ? query.split("/", 2).map(&:strip) : [nil, query]
      return [] if title.blank?

      type = FLEET_TYPES.fetch(prefix)
      fleets = readable_fleets
      fleets = fleets.where(normalized_fid: fid.downcase) if fid.present?
      fleets = fleets.select { |fleet| fleet_type_open?(prefix, fleet) }.index_by(&:id)
      return [] if fleets.empty?

      escaped = ActiveRecord::Base.sanitize_sql_like(title.downcase)

      # Only titles one record of its fleet carries, which are the ones a token
      # can name; the slug of a group of one is its record's.
      found = type[:model].where(fleet_id: fleets.keys)
        .where("lower(title) LIKE ?", "%#{escaped}%")
        .group(:fleet_id, Arel.sql("lower(title)"))
        .having("count(*) = 1")
        .order(starts_with("lower(title)", escaped), Arel.sql("min(length(title))"), Arel.sql("lower(title)"))
        .limit(TokenResolver::SEARCH_LIMIT)
        .pluck(:fleet_id, Arel.sql("min(slug)"))

      records = found.group_by(&:first).flat_map do |fleet_id, slugs|
        type[:model].where(fleet_id:, slug: slugs.map(&:last)).to_a
      end

      records.reject { |record| record.title.match?(UNWRITABLE) }.select { |record| visible?(type, record) }.map do |record|
        fleet = fleets.fetch(record.fleet_id)

        ranked(record.title, title, TokenResolver::Match.new(token: "#{prefix}:#{fleet.fid}/#{record.title}",
          name: record.title, type: type[:model].name, slug: record.slug, fleet_slug: fleet.slug))
      end
    end

    private def ranked(name, query, match)
      [name.downcase.start_with?(query.downcase) ? 0 : 1, name.length, match]
    end

    # The fleets the reader is an accepted member of, which are the only ones
    # whose contracts or events the pages show them.
    private def readable_fleets
      return ::Fleet.none if @fleet_reader.blank?

      @readable_fleets ||= ::Fleet.kept.where(
        id: ::FleetMembership.kept.accepted.where(user: @fleet_reader).select(:fleet_id)
      )
    end

    # The two gates the controllers ask before their policy: the feature is
    # rolled out here, and the fleet has bought it where that is enforced.
    private def fleet_type_open?(prefix, fleet)
      type = FLEET_TYPES.fetch(prefix)

      return false unless Flipper.enabled?(type[:feature], @fleet_reader, fleet)
      return true unless ::Subscriptions::PREMIUM_FEATURES.include?(type[:capability])
      return true unless Flipper.enabled?("fleet_subscriptions", @fleet_reader, fleet)

      fleet.subscribed?
    end

    private def visible?(type, record)
      type[:policy].new(record, user: @fleet_reader).apply(:show?)
    end

    private def starts_with(column, escaped)
      Arel.sql(ActiveRecord::Base.sanitize_sql_array(["CASE WHEN #{column} LIKE ? THEN 0 ELSE 1 END", "#{escaped}%"]))
    end
  end
end
