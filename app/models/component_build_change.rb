# frozen_string_literal: true

# One fact a patch changed about one component.
#
# Written when a build lands, from the build before it. `ItemsLoader` prunes
# component builds to the two or three `ScData::Source::BUILDS_RETAINED` keeps,
# so this is the only place a change survives long enough to read a year later.
# == Schema Information
#
# Table name: component_build_changes
#
#  id           :uuid             not null, primary key
#  environment  :string           not null
#  field        :string           not null
#  from_version :string           not null
#  new_value    :text
#  old_value    :text
#  recorded_at  :datetime         not null
#  to_version   :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  component_id :uuid             not null
#
# Indexes
#
#  index_component_build_changes_on_build              (environment,to_version)
#  index_component_build_changes_on_component_and_field  (component_id,environment,to_version,field) UNIQUE
#  index_component_build_changes_on_recorded_at        (recorded_at)
#
# Foreign Keys
#
#  fk_rails_...  (component_id => components.id) ON DELETE => cascade
#
class ComponentBuildChange < ApplicationRecord
  belongs_to :component

  # A metric out of `type_data` rather than a column of its own. The prefix is
  # what keeps `type_data.size` apart from the `size` column, which are different
  # facts that a bare key would collide on.
  METRIC_PREFIX = "type_data."

  scope :newest_first, -> { order(recorded_at: :desc, field: :asc) }
  scope :for_build, ->(environment, version) { where(environment:, to_version: version) }

  validates :environment, :from_version, :to_version, :field, :recorded_at, presence: true

  # Diffs a build against the one that preceded it in the same environment and
  # replaces whatever was recorded for it.
  #
  # Replacing rather than appending is what makes a re-load safe: the same export
  # parsed twice can produce different values without a version bump, and the
  # second parse is the one to keep rather than a second set of rows beside the
  # first.
  def self.record!(build)
    previous = previous_build(build)
    return 0 if previous.blank?

    rows = changed_facts(previous, build).map do |field, (old_value, new_value)|
      {
        component_id: build.component_id,
        environment: build.environment,
        from_version: previous.version,
        to_version: build.version,
        field: field.to_s,
        old_value: old_value&.to_s,
        new_value: new_value&.to_s,
        recorded_at: build.created_at,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    transaction do
      where(component_id: build.component_id, environment: build.environment, to_version: build.version).delete_all
      insert_all(rows) if rows.any?
    end

    rows.size
  end

  # The build this one replaced: the most recently first-seen build of the same
  # environment that is not this one. Re-loading a build updates it in place, so
  # `created_at` is when a version landed rather than when it was last touched.
  def self.previous_build(build)
    build.component.builds
      .where(environment: build.environment)
      .where.not(version: build.version)
      .order(created_at: :desc)
      .first
  end

  def self.changed_facts(previous, build)
    changed_columns(previous, build).merge(changed_metrics(previous, build))
  end

  def self.changed_columns(previous, build)
    ComponentBuild::DIFFABLE_FACTS.each_with_object({}) do |fact, changes|
      old_value = previous.public_send(fact)
      new_value = build.public_send(fact)
      next if old_value == new_value

      changes[fact] = [old_value, new_value]
    end
  end

  # The scalar keys inside `type_data`, which is where a weapon's damage and a
  # quantum drive's jump range live -- the figures a reader came to the page for,
  # and the ones that actually move between patches.
  #
  # Scalars only. A nested shape (`calibration`, `stunParams`, `splineJumpParams`)
  # has no one-line "from -> to" to render, and comparing it whole reports a
  # change whenever a re-parse orders it differently.
  def self.changed_metrics(previous, build)
    old_metrics = metrics(previous)
    new_metrics = metrics(build)

    (old_metrics.keys | new_metrics.keys).each_with_object({}) do |key, changes|
      old_value = old_metrics[key]
      new_value = new_metrics[key]
      next if old_value == new_value

      changes[:"#{METRIC_PREFIX}#{key}"] = [old_value, new_value]
    end
  end

  SCALAR_METRIC_TYPES = [Numeric, String, TrueClass, FalseClass].freeze

  def self.metrics(build)
    build.type_data.to_h.select do |_key, value|
      SCALAR_METRIC_TYPES.any? { |type| value.is_a?(type) }
    end
  end

  # Whether this row is a `type_data` metric rather than a column.
  def metric?
    field.start_with?(METRIC_PREFIX)
  end

  # The field without its prefix, which is the name the payload spells the metric
  # under and the name a label is looked up by.
  def field_name
    field.delete_prefix(METRIC_PREFIX)
  end
end
