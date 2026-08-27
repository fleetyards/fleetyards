# frozen_string_literal: true

# What one build of the game says about a model.
#
# The columns here are exactly the ones `ScData::Loader::ModelsLoader` writes,
# minus dimensions and minus `in_game` -- see the migration for why. Everything
# curated, everything the RSI ship matrix supplies, and everything that
# identifies the model stays on Model.
# == Schema Information
#
# Table name: model_builds
#
#  id                      :uuid             not null, primary key
#  cargo_holds             :string
#  environment             :string           not null
#  external_fuel_tanks     :string
#  ground                  :boolean          default(FALSE)
#  ground_acceleration     :decimal(15, 2)
#  ground_decceleration    :decimal(15, 2)
#  ground_max_speed        :decimal(15, 2)
#  ground_reverse_speed    :decimal(15, 2)
#  hull_doors              :jsonb
#  hull_health             :decimal(15, 2)
#  hull_parts              :jsonb
#  hydrogen_fuel_tanks     :string
#  mass                    :decimal(15, 2)
#  max_speed               :decimal(15, 2)
#  personal_inventory      :decimal(15, 2)
#  pitch                   :decimal(15, 2)
#  pitch_boosted           :decimal(15, 2)
#  quantum_fuel_tanks      :string
#  refuel_boom             :string
#  reverse_speed_boosted   :decimal(15, 2)
#  roll                    :decimal(15, 2)
#  roll_boosted            :decimal(15, 2)
#  scm_speed               :decimal(15, 2)
#  scm_speed_boosted       :decimal(15, 2)
#  signature_cross_section :jsonb
#  version                 :string           not null
#  weapon_pool_size        :integer
#  yaw                     :decimal(15, 2)
#  yaw_boosted             :decimal(15, 2)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  model_id                :uuid             not null
#
# Indexes
#
#  index_model_builds_on_environment_and_version  (environment,version)
#  index_model_builds_on_model_and_build          (model_id,environment,version) UNIQUE
#  index_model_builds_on_model_id                 (model_id)
#
# Foreign Keys
#
#  fk_rails_...  (model_id => models.id) ON DELETE => cascade
#
class ModelBuild < ApplicationRecord
  belongs_to :model

  # How many builds of one environment are kept. Enough to diff a patch against
  # the one before it, and to compare a bad load with what it replaced, without
  # the table growing with every patch forever.
  BUILDS_RETAINED = 3

  # Everything a build says about a model's mechanics.
  #
  # The data migration carries its own copy on purpose: a migration has to keep
  # running against the schema of its own moment, not this list as it later
  # becomes.
  FACTS = %i[
    mass hull_health hull_parts hull_doors weapon_pool_size signature_cross_section ground
    personal_inventory
    cargo_holds quantum_fuel_tanks hydrogen_fuel_tanks external_fuel_tanks refuel_boom
    scm_speed scm_speed_boosted reverse_speed_boosted max_speed
    pitch pitch_boosted yaw yaw_boosted roll roll_boosted
    ground_max_speed ground_reverse_speed ground_acceleration ground_decceleration
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
  def self.retained_versions(environment, keep: BUILDS_RETAINED)
    where(environment:)
      .group(:version)
      .minimum(:created_at)
      .sort_by { |_version, first_seen| first_seen }
      .last(keep)
      .map(&:first)
  end
end
