# frozen_string_literal: true

# == Schema Information
#
# Table name: equipment_builds
#
#  id                     :uuid             not null, primary key
#  backpack_compatibility :integer
#  core_compatibility     :integer
#  damage_reduction       :decimal(15, 2)
#  description            :text
#  environment            :string           not null
#  equipment_type         :string
#  g_force_tolerance      :decimal(15, 2)
#  grade                  :string
#  hidden                 :boolean          default(FALSE)
#  item_type              :string
#  name                   :string
#  radiation_protection   :decimal(15, 2)
#  radiation_scrub_rate   :decimal(15, 2)
#  range                  :decimal(15, 2)
#  rate_of_fire           :decimal(15, 2)
#  size                   :string
#  slot                   :integer
#  storage                :decimal(15, 2)
#  sub_type               :string
#  temperature_rating     :string
#  version                :string           not null
#  volume                 :decimal(15, 6)
#  volume_dimensions      :jsonb
#  weapon_class           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  equipment_id           :uuid             not null
#  manufacturer_id        :uuid
#
# Indexes
#
#  index_equipment_builds_on_environment_and_equipment_type  (environment,equipment_type)
#  index_equipment_builds_on_environment_and_item_type       (environment,item_type)
#  index_equipment_builds_on_environment_and_version         (environment,version)
#  index_equipment_builds_on_equipment_and_build             (equipment_id,environment,version) UNIQUE
#  index_equipment_builds_on_equipment_id                    (equipment_id)
#  index_equipment_builds_on_manufacturer_id                 (manufacturer_id)
#
# Foreign Keys
#
#  fk_rails_...  (equipment_id => equipment.id) ON DELETE => cascade
#
# What one build of the game says about a piece of equipment.
#
# The columns here are exactly the ones `ScData::Loader::EquipmentLoader` writes.
# Everything that identifies the item, or that a person set by hand, stays on
# Equipment -- so a load can rewrite a build without touching the row a ledger
# entry or an uploaded image hangs off.
class EquipmentBuild < ApplicationRecord
  belongs_to :equipment
  belongs_to :manufacturer, optional: true

  # How many builds of one environment are kept. Enough to diff a patch against
  # the one before it, and to compare a bad load with what it replaced, without
  # the table growing with every patch forever.
  BUILDS_RETAINED = 3

  # Everything a build says, as opposed to what identifies the item. The data
  # migration carries its own copy on purpose: a migration has to keep running
  # against the schema of its own moment, not this list as it later becomes.
  FACTS = %i[
    manufacturer_id name description equipment_type item_type sub_type
    weapon_class size grade slot hidden rate_of_fire range storage
    damage_reduction temperature_rating radiation_protection
    radiation_scrub_rate g_force_tolerance core_compatibility
    backpack_compatibility volume volume_dimensions
  ].freeze

  validates :environment, presence: true
  validates :version, presence: true
  validates :equipment_id, uniqueness: {scope: [:environment, :version]}

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
  def self.retained_versions(environment, keep: BUILDS_RETAINED)
    where(environment:)
      .group(:version)
      .minimum(:created_at)
      .sort_by { |_version, first_seen| first_seen }
      .last(keep)
      .map(&:first)
  end
end
