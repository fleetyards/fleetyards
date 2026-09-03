# frozen_string_literal: true

# One fact a patch changed about one ship.
#
# Written when a build lands, from the build before it. The builds themselves are
# pruned after three patches, so this is the only place a change survives long
# enough to read a year later.
# == Schema Information
#
# Table name: model_build_changes
#
#  id           :uuid             not null, primary key
#  environment  :string           not null
#  field        :string           not null
#  from_version :string           not null
#  new_value    :decimal(15, 2)
#  old_value    :decimal(15, 2)
#  recorded_at  :datetime         not null
#  to_version   :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  model_id     :uuid             not null
#
# Indexes
#
#  index_model_build_changes_on_build            (environment,to_version)
#  index_model_build_changes_on_model_and_field  (model_id,environment,to_version,field) UNIQUE
#  index_model_build_changes_on_model_id         (model_id)
#  index_model_build_changes_on_recorded_at      (recorded_at)
#
# Foreign Keys
#
#  fk_rails_...  (model_id => models.id) ON DELETE => cascade
#
class ModelBuildChange < ApplicationRecord
  belongs_to :model

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
        model_id: build.model_id,
        environment: build.environment,
        from_version: previous.version,
        to_version: build.version,
        field: field.to_s,
        old_value:,
        new_value:,
        recorded_at: build.created_at,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    transaction do
      where(model_id: build.model_id, environment: build.environment, to_version: build.version).delete_all
      insert_all(rows) if rows.any?
    end

    rows.size
  end

  # The build this one replaced: the most recently first-seen build of the same
  # environment that is not this one. Re-loading a build updates it in place, so
  # `created_at` is when a version landed rather than when it was last touched.
  def self.previous_build(build)
    build.model.builds
      .where(environment: build.environment)
      .where.not(version: build.version)
      .order(created_at: :desc)
      .first
  end

  def self.changed_facts(previous, build)
    ModelBuild::DIFFABLE_FACTS.each_with_object({}) do |fact, changes|
      old_value = previous.public_send(fact)
      new_value = build.public_send(fact)
      next if old_value == new_value

      changes[fact] = [old_value, new_value]
    end
  end
end
