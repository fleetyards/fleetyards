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

    @sources.filter_map { |source| group(source, query) }
      .each_with_index
      .sort_by { |group, index| [rank(group.items.first.name, query), index] }
      .map(&:first)
  end

  private def group(source, query)
    records = source.scope.ransack(source.filter => query).result.limit(PER_TYPE + 1).to_a
    return if records.empty?

    kept = records.first(PER_TYPE)
    images = source.images&.call(kept) || {}

    ::Catalogue::Search::Group.new(
      type: source.type,
      items: kept.map { |record| with_image(source.item.call(record), images[record]) },
      has_more: records.size > PER_TYPE
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
