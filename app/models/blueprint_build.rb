# frozen_string_literal: true

# What one build of the game says about a blueprint, following the shape
# `commodity_builds`, `equipment_builds` and `component_builds` established.
#
# The crafted output is here rather than only on the row because it is a fact: a
# build can point a recipe somewhere else, and one whose output the export drops
# has to keep answering for the build that still named one.
class BlueprintBuild < ApplicationRecord
  belongs_to :blueprint
  belongs_to :craftable, polymorphic: true, optional: true

  # The recipe this build states. Destroyed with the build, which is what makes
  # `prune_builds` and `retire_absent_builds` carry the costs away too.
  has_many :cost_slots,
    -> { order(:position) },
    class_name: "BlueprintCostSlot", inverse_of: :build, dependent: :destroy

  # Where this build says the blueprint can be obtained. Same ownership as the
  # recipe, and for the same reason.
  has_many :sources,
    -> { order(:position) },
    class_name: "BlueprintSource", inverse_of: :build, dependent: :destroy

  FACTS = %i[name craftable_type craftable_id category_ref craft_time slot_count].freeze

  # `craftable_type` and `craftable_id` are held back: the association reads the
  # columns, and an association cannot be served through a fact reader.
  READ_THROUGH = %i[name category_ref craft_time slot_count].freeze

  # The facts a browsable catalogue filters and sorts by.
  #
  # The craftable pair is here because the columns on the row hold whatever the
  # last source to load wrote: filtering them answers a ptu request with live's
  # links, which is the same leak the fact readers were fixed for.
  FILTERABLE = %i[name craft_time craftable_type craftable_id].freeze

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
