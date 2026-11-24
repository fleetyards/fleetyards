# frozen_string_literal: true

module ScData
  # One catalogue's two builds as a reader compares them: records by name, every
  # changed fact with the value on both sides, references as names.
  #
  # `BuildCompare` answers which records and fields moved, for an audit. This
  # leaves out what a reader cannot act on -- records the game never named or we
  # hide, internal keys, tags and shapes with no one-line value.
  class BuildDiff
    KINDS = %w[added removed changed].freeze

    # `drop` is what a build records that is no value to a reader: prose, keys
    # into the export, tags, and facts we derive ourselves.
    CATALOGUES = {
      "models" => {build: "ModelBuild", drop: []},
      "modules" => {build: "ModelModuleBuild", drop: []},
      "loadouts" => {build: "HardpointBuild", drop: []},
      "components" => {build: "ComponentBuild", drop: %w[category hidden]},
      "equipment" => {build: "EquipmentBuild", drop: %w[fit inventory hidden]},
      "commodities" => {build: "CommodityBuild", drop: []},
      "blueprints" => {build: "BlueprintBuild", drop: %w[craftable_type category_ref]},
      "missions" => {build: "GameMissionBuild", drop: %w[
        org_ref org_key debug_name generator_key blueprint_pool_refs kind
      ]},
      "factions" => {build: "FactionBuild", drop: []},
      "locations" => {build: "LocationBuild", drop: %w[
        resources facilities position armistice_sphere trespass_areas
      ]}
    }.freeze

    # `category` is what a slot is for, and nil for any other fact.
    Field = Data.define(:field, :from, :to, :category) do
      def initialize(field:, from:, to:, category: nil) = super
    end
    Entry = Data.define(:id, :kind, :name, :fields)
    Result = Data.define(:recorded, :entries, :unrecorded) do
      def counts
        KINDS.index_with { |kind| entries.count { |entry| entry.kind == kind } }
      end

      # How many records each fact moved on, most first.
      def field_counts
        entries.flat_map { |entry| entry.fields.map(&:field).uniq }.tally.sort_by { |field, count| [-count, field] }
      end
    end

    attr_reader :catalogue, :from, :to, :same_code

    def initialize(catalogue, from:, to:, same_code: false)
      @catalogue = catalogue
      @from = from
      @to = to
      @same_code = same_code
    end

    def call
      return Result.new(recorded: false, entries: [], unrecorded: []) unless before.any? && after.any?

      entries = (catalogue == "loadouts") ? loadout_entries : record_entries
      entries, unrecorded = without_unrecorded_facts(entries)

      Result.new(recorded: true, unrecorded:, entries: entries.sort_by { |entry| [entry.name.downcase, entry.id] })
    end

    # Fewer records than this could be the game introducing a fact.
    UNRECORDED_FROM = 5

    # A fact one build states for no record at all and the other for several was
    # not read from the first, so no record changed in it. The same code reads
    # the same facts, so there such a fact is the game's own. The facts left out
    # come back with the number of records they would have marked as changed.
    private def without_unrecorded_facts(entries)
      return [entries, []] if catalogue == "loadouts" || same_code

      shared = (before.keys & after.keys).select { |id| shown(id, before[id]) && shown(id, after[id]) }
      stated = [before, after].map { |rows| rows.values_at(*shared).flat_map { |row| stated_fields(row) }.tally }
      counts = entries.flat_map { |entry| entry.fields.map(&:field) }.tally
      unrecorded = counts.select { |field, _count|
        sides = stated.map { |fields| fields.fetch(field, 0) }

        sides.min.zero? && sides.max >= UNRECORDED_FROM
      }

      kept = entries.filter_map do |entry|
        fields = entry.fields.reject { |field| unrecorded.key?(field.field) }
        next if fields.empty? && entry.fields.any?

        entry.with(fields:)
      end

      [kept, unrecorded.sort_by { |field, count| [-count, field] }]
    end

    private def stated_fields(row)
      plain = comparable_facts.reject { |fact| unstated?(row.public_send(fact)) }.map { |fact| reader_field(fact).to_s }

      plain + nested_facts(row).reject { |_field, value| unstated?(value) }.keys.map(&:to_s)
    end

    private def unstated?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end

    private def nested_facts(row)
      case catalogue
      when "components"
        ::ComponentBuildChange.metrics(row)
          .transform_keys { |key| "#{::ComponentBuildChange::METRIC_PREFIX}#{key}" }
          .merge(::ComponentBuild.durability_figures(row.durability))
      when "models" then {"cargo" => cargo(row)}
      when "modules" then {"cargo" => cargo(row), "medical_beds" => medical_beds(row)}
      else {}
      end
    end

    private def build_class
      CATALOGUES.fetch(catalogue).fetch(:build).constantize
    end

    private def subject_key
      @subject_key ||= BuildCompare.subject_key(build_class)
    end

    private def subject_class
      build_class.reflect_on_all_associations(:belongs_to).find { |a| a.foreign_key == subject_key }.klass
    end

    private def before
      @before ||= rows(from)
    end

    private def after
      @after ||= rows(to)
    end

    private def rows(source)
      build_class
        .where(environment: source.environment, version: source.version)
        .index_by(&subject_key.to_sym)
    end

    # Shown on one side only is an arrival or a departure to a reader, also when
    # the other build has the record and hides it. A name is not part of that:
    # the game names things it already had, and a record only one build names is
    # the same record.
    private def record_entries
      (before.keys | after.keys).filter_map do |id|
        old = shown(id, before[id])
        new = shown(id, after[id])
        name = [new, old].compact.filter_map { |row| name_of(id, row).presence }.first
        next if name.nil?

        kind = if old && new
          "changed"
        else
          (new ? "added" : "removed")
        end
        fields = (kind == "changed") ? changed_fields(old, new) : []
        next if kind == "changed" && fields.empty?

        Entry.new(id:, kind:, name:, fields:)
      end
    end

    private def shown(id, row)
      row if row && listed?(id, row)
    end

    private def name_of(id, row)
      build_class.column_names.include?("name") ? row.name : subjects[id]
    end

    # Names for the catalogues whose build rows carry none, limited to the
    # records a reader can be shown.
    private def subjects
      @subjects ||= case catalogue
      when "models" then ::Model.visible.active.pluck(:id, :name).to_h
      when "modules" then ::ModelModule.visible.active.pluck(:id, :name).to_h
      end
    end

    private def listed?(id, row)
      case catalogue
      when "components", "equipment" then !row.hidden
      when "locations" then listed_locations.include?(id)
      else true
      end
    end

    private def listed_locations
      @listed_locations ||= ::Location.listed.pluck(:id).to_set
    end

    private def changed_fields(old, new)
      pairs = plain_changes(old, new).merge(nested_changes(old, new))

      pairs.map { |field, (a, b)| Field.new(field: field.to_s, from: present(a), to: present(b)) }
    end

    private def plain_changes(old, new)
      comparable_facts.each_with_object({}) do |fact, changes|
        a = readable(fact, old)
        b = readable(fact, new)
        next if a == b
        next unless recorded_fact?(fact, a) && recorded_fact?(fact, b)

        changes[reader_field(fact)] = [a, b]
      end
    end

    private def recorded_fact?(fact, value)
      !build_class.respond_to?(:fact_recorded?) || build_class.fact_recorded?(fact, value)
    end

    private def comparable_facts
      @comparable_facts ||= BuildCompare.diffable_facts(build_class)
        .reject { |fact| CATALOGUES.fetch(catalogue)[:drop].include?(fact.to_s) }
    end

    REFERENCES = {manufacturer_id: "manufacturer", craftable_id: "craftable"}.freeze

    private def reader_field(fact)
      REFERENCES.fetch(fact, fact)
    end

    private def readable(fact, row)
      value = row.public_send(fact)

      case fact
      when :manufacturer_id then value && manufacturer_names[value]
      when :craftable_id then value && craftable_name(row)
      else value
      end
    end

    private def manufacturer_names
      @manufacturer_names ||= ::Manufacturer.pluck(:id, :name).to_h
    end

    # A craftable can be one of several thousand, so only the ones that differ
    # are worth reading -- but the comparison needs the name on both sides to
    # know that. All of them are read once.
    private def craftable_name(row)
      @craftable_names ||= Hash.new do |names, type|
        names[type] = type.constantize.pluck(:id, :name).to_h
      end

      @craftable_names[row.craftable_type][row.craftable_id]
    end

    private def nested_changes(old, new)
      case catalogue
      when "components"
        ::ComponentBuildChange.changed_metrics(old, new).merge(::ComponentBuild.durability_changes(old.durability, new.durability))
      when "models"
        difference("cargo" => [cargo(old), cargo(new)])
      when "modules"
        difference("cargo" => [cargo(old), cargo(new)], "medical_beds" => [medical_beds(old), medical_beds(new)])
      else
        {}
      end
    end

    private def difference(pairs)
      pairs.reject { |_field, (a, b)| a == b }
    end

    private def cargo(row)
      holds = row.cargo_holds
      return if holds.blank?

      holds.sum { |hold| hold["capacity"].to_f }
    end

    private def medical_beds(row)
      tiers = row.medical_beds.to_h.with_indifferent_access[:tiers]
      return if tiers.blank?

      tiers.sum { |tier| tier[:beds].to_i }
    end

    private def present(value)
      case value
      when BigDecimal then value.to_f
      when Array then value.map { |item| present(item) }.join(", ").presence
      when Hash then value.values.map { |item| present(item) }.join(" × ").presence
      else value
      end
    end

    # A slot is a fact about the ship or module carrying it, so a ship's slots
    # are one entry. Slots inside a turret belong to the turret's own component.
    private def loadout_entries
      slots = ::Hardpoint.where(id: before.keys | after.keys, parent_type: %w[Model ModelModule]).to_a
      described = {
        "Model" => carriers("Model", ::ModelBuild, :model_id),
        "ModelModule" => carriers("ModelModule", ::ModelModuleBuild, :model_module_id)
      }

      slots.group_by { |slot| [slot.parent_type, slot.parent_id] }.filter_map do |(type, id), parent_slots|
        name = described[type][id]
        next if name.blank?

        fields = parent_slots.sort_by { |slot| slot.sc_name.to_s.gsub(/\d+/) { |digits| digits.rjust(4, "0") } }.filter_map { |slot| slot_field(slot) }
        fields = without_renamed_slots(fields)
        next if fields.empty?

        Entry.new(id:, kind: "changed", name:, fields:)
      end
    end

    # A ship only one of the builds has is new or gone rather than refitted, and
    # the ship catalogue says so.
    private def carriers(type, klass, key)
      in_both = [from, to].map { |source|
        klass.where(environment: source.environment, version: source.version).pluck(key)
      }.reduce(:&)

      type.constantize.visible.active.where(id: in_both).pluck(:id, :name).to_h
    end

    # Compared by the part rather than its name: a part the game renames is the
    # component catalogue's change, not a refit. A part that has no name to show
    # is not an empty slot, so that slot says nothing.
    private def slot_field(slot)
      old = part_in(before[slot.id])
      new = part_in(after[slot.id])
      return if old == new

      from_name = old && from_component_names[old]
      to_name = new && to_component_names[new]
      return if (old && from_name.nil?) || (new && to_name.nil?) || from_name == to_name

      Field.new(field: slot.sc_name.to_s, from: from_name, to: to_name, category: (after[slot.id] || before[slot.id]).category)
    end

    # A slot the export renames leaves one build and enters the other with the
    # same part in it, which is no change to the loadout.
    private def without_renamed_slots(fields)
      gone = fields.select { |field| field.to.nil? }.group_by(&:from)
      come = fields.select { |field| field.from.nil? }.group_by(&:to)

      renamed = gone.flat_map do |part, slots|
        slots.zip(come[part].to_a).reject { |pair| pair.any?(&:nil?) }.flatten
      end

      fields - renamed
    end

    # Slots that hold how a ship is operated rather than what it carries.
    UNFITTED_CATEGORIES = %w[controller seat doors].freeze

    private def part_in(row)
      row.component_id if row && !UNFITTED_CATEGORIES.include?(row.category)
    end

    private def from_component_names
      @from_component_names ||= component_names(from)
    end

    private def to_component_names
      @to_component_names ||= component_names(to)
    end

    private def component_names(source)
      ::ComponentBuild
        .where(environment: source.environment, version: source.version, hidden: false)
        .where.not(name: [nil, ""])
        .pluck(:component_id, :name).to_h
    end
  end
end
