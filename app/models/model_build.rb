# frozen_string_literal: true

# What one build of the game says about a model.
#
# The columns here are exactly the ones `ScData::Loader::ModelsLoader` writes,
# minus dimensions and minus `in_game` -- see the migration for why. Everything
# curated, everything the RSI ship matrix supplies, and everything that
# identifies the model stays on Model.
class ModelBuild < ApplicationRecord
  belongs_to :model

  # Everything a build says about a model's mechanics.
  #
  # The data migration carries its own copy on purpose: a migration has to keep
  # running against the schema of its own moment, not this list as it later
  # becomes.
  FACTS = %i[
    mass hull_health hull_parts hull_doors weapon_pool_size signature_cross_section ground crew
    personal_inventory fuel_consumption main_acceleration retro_acceleration
    cargo_holds quantum_fuel_tanks hydrogen_fuel_tanks external_fuel_tanks refuel_boom
    scm_speed scm_speed_boosted reverse_speed_boosted max_speed
    pitch pitch_boosted yaw yaw_boosted roll roll_boosted
    ground_max_speed ground_reverse_speed ground_acceleration ground_deceleration
  ].freeze

  # All five of Model's serialized columns that a build carries, declared
  # together. Missing one is not a quiet loss: `Component` serializes six and I
  # matched one, and the reader handed a raw YAML string to a caller that called
  # `dig` on it. A reader falls through to the column only on nil, and a string
  # is not nil.
  serialize :cargo_holds, coder: YAML
  serialize :quantum_fuel_tanks, coder: YAML
  serialize :hydrogen_fuel_tanks, coder: YAML
  serialize :external_fuel_tanks, coder: YAML
  serialize :refuel_boom, coder: YAML

  # Facts that are a shape rather than a number. Two loads of the same export
  # can serialise these differently without anything having changed, so
  # comparing them reports a change on every re-parse -- see the change log,
  # which leaves them out for exactly that reason.
  STRUCTURED_FACTS = %i[
    hull_parts hull_doors signature_cross_section
    cargo_holds quantum_fuel_tanks hydrogen_fuel_tanks external_fuel_tanks refuel_boom
  ].freeze

  # What a patch diff compares. Derived rather than listed, so a numeric fact
  # added to FACTS is diffable without anyone remembering to say so. `ground` is
  # excluded with the shapes: it classifies the ship rather than measuring it.
  DIFFABLE_FACTS = (FACTS - STRUCTURED_FACTS - %i[ground]).freeze

  # Facts that joined after builds were already being written. A build from
  # before then holds nil for them, which says nothing about the ship, so a diff
  # skips a side without one rather than report the fact appearing on every
  # model at once. Telling those builds apart by timestamp does not work: any
  # later write to the row, an admin correction included, bumps `updated_at`.
  LATE_FACTS = %i[crew].freeze

  def self.fact_recorded?(fact, value)
    !value.nil? || LATE_FACTS.exclude?(fact)
  end

  # The facts Model filters and sorts by, which is every one of them that
  # `Model.ransackable_attributes` lists. The other twelve nothing queries.
  FILTERABLE = %i[
    mass scm_speed max_speed personal_inventory ground crew
    pitch yaw roll
    ground_max_speed ground_reverse_speed ground_acceleration ground_deceleration
    cargo_holds quantum_fuel_tanks hydrogen_fuel_tanks
  ].freeze

  validates :environment, presence: true
  validates :version, presence: true
  validates :model_id, uniqueness: {scope: [:environment, :version]}

  # Every build this environment still has.
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
end
