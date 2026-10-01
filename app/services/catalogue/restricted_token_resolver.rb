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
        feature: "fleet_mission_builder", capability: :events,
        # Event titles repeat, and a split series repeats its own.
        tie_break: :still_running
      }
    }.freeze

    PREFIXES = [*FLEET_TYPES.keys, "user"].freeze

    TYPES = [*FLEET_TYPES.values.map { |type| type[:model].name }, ::User.name].freeze

    # How many rows the search reads per result it may offer, for the ones the
    # policy turns down.
    CANDIDATES_PER_RESULT = 5

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
        # Of a title several records carry, the one still running -- which is
        # still read across all of them, so a hidden one keeps it ambiguous.
        running = tie_broken_ids(type, records.values.select { |named| named.size > 1 }.flatten)

        in_fleet.filter_map do |target|
          candidates = records.fetch(target[:title].downcase, [])
          candidates = candidates.select { |record| running.include?(record.id) } unless candidates.one?
          next unless candidates.one?

          record = candidates.first
          next unless visible?(type, record)

          TokenResolver::Match.new(token: target[:token], name: record.title, type: type[:model].name,
            slug: record.slug, fleet_slug: fleet.slug)
        end
      end
    end

    # The reader's friends and the people who share a fleet with them -- the
    # ones a writer means when naming somebody -- whose hangar the writer may
    # open, since a token they could not follow would not link for them
    # either. Fleet-mates only for a fleet reader, since who is in a fleet is
    # fleet data.
    private def search_users(query)
      return [] if @reader.blank?

      escaped = ActiveRecord::Base.sanitize_sql_like(query.downcase)
      fleet_mate_ids = ::FleetMembership.kept.accepted.where(fleet_id: readable_fleets.select(:id)).select(:user_id)

      ::User.where(id: ::Friendship.partner_ids_for(@reader)).or(::User.where(id: fleet_mate_ids))
        .where.not(id: @reader.id)
        .with_hangar_readable_by(@reader)
        .where("normalized_username LIKE ?", "%#{escaped}%")
        .order(starts_with("normalized_username", escaped), Arel.sql("length(normalized_username)"), :normalized_username)
        .limit(TokenResolver::SEARCH_LIMIT)
        .pluck(:username)
        .map do |username|
          ranked(username, query, TokenResolver::Match.new(token: "user:#{username}", name: username, type: ::User.name, slug: username))
        end
    end

    # A query may name the fleet the way the token does, `FID/Title`. One
    # whose part before the slash is no fleet of the reader's is a title with
    # a slash in it.
    private def search_fleet_records(prefix, query)
      fleets = readable_fleets.select { |fleet| fleet_type_open?(prefix, fleet) }
      fid, title = query.split("/", 2).map(&:strip) if query.include?("/")

      if fid.present? && (named = fleets.select { |fleet| fleet.normalized_fid == fid.downcase }).any?
        fleets = named
      else
        title = query
      end

      return [] if title.blank? || fleets.empty?

      type = FLEET_TYPES.fetch(prefix)
      fleets = fleets.index_by(&:id)

      escaped = ActiveRecord::Base.sanitize_sql_like(title.downcase)

      # Only titles a token can name: one record of its fleet carries them, or
      # one of those that do is still running, whose id the group then answers.
      # The policy then drops what the reader may not open, so the database is
      # asked for more than is offered.
      single = "count(*) = 1"
      ids = type[:model].where(fleet_id: fleets.keys)
        .where("lower(title) LIKE ?", "%#{escaped}%")
        .where.not("title LIKE '%*%' OR title LIKE '%]%' OR title LIKE ?", "%\n%")
        .group(:fleet_id, Arel.sql("lower(title)"))
        .having(type[:tie_break] ? "#{single} OR count(*) FILTER (WHERE #{tie_break_sql(type)}) = 1" : single)
        .order(starts_with("lower(title)", escaped), Arel.sql("min(length(title))"), Arel.sql("lower(title)"))
        .limit(TokenResolver::SEARCH_LIMIT * CANDIDATES_PER_RESULT)
        .pluck(Arel.sql(type[:tie_break] ? "CASE WHEN #{single} THEN min(id::text) ELSE min(id::text) FILTER (WHERE #{tie_break_sql(type)}) END" : "min(id::text)"))

      records = type[:model].where(id: ids).index_by { |record| record.id.to_s }.values_at(*ids).compact

      records.select { |record| visible?(type, record) }.first(TokenResolver::SEARCH_LIMIT).map do |record|
        fleet = fleets.fetch(record.fleet_id)

        ranked(record.title, title, TokenResolver::Match.new(token: "#{prefix}:#{fleet.fid}/#{record.title}",
          name: record.title, type: type[:model].name, slug: record.slug, fleet_slug: fleet.slug))
      end
    end

    private def tie_broken_ids(type, records)
      return Set.new if records.empty? || !type[:tie_break]

      type[:model].where(id: records.map(&:id)).public_send(type[:tie_break]).pluck(:id).to_set
    end

    private def tie_break_sql(type)
      type[:model].public_send(:"#{type[:tie_break]}_sql")
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
