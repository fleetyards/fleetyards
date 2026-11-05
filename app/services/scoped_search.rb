# frozen_string_literal: true

# A site search over records someone is allowed to see rather than over a public
# catalogue. What may be seen is decided by the caller, which hands over scopes
# it has already authorized; this only searches them and shapes the answer.
class ScopedSearch
  PER_TYPE = ::Catalogue::Search::PER_TYPE
  MIN_LENGTH = ::Catalogue::Search::MIN_LENGTH
  MAX_LENGTH = ::Catalogue::TokenResolver::MAX_NAME_LENGTH

  # `filter` is the ransack predicate the matching list page filters by, so what
  # "show more" opens on holds what this counted. `item` turns a record into
  # a `Catalogue::Search::Result`.
  Source = Data.define(:type, :scope, :filter, :item)

  def self.result(type:, name:, slug:, detail: nil, image: nil, online: nil)
    ::Catalogue::Search::Result.new(type:, name:, slug:, detail:, image:, appearance: nil, online:)
  end

  def initialize(sources)
    @sources = sources
  end

  def call(query)
    query = query.to_s.strip
    return [] if query.length < MIN_LENGTH || query.length > MAX_LENGTH

    @sources.filter_map { |source| group(source, query) }
      .each_with_index
      .sort_by { |group, index| [rank(group.items.first.name, query), index] }
      .map(&:first)
  end

  private def group(source, query)
    records = source.scope.ransack(source.filter => query).result.limit(PER_TYPE + 1).to_a
    return if records.empty?

    ::Catalogue::Search::Group.new(
      type: source.type,
      items: records.first(PER_TYPE).map(&source.item),
      has_more: records.size > PER_TYPE
    )
  end

  private def rank(name, query)
    name = name.to_s.downcase
    query = query.downcase

    return 0 if name.start_with?(query)
    return 1 if name.include?(" #{query}")

    2
  end
end
