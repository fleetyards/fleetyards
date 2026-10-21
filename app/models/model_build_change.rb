# frozen_string_literal: true

# One fact a patch changed about one ship.
#
# Written when a build lands, from the build before it. The builds themselves are
# pruned after three patches, so this is the only place a change survives long
# enough to read a year later.
class ModelBuildChange < ApplicationRecord
  belongs_to :model

  scope :newest_first, -> { order(recorded_at: :desc, field: :asc) }
  scope :for_build, ->(environment, version) { where(environment:, to_version: version) }

  # Every build of the patch a version belongs to: 4.10.2 and its hotfixes,
  # each recorded against the build before it.
  scope :for_patch, ->(environment, version) {
    where(environment:).where("to_version LIKE ?", "#{sanitize_sql_like(release(version))}-%")
  }

  validates :environment, :from_version, :to_version, :field, :recorded_at, presence: true

  # "4.10.2" for "4.10.2-live.12913470".
  def self.release(version)
    version.to_s.split("-").first
  end

  # What a patch changed, its hotfixes included, as one unsaved row per ship
  # and fact: the value before the patch's first build against the value after
  # the latest one. A fact a hotfix put back where it was is no change at all.
  def self.patch_changes(environment, version, model_ids: nil)
    rows = for_patch(environment, version)
    rows = rows.where(model_id: model_ids) unless model_ids.nil?

    rows.order(:recorded_at).group_by { |row| [row.model_id, row.field] }.filter_map do |_, history|
      first = history.first
      last = history.last
      next if first.old_value == last.new_value

      # Carries the latest row's id, so a reader still has a record to name.
      new(
        id: last.id, model_id: first.model_id, environment:, field: first.field,
        from_version: first.from_version, to_version: last.to_version,
        old_value: first.old_value, new_value: last.new_value, recorded_at: last.recorded_at
      )
    end
  end

  # Diffs a build against the one that preceded it in the same environment and
  # replaces whatever was recorded for it.
  #
  # Replacing rather than appending is what makes a re-load safe: the same export
  # parsed twice can produce different values without a version bump, and the
  # second parse is the one to keep rather than a second set of rows beside the
  # first.
  #
  # The previous build is looked up as the newest other one, which is right only
  # while `build` is the newest: a caller recording an older build again names
  # the build that came before it.
  def self.record!(build, previous: previous_build(build))
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
      next unless ModelBuild.fact_recorded?(fact, old_value) && ModelBuild.fact_recorded?(fact, new_value)

      changes[fact] = [old_value, new_value]
    end
  end
end
