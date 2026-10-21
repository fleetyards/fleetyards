# frozen_string_literal: true

module Catalogue
  # What the site search offers: a few of the best matches from every
  # catalogue, each with what tells it apart from the items that share its name.
  #
  # Not `TokenResolver#search`, which answers a different question -- what a
  # markdown token can name unambiguously -- and so drops every name two items
  # carry. On a site search that hides most missions and every size of a
  # component.
  class Search
    TYPES = %w[ship component equipment commodity blueprint mission location].freeze
    PER_TYPE = 5
    MIN_LENGTH = 2

    # Rows fetched per type before identical ones are collapsed: an item and
    # its NPC variants share a name, a size and a maker, and three rows a
    # reader cannot tell apart are worth one.
    CANDIDATES = PER_TYPE * 4

    # Where a catalogue keeps its picture, best first. A mission has none; a
    # blueprint borrows the one of what it crafts.
    IMAGES = {
      "ship" => ::Model::PREVIEW_VIEWS,
      "component" => %i[store_image],
      "equipment" => %i[store_image],
      "commodity" => %i[store_image],
      "location" => %i[image]
    }.freeze

    # `image` is the attachment itself, or nil where there is no picture.
    # `appearance` is how a place is drawn -- its kind and colour -- or nil for
    # anything else.
    Result = Data.define(:type, :name, :slug, :detail, :image, :appearance)

    # A place drawn rather than pictured: a body as a globe, a star as a sun,
    # and a system as its star.
    Appearance = Data.define(:kind, :color, :body_type, :flare)
    Group = Data.define(:type, :items)

    def call(query)
      query = query.to_s.strip
      return [] if query.length < MIN_LENGTH || query.length > TokenResolver::MAX_NAME_LENGTH

      escaped = ActiveRecord::Base.sanitize_sql_like(query.downcase)

      # A catalogue whose best match is strong comes first, so "port" opens on
      # Port Tressler rather than on equipment that merely contains the word.
      # Ties keep the order of TYPES.
      TYPES.map { |prefix| group(prefix, escaped) }
        .compact
        .each_with_index
        .sort_by { |group, index| [rank(group.items.first.name, query), index] }
        .map(&:first)
    end

    private def group(prefix, escaped)
      items = matches(prefix, escaped)
      return if items.empty?

      slugs = items.map(&:slug)
      images = images_for(prefix, slugs)
      appearances = (prefix == "location") ? location_appearances(slugs) : {}

      Group.new(
        type: items.first.type,
        items: items.map { |item| item.with(image: images[item.slug], appearance: appearances[item.slug]) }
      )
    end

    # Looked up for the few matches shown rather than joined into the search,
    # which ranks thousands of rows that are never displayed.
    private def images_for(prefix, slugs)
      return blueprint_images(slugs) if prefix == "blueprint"

      attachments = IMAGES.fetch(prefix, [])
      return {} if attachments.empty?

      records = TokenResolver::CATALOGUES.fetch(prefix).where(slug: slugs).to_a
      ActiveRecord::Associations::Preloader.new(
        records:,
        associations: attachments.to_h { |attachment| [:"#{attachment}_attachment", :blob] }
      ).call

      records.each_with_object({}) do |record, images|
        image = attachments.map { |attachment| record.public_send(attachment) }.find(&:attached?)
        images[record.slug] = image if image
      end
    end

    # Its kind always; a colour where it has one to be drawn in. A system takes
    # its star's, since it is drawn as that star.
    private def location_appearances(slugs)
      places = Location.where(slug: slugs).to_a
      stars = Location.where(kind: "star", system_id: places.select { |place| place.kind == "system" }.map(&:id))
        .index_by(&:system_id)

      places.to_h do |place|
        star = (place.kind == "system") ? stars[place.id] : place

        [place.slug, Appearance.new(
          kind: place.kind,
          color: star&.drawn_color || place.drawn_color,
          body_type: place.body_type,
          flare: star&.flare_star? || false
        )]
      end
    end

    private def blueprint_images(slugs)
      blueprints = Blueprint.where(slug: slugs).includes(:craftable).to_a
      craftables = blueprints.filter_map(&:craftable).select { |craftable| craftable.respond_to?(:store_image) }

      ActiveRecord::Associations::Preloader.new(records: craftables, associations: {store_image_attachment: :blob}).call

      blueprints
        .to_h { |blueprint| [blueprint.slug, blueprint.craftable.try(:store_image)] }
        .select { |_slug, image| image&.attached? }
    end

    # Names that start with the query first, then those with a word that does
    # -- "port" means Port Tressler before Support -- then the shortest, the
    # closest match, then alphabetically so equal names keep a stable order.
    private def matches(prefix, escaped)
      klass = TokenResolver::CATALOGUES.fetch(prefix)
      name = TokenResolver.name_sql(prefix)
      rank = ActiveRecord::Base.sanitize_sql_array([
        "CASE WHEN lower(#{name}) LIKE ? THEN 0 WHEN lower(#{name}) LIKE ? THEN 1 ELSE 2 END",
        "#{escaped}%", "% #{escaped}%"
      ])

      rows = TokenResolver.listed(prefix)
        .where("lower(#{name}) LIKE ?", "%#{escaped}%")
        .order(Arel.sql(rank), Arel.sql("length(#{name})"), Arel.sql("lower(#{name})"), Arel.sql("#{klass.table_name}.slug"))
        .limit(CANDIDATES)
        .pluck(Arel.sql(name), Arel.sql("#{klass.table_name}.slug"), *detail_columns(prefix, klass))

      details = details_for(prefix, rows.map { |row| row.drop(2) })

      rows.each_with_index
        .map { |(row_name, slug), index| Result.new(type: klass.name, name: row_name, slug:, detail: details[index], image: nil, appearance: nil) }
        .uniq { |result| [result.name.downcase, result.detail] }
        .first(PER_TYPE)
    end

    # The same ranking the query orders a catalogue by.
    private def rank(name, query)
      name = name.downcase
      query = query.downcase

      return 0 if name.start_with?(query)
      return 1 if name.include?(" #{query}")

      2
    end

    private def detail_columns(prefix, klass)
      case prefix
      when "ship" then [Arel.sql("models.manufacturer_id")]
      when "component" then [klass.fact_sql(:size), klass.fact_sql(:manufacturer_id), klass.fact_sql(:category)]
      when "equipment" then [klass.fact_sql(:manufacturer_id)]
      when "mission" then [klass.fact_sql(:org_name)]
      when "location" then [Arel.sql("locations.parent_id")]
      else []
      end
    end

    # One detail per row, or nil where there is nothing worth saying.
    private def details_for(prefix, columns)
      case prefix
      when "ship", "equipment"
        names = manufacturer_names(columns.map(&:first))
        columns.map { |(manufacturer_id)| names[manufacturer_id] }
      when "component"
        names = manufacturer_names(columns.map(&:second))
        columns.map do |size, manufacturer_id, category|
          # A paint is "size 1" for the game's bookkeeping alone.
          size = nil if category == "paints"

          [size.present? ? "S#{size}" : nil, names[manufacturer_id]].compact.join(" · ").presence
        end
      when "mission"
        columns.map { |(org_name)| org_name.presence }
      when "location"
        names = location_names(columns.map(&:first))
        columns.map { |(parent_id)| names[parent_id] }
      else
        Array.new(columns.size)
      end
    end

    private def manufacturer_names(ids)
      ids = ids.compact.uniq
      return {} if ids.empty?

      Manufacturer.where(id: ids).pluck(:id, :name).to_h
    end

    # A place's name is a fact of the build, like everything else about it.
    private def location_names(ids)
      ids = ids.compact.uniq
      return {} if ids.empty?

      Location.with_facts(true).where(id: ids).pluck(:id, Location.fact_sql(:name)).to_h
    end
  end
end
