# frozen_string_literal: true

# What one build of the game says about a component.
#
# The columns here are exactly the ones `ScData::Loader::ItemsLoader` writes.
# Everything that identifies the component, or that a person set by hand, stays on
# Component -- so a load can rewrite a build without touching the row a hardpoint,
# a model paint or an uploaded icon hangs off.
class ComponentBuild < ApplicationRecord
  belongs_to :component
  belongs_to :manufacturer, optional: true

  # Everything a build says, as opposed to what identifies the component. Taken
  # from Component's own paper_trail list, which already named the specs that move
  # between builds, plus `category` -- the loader writes it and it decides
  # `hidden`, so it belongs to the build even though paper_trail skips it.
  #
  # The data migration carries its own copy on purpose: a migration has to keep
  # running against the schema of its own moment, not this list as it later
  # becomes.
  FACTS = %i[
    manufacturer_id name description size grade item_class
    component_type component_sub_type category type_data
    durability power_connection heat_connection ammunition
    inventory_consumption tracking_signal hidden
  ].freeze

  # The facts Component reads through its build. `manufacturer_id` and `hidden`
  # are held back for the same reasons as on equipment: the association reads the
  # column, and `visible` moves with the filters rather than with the readers.
  READ_THROUGH = (FACTS - %i[manufacturer_id hidden]).freeze

  # Facts that are a shape rather than a value. Two loads of the same export can
  # serialise these differently without anything having changed, so comparing
  # them whole reports a change on every re-parse -- the change log leaves them
  # out for the reason `ModelBuild::STRUCTURED_FACTS` names.
  #
  # `type_data` is the exception that is handled rather than dropped:
  # `ComponentBuildChange` reaches inside it and diffs its scalar keys, which is
  # where a weapon's damage and a cooler's cooling rate actually live.
  STRUCTURED_FACTS = %i[
    type_data durability power_connection heat_connection ammunition
    inventory_consumption
  ].freeze

  # What a patch diff compares, as columns. Derived rather than listed, so a fact
  # added to FACTS is diffable without anyone remembering to say so.
  #
  # `description` is excluded because it is prose: a reworded sentence is a real
  # change and an unreadable one to render beside "size 2 -> 3".
  # `manufacturer_id` because the value it would record is a uuid, which says
  # nothing to a reader -- the manufacturer's own change log is where that
  # belongs.
  DIFFABLE_FACTS = (FACTS - STRUCTURED_FACTS - %i[description manufacturer_id]).freeze

  # `durability` is one of the shapes above, but every figure in it is a number
  # a reader acts on -- health, mass, how much of each damage type it takes,
  # its repair and its distortion limits. So it is compared a figure at a time
  # rather than whole: one entry per leaf, keyed by its path.
  DURABILITY_PREFIX = "durability."

  # The parts the parser writes. Older rows also carry a `lifetime` nothing
  # reads, which must not surface as a figure.
  DURABILITY_PARTS = %w[health mass resistances self_repair distortion].freeze

  def self.durability_figures(durability)
    flatten = lambda do |hash, path|
      hash.each_with_object({}) do |(key, value), figures|
        field = "#{path}#{key}"

        if value.is_a?(Hash)
          figures.merge!(flatten.call(value, "#{field}."))
        elsif value.is_a?(Numeric)
          figures[field] = value
        end
      end
    end

    flatten.call(durability.to_h.stringify_keys.slice(*DURABILITY_PARTS), DURABILITY_PREFIX)
  end

  # The figures that differ between two builds' durability, as
  # `field => [old, new]`.
  #
  # Health is the one part every load has always written. A build from before
  # the parser read the rest carries health without the damage multipliers the
  # parser now always writes beside it, and against such a build every other
  # figure would read as one the patch introduced -- on thousands of
  # components at once, none of which a patch touched. So against one of
  # those, only health is compared.
  def self.durability_changes(before, after)
    old_figures = durability_figures(before)
    new_figures = durability_figures(after)

    if legacy_durability?(before)
      old_figures = old_figures.slice("#{DURABILITY_PREFIX}health")
      new_figures = new_figures.slice("#{DURABILITY_PREFIX}health")
    end

    (old_figures.keys | new_figures.keys).sort.each_with_object({}) do |field, changes|
      next if old_figures[field] == new_figures[field]

      changes[field] = [old_figures[field], new_figures[field]]
    end
  end

  def self.legacy_durability?(durability)
    parts = durability.to_h.stringify_keys

    parts.key?("health") && !parts.key?("resistances")
  end

  # The facts Component filters and sorts by. One list, so a ransacker and the
  # fallback join's column list cannot drift apart.
  #
  # The six YAML columns are left out on purpose: nothing filters on a serialized
  # structure, and folding each into the fallback subquery would widen it for no
  # gain. `description` too -- no filter reaches it.
  FILTERABLE = %i[
    name size grade item_class component_type
    component_sub_type category tracking_signal hidden
  ].freeze

  # The same serialization and enums Component declares, because a build row
  # holding `0` has to read as `stealth` here too, and a YAML string has to come
  # back as the structure it encodes.
  #
  # All six of Component's serialized columns, not the one that caught the eye:
  # missing `type_data` alone made the weapons endpoint call `dig` on a raw YAML
  # string, because the reader falls through to the column only on nil and a
  # string is not nil.
  # jsonb, not a YAML string: every metric a component has lives in here,
  # and as text none of it could be filtered, sorted or indexed on. The
  # type keeps indifferent access, which the readers already assume.
  attribute :type_data, Types::IndifferentJson.new
  serialize :durability, coder: YAML
  serialize :power_connection, coder: YAML
  serialize :heat_connection, coder: YAML
  serialize :ammunition, coder: YAML
  serialize :inventory_consumption, coder: YAML

  # JSON rather than YAML, matching Component: these two are lists of tags, and
  # a build has to read back the same shape the column does.
  serialize :tags, type: Array, coder: JSON
  serialize :required_tags, type: Array, coder: JSON

  enum :item_class,
    {stealth: 0, civilian: 1, industrial: 2, military: 3, competition: 4}

  enum :tracking_signal,
    {infrared: 0, cross_section: 1, electromagnetic: 2}

  # The reader prefers the build, so a raw description here reaches the API
  # whatever the component's own column says -- which is how the export's
  # "Item Type: ... Manufacturer: ..." preamble kept being served.
  before_save :normalize_description

  validates :environment, presence: true
  validates :version, presence: true
  validates :component_id, uniqueness: {scope: [:environment, :version]}

  # Every build this environment still has, newest first.
  scope :for_source, ->(source = ::ScData::Source.current) {
    where(environment: source.environment)
  }

  # The one build the environment is on. `ScData::Source` names the version
  # exactly, so this needs no ordering or subselect.
  scope :current, ->(source = ::ScData::Source.current) {
    where(environment: source.environment, version: source.version)
  }

  # The versions worth keeping for one environment, ordered by when they first
  # appeared. Re-loading a build updates its rows in place, so `created_at` is
  # when that build first landed rather than when it was last touched.
  def self.retained_versions(environment, keep: ::ScData::Source.builds_retained(environment))
    where(environment:)
      .group(:version)
      .minimum(:created_at)
      .sort_by { |_version, first_seen| first_seen }
      .last(keep)
      .map(&:first)
  end

  private def normalize_description
    return if description.blank?

    prose, = Component.split_description(description)
    self.description = prose
  end
end
