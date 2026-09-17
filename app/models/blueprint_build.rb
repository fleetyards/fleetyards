# frozen_string_literal: true

# What one build of the game says about a blueprint, following the shape
# `commodity_builds`, `equipment_builds` and `component_builds` established.
#
# The crafted output is here rather than only on the row because it is a fact: a
# build can point a recipe somewhere else, and one whose output the export drops
# has to keep answering for the build that still named one.
# == Schema Information
#
# Table name: blueprint_builds
#
#  id             :uuid             not null, primary key
#  category_ref   :string
#  craft_time     :integer
#  craftable_type :string
#  environment    :string           not null
#  name           :string
#  slot_count     :integer
#  version        :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  blueprint_id   :uuid             not null
#  craftable_id   :uuid
#
# Indexes
#
#  index_blueprint_builds_on_blueprint_and_build      (blueprint_id,environment,version) UNIQUE
#  index_blueprint_builds_on_blueprint_id             (blueprint_id)
#  index_blueprint_builds_on_environment_and_name     (environment,name)
#  index_blueprint_builds_on_environment_and_version  (environment,version)
#
# Foreign Keys
#
#  fk_rails_...  (blueprint_id => blueprints.id) ON DELETE => cascade
#
class BlueprintBuild < ApplicationRecord
  belongs_to :blueprint
  belongs_to :craftable, polymorphic: true, optional: true

  # The recipe this build states. Destroyed with the build, which is what makes
  # `prune_builds` and `retire_absent_builds` carry the costs away too.
  has_many :cost_slots,
    -> { order(:position) },
    class_name: "BlueprintCostSlot", inverse_of: :build, dependent: :destroy

  FACTS = %i[name craftable_type craftable_id category_ref craft_time slot_count].freeze

  # `craftable_type` and `craftable_id` are held back: the association reads the
  # columns, and an association cannot be served through a fact reader.
  READ_THROUGH = %i[name category_ref craft_time slot_count].freeze

  # The facts a browsable catalogue filters and sorts by.
  FILTERABLE = %i[name craft_time].freeze

  validates :environment, presence: true
  validates :version, presence: true
  validates :blueprint_id, uniqueness: {scope: [:environment, :version]}

  scope :for_source, ->(source = ::ScData::Source.current) {
    where(environment: source.environment)
  }

  scope :current, ->(source = ::ScData::Source.current) {
    where(environment: source.environment, version: source.version)
  }

  def self.retained_versions(environment, keep: ::ScData::Source.builds_retained(environment))
    where(environment:)
      .group(:version)
      .minimum(:created_at)
      .sort_by { |_version, first_seen| first_seen }
      .last(keep)
      .map(&:first)
  end
end
