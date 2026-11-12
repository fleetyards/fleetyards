# frozen_string_literal: true

# A site search over records someone is allowed to see rather than over a public
# catalogue. What may be seen is decided by the caller, which hands over scopes
# it has already authorized; this only searches them and shapes the answer.
class ScopedSearch
  PER_TYPE = ::Catalogue::Search::PER_TYPE
  MIN_LENGTH = ::Catalogue::Search::MIN_LENGTH
  MAX_LENGTH = ::Catalogue::TokenResolver::MAX_NAME_LENGTH

  # How many of a list are looked through for a name spaced differently or a
  # letter off: a hangar's own lists are a few hundred at most, and the names
  # are compared here rather than in a query each source would need its own of.
  FALLBACK_CANDIDATES = 500

  # The kinds whose filter also looks at what the row shows as its detail: a
  # ship's model, a friend's display name.
  DETAIL_SEARCHED = %w[Vehicle User].freeze

  # `filter` is the ransack predicate the matching list page filters by, so what
  # "show more" opens on holds what this counted. `item` turns a record into
  # a `Catalogue::Search::Result`.
  # `images`, where given, answers for the kept records at once, record to
  # attachment, so a page of rows takes one query per catalogue.
  Source = Data.define(:type, :scope, :filter, :item, :images) do
    def initialize(images: nil, **)
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

    @candidates = {}

    found = @sources.filter_map { |source| group(source, query) }
      .each_with_index
      .sort_by { |group, index| [rank(group.items.first.name, query), index] }
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

    spaced = candidates(source).select do |_, result|
      texts(result).any? { |text| SearchMatch.compact(text).include?(compact) }
    end
    build(source, spaced.first(PER_TYPE).map(&:first), has_more: false) if spaced.any?
  end

  # Only once nothing matches as typed: names a letter or two off, the closest
  # first, scored by the same functions as the catalogue search.
  private def near_misses(query)
    return [] unless SearchMatch.fuzzy?(query)

    @sources.filter_map do |source|
      pairs = candidates(source)
      next if pairs.empty?

      spans = pairs.map { |_, result| texts(result) }
      scores = SearchMatch.fuzzy_scores(query, spans.flatten).each
      best = spans.map { |texts| texts.map { scores.next }.max_by(&:last) }

      close = pairs.zip(best)
        .select { |_, (match, _)| match >= SearchMatch::FUZZY_THRESHOLD }
        .sort_by { |_, (_, rank)| -rank }
      build(source, close.first(PER_TYPE).map { |(record, _), _| record }, has_more: false) if close.any?
    end
  end

  private def candidates(source)
    @candidates[source.type] ||= source.scope.limit(FALLBACK_CANDIDATES).to_a
      .map { |record| [record, source.item.call(record)] }
  end

  private def texts(result)
    texts = [result.name]
    texts << result.detail if DETAIL_SEARCHED.include?(result.type)

    texts.compact.map(&:to_s)
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
