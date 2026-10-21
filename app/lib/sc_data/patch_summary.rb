# frozen_string_literal: true

module ScData
  # What the current patch brought, for a reader rather than for an audit: the
  # newest build of an environment against the last build of the patch before
  # it, so a hotfix adds to its patch instead of replacing it. Two builds of
  # 4.10.2 differ by a handful of items; 4.10.2 against 4.10.1 is the patch.
  #
  # Built on `BuildCompare`, which names the facts that differ, and then reads
  # both values of each, which is what a person can act on -- "hull health
  # 180,844 to 103,004" rather than "hull_health changed".
  class PatchSummary
    # Facts we derive rather than read from the export, where our own
    # classification changed and every record moved with it: #5726 put ore
    # pods in a category of their own.
    DERIVED_FACTS = {
      "models" => [],
      "components" => %i[category],
      "equipment" => []
    }.freeze

    CATALOGUES = {
      "models" => ModelBuild,
      "components" => ComponentBuild,
      "equipment" => EquipmentBuild
    }.freeze

    # A summary, not the full comparison: enough for a section, the rest is a
    # link away.
    LIMIT = 8

    attr_reader :from, :to

    def self.for(environment)
      builds = ::ScData::Source.recorded.select { |source| source.environment == environment.to_s }
      to = builds.first
      return if to.blank?

      from = builds.find { |source| release(source) != release(to) } || builds.second
      return if from.blank?

      new(from:, to:)
    end

    def self.release(source)
      source.version.to_s.split("-").first
    end

    def initialize(from:, to:)
      @from = from
      @to = to
    end

    # Plain data, so it can be cached and the records loaded per request.
    def call
      models = compare("models")
      components = compare("components")
      equipment = compare("equipment")

      # A ship nobody can open is not news: hidden and inactive models carry
      # builds like any other.
      listed = ::Model.visible.active.where(id: models.appeared.map(&:id) + models.changed.map(&:id) + models.vanished.map(&:id)).pluck(:id).to_set
      models.appeared = models.appeared.select { |entry| listed.include?(entry.id) }
      models.changed = models.changed.select { |change| listed.include?(change.id) }
      models.vanished = models.vanished.select { |entry| listed.include?(entry.id) }

      {
        from: {environment: from.environment, version: from.version},
        to: {environment: to.environment, version: to.version},
        counts: {
          new_ships: models.appeared.size,
          changed_ships: models.changed.size,
          vanished_ships: models.vanished.size,
          new_components: components.appeared.size,
          changed_components: components.changed.size,
          new_equipment: equipment.appeared.size,
          changed_equipment: equipment.changed.size,
          vanished_equipment: equipment.vanished.size
        },
        new_ship_ids: models.appeared.map(&:id),
        ship_changes: ranked(changes("models", models)).first(LIMIT),
        item_changes: ranked(changes("components", components) + changes("equipment", equipment)).first(LIMIT)
      }
    end

    private def compare(catalogue)
      result = ::ScData::BuildCompare.new(CATALOGUES.fetch(catalogue), from:, to:).call
      derived = DERIVED_FACTS.fetch(catalogue)

      result.changed = result.changed.filter_map do |change|
        fields = change.fields - derived
        next if fields.empty?

        change.fields = fields
        change
      end

      result
    end

    private def changes(catalogue, result)
      return [] if result.changed.empty?

      build_class = CATALOGUES.fetch(catalogue)
      key = ::ScData::BuildCompare.subject_key(build_class)
      ids = result.changed.map(&:id)
      before = rows(build_class, from, key, ids)
      after = rows(build_class, to, key, ids)

      result.changed.map do |change|
        fields = change.fields.map do |field|
          {field: field.to_s, from: value(before[change.id], field), to: value(after[change.id], field)}
        end

        {kind: catalogue, id: change.id, name: change.name, fields:}
      end
    end

    # Largest relative change first, so the section leads with what moved most.
    # A fact that is not a number counts as no movement: a rename is worth
    # listing, not leading with.
    private def ranked(changes)
      changes.sort_by { |change| -change[:fields].map { |field| movement(field) }.max.to_f }
    end

    private def movement(field)
      before = field[:from]
      after = field[:to]
      return 0 unless before.is_a?(Numeric) && after.is_a?(Numeric)

      (after - before).abs / [before.abs, 1e-9].max
    end

    private def rows(build_class, source, key, ids)
      build_class
        .where(environment: source.environment, version: source.version)
        .where(key => ids)
        .index_by(&key.to_sym)
    end

    # Durability is compared leaf by leaf, so its fields arrive as
    # `durability.health` and are read the same way.
    private def value(row, field)
      return if row.nil?

      head, *path = field.to_s.split(".")
      raw = row.public_send(head)
      raw = raw.dig(*path) if path.any? && raw.respond_to?(:dig)

      raw.is_a?(BigDecimal) ? raw.to_f : raw
    end
  end
end
