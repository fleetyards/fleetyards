# frozen_string_literal: true

# A site search over records someone is allowed to see rather than over a public
# catalogue. What may be seen is decided by the caller, which hands over scopes
# it has already authorized; this only searches them and shapes the answer.
class ScopedSearch
  PER_TYPE = ::Catalogue::Search::PER_TYPE
  MIN_LENGTH = ::Catalogue::Search::MIN_LENGTH
  MAX_LENGTH = ::Catalogue::TokenResolver::MAX_NAME_LENGTH

  # `filter` is the ransack predicate the matching list page filters by, so what
  # "show more" opens on holds what this counted. `columns` are the SQL
  # expressions that filter looks at, for matching a name spaced differently or
  # a letter off, which ransack cannot express. `item` turns a record into a
  # `Catalogue::Search::Result`.
  # `images`, where given, answers for the kept records at once, record to
  # attachment, so a page of rows takes one query per catalogue.
  # A `lead` source heads the answer whenever it matches, however well the
  # others do.
  Source = Data.define(:type, :scope, :filter, :columns, :item, :images, :lead) do
    def initialize(images: nil, lead: false, **)
      super
    end
  end

  def self.result(type:, name:, slug:, detail: nil, image: nil, online: nil, squadron: nil, image_url: nil)
    ::Catalogue::Search::Result.new(type:, name:, slug:, detail:, image:, appearance: nil, online:, squadron:, image_url:)
  end

  def self.blueprint_source(type, scope)
    Source.new(
      type:,
      scope: scope.order(Arel.sql(::Catalogue::TokenResolver.name_sql("blueprint"))),
      filter: :name_cont,
      columns: [::Catalogue::TokenResolver.name_sql("blueprint")],
      item: ->(blueprint) { result(type: "Blueprint", name: blueprint.name, slug: blueprint.slug) },
      images: lambda { |blueprints|
        images = ::Catalogue::Search.new.images_for("blueprint", blueprints.map(&:slug))

        blueprints.to_h { |blueprint| [blueprint, images[blueprint.slug]] }
      }
    )
  end

  def self.inventory_images(entries)
    ::InventoryLedgerEntry.preload_images(entries)

    entries.to_h { |entry| [entry, entry.display_image] }
  end

  def initialize(sources)
    @sources = sources
  end

  def call(query)
    query = query.to_s.strip
    return [] if query.length < MIN_LENGTH || query.length > MAX_LENGTH

    found = @sources.each_with_index
      .filter_map { |source, index| group(source, query)&.then { |match| [match, source, index] } }
      .sort_by { |match, source, index| [source.lead ? 0 : 1, rank(match.items.first.name, query), index] }
      .map(&:first)

    found.presence || near_misses(query)
  end

  # As typed first, which is what the list page's filter holds; failing that,
  # the same name spaced or punctuated differently -- "northstar" for a North
  # Star -- which the list page does not hold, so it offers no more.
  private def group(source, query)
    records = source.scope.ransack(source.filter => query).result.limit(PER_TYPE + 1).to_a
    return build(source, records.first(PER_TYPE), has_more: records.size > PER_TYPE) if records.any?

    compact = SearchMatch.compact(query)
    return if compact.length < MIN_LENGTH

    spaced = source.columns.map { |column| "#{SearchMatch.compact_sql(column)} LIKE :compact" }.join(" OR ")
    records = source.scope.where(spaced, compact: "%#{compact}%").limit(PER_TYPE).to_a
    build(source, records, has_more: false) if records.any?
  end

  # Only once nothing matches as typed: names a letter or two off, the closest
  # first, scored by the same functions as the catalogue search.
  private def near_misses(query)
    return [] unless SearchMatch.fuzzy?(query)

    binds = SearchMatch.fuzzy_binds(query)

    @sources.filter_map do |source|
      match = greatest(source.columns.map { |column| SearchMatch.fuzzy_match_sql(column) }, binds)
      score = greatest(source.columns.map { |column| SearchMatch.fuzzy_rank_sql(column) }, binds)

      records = source.scope
        .where("#{match} >= ?", SearchMatch::FUZZY_THRESHOLD)
        .reorder(Arel.sql("#{score} DESC"))
        .limit(PER_TYPE).to_a
      build(source, records, has_more: false) if records.any?
    end
  end

  # The best of a record's columns; a column it leaves empty counts for nothing.
  private def greatest(expressions, binds)
    ActiveRecord::Base.sanitize_sql_array(["GREATEST(#{expressions.join(", ")})", binds])
  end

  private def build(source, records, has_more:)
    images = source.images&.call(records) || {}

    ::Catalogue::Search::Group.new(
      type: source.type,
      items: records.map { |record| with_image(source.item.call(record), images[record]) },
      has_more:
    )
  end

  private def with_image(result, image)
    image ? result.with(image:) : result
  end

  private def rank(name, query)
    name = name.to_s.downcase
    query = query.downcase

    return 0 if name.start_with?(query)
    return 1 if name.include?(" #{query}")

    2
  end
end
