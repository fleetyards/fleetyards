# frozen_string_literal: true

# What one build of the game says about a hardpoint slot.
#
# The four catalogues each hold their facts in a `*_build` row; the loadout never
# did, which is why loading a second environment replaced the first one's
# hardpoints instead of sitting beside them. This is that row, one layer deeper:
# the slot on `hardpoints` is stable across builds, and everything a build has an
# opinion about lives here.
#
# Only the `game_files` half gets rows. The ship matrix comes from no build and
# has no version, so if "has a build row" were the test for "is in this build",
# every matrix hardpoint would read as retired from every build -- the same
# conflation `in_game` was rejected for on the model catalogue.
# == Schema Information
#
# Table name: hardpoint_builds
#
#  id            :uuid             not null, primary key
#  category      :integer
#  environment   :string           not null
#  flags         :string
#  group         :integer
#  group_key     :string
#  max_size      :integer
#  min_size      :integer
#  port_tags     :string
#  required_tags :string
#  types         :string
#  version       :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  component_id  :uuid
#  hardpoint_id  :uuid             not null
#
# Indexes
#
#  index_hardpoint_builds_on_component_id             (component_id)
#  index_hardpoint_builds_on_environment_and_version  (environment,version)
#  index_hardpoint_builds_on_hardpoint_and_build      (hardpoint_id,environment,version) UNIQUE
#  index_hardpoint_builds_on_hardpoint_id             (hardpoint_id)
#
# Foreign Keys
#
#  fk_rails_...  (hardpoint_id => hardpoints.id) ON DELETE => cascade
#
class HardpointBuild < ApplicationRecord
  belongs_to :hardpoint
  belongs_to :component, optional: true

  # How many builds of one environment are kept, matching the catalogues: enough
  # to diff a patch against the one before it without the table growing forever.
  BUILDS_RETAINED = 3

  # Everything a build says, as opposed to what identifies the slot. `parent`,
  # `sc_name` and `source` are the identity and stay on the row; `matrix_key` and
  # `details` stay too -- neither is written by a load.
  #
  # `group`, `category` and `group_key` are here because Hardpoint derives all
  # three from the installed component in a `before_validation`, so they move
  # wherever the component does.
  FACTS = %i[
    component_id min_size max_size types port_tags required_tags flags
    group category group_key
  ].freeze

  # The same serialization and enums Hardpoint declares, so a build row holding
  # `3` reads as `thruster` here too and a JSON string comes back as the array it
  # encodes. Getting this wrong is how a reader ends up calling `dig` on a raw
  # serialized string, since the fallback fires only on nil.
  serialize :types, type: Array, coder: JSON
  serialize :port_tags, type: Array, coder: JSON
  serialize :required_tags, type: Array, coder: JSON
  serialize :flags, type: Array, coder: JSON

  # Taken from Hardpoint rather than restated: a build row holding `40` has to
  # read as `weapons` exactly as the slot's own column does, and a second copy
  # of a 30-entry map is a drift waiting to happen.
  enum :group, ::Hardpoint::GROUPS, suffix: true

  enum :category, ::Hardpoint::CATEGORIES, suffix: true

  validates :environment, presence: true
  validates :version, presence: true
  validates :hardpoint_id, uniqueness: {scope: [:environment, :version]}

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
