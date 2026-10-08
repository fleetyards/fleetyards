# frozen_string_literal: true

# What one build of the game says about a piece of equipment.
#
# The columns here are exactly the ones `ScData::Loader::EquipmentLoader` writes.
# Everything that identifies the item, or that a person set by hand, stays on
# Equipment -- so a load can rewrite a build without touching the row a ledger
# entry or an uploaded image hangs off.
class EquipmentBuild < ApplicationRecord
  belongs_to :equipment
  belongs_to :manufacturer, optional: true

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

  # The facts Equipment reads through its build. `hidden` is held back from the
  # readers because nothing reads it -- `visible` and the `hidden_eq` filter go
  # through `Equipment.fact_sql`, which resolves it the same way.
  #
  # `manufacturer_id` is held back because `belongs_to :manufacturer` reads the
  # column, and the public filter traverses that association. Splitting the two
  # would let a filter and a displayed manufacturer disagree, so they move
  # together, later.
  READ_THROUGH = (FACTS - %i[manufacturer_id hidden]).freeze

  # The facts Equipment filters and sorts by. One list, so a ransacker and the
  # fallback join's column list cannot drift apart. The free-text and jsonb facts
  # are left out: nothing filters on them, and each one widens the fallback
  # subquery for no gain. `temperature_rating` is free text ("-30 / 60 °C"), so
  # it has no order to sort by.
  FILTERABLE = %i[
    name equipment_type item_type sub_type weapon_class size grade slot hidden
    rate_of_fire range storage damage_reduction radiation_protection
    g_force_tolerance volume
  ].freeze

  # The same enums Equipment declares, because a build row holding `0` has to
  # read as `undersuit` here too. Without them, moving the readers over turns
  # every enum-backed fact back into a raw integer.
  enum :slot,
    {
      undersuit: 0, arms: 1, helmet: 2, torso: 3, legs: 4, footwear: 5, hat: 6, gloves: 7,
      pants: 8, shirt: 9, jacket: 10, backpack: 11
    },
    suffix: true

  enum :core_compatibility, {all: 0, medium_heavy: 1, heavy: 2}, suffix: true

  enum :backpack_compatibility, {all: 0, light_medium: 1, light: 2}, suffix: true

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
  def self.retained_versions(environment, keep: ::ScData::Source.builds_retained(environment))
    where(environment:)
      .group(:version)
      .minimum(:created_at)
      .sort_by { |_version, first_seen| first_seen }
      .last(keep)
      .map(&:first)
  end
end
