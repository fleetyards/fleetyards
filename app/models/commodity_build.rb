# frozen_string_literal: true

# What one build of the game says about a commodity.
#
# The columns here are exactly the ones `ScData::Loader::CommoditiesLoader`
# writes. Everything that identifies the commodity, or that comes from another
# source, stays on Commodity -- `uex_code` and `uex_id` are the UEX importer's,
# `slug` is generated, and `store_image` is curated.
# == Schema Information
#
# Table name: commodity_builds
#
#  id             :uuid             not null, primary key
#  commodity_type :string
#  description    :text
#  environment    :string           not null
#  name           :string
#  version        :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  commodity_id   :uuid             not null
#
# Indexes
#
#  index_commodity_builds_on_commodity_and_build             (commodity_id,environment,version) UNIQUE
#  index_commodity_builds_on_commodity_id                    (commodity_id)
#  index_commodity_builds_on_environment_and_commodity_type  (environment,commodity_type)
#  index_commodity_builds_on_environment_and_version         (environment,version)
#
# Foreign Keys
#
#  fk_rails_...  (commodity_id => commodities.id) ON DELETE => cascade
#
class CommodityBuild < ApplicationRecord
  belongs_to :commodity

  # How many builds of one environment are kept. Enough to diff a patch against
  # the one before it, and to compare a bad load with what it replaced, without
  # the table growing with every patch forever.
  BUILDS_RETAINED = 3

  # Everything a build says, as opposed to what identifies the commodity. Three
  # facts -- this catalogue has no enums, no serialized columns and no
  # manufacturer, which is why it fits in one change rather than three.
  #
  # The data migration carries its own copy on purpose: a migration has to keep
  # running against the schema of its own moment, not this list as it later
  # becomes.
  FACTS = %i[name commodity_type description].freeze

  # Every fact is read through the build. Nothing is held back here: equipment
  # and components hold `manufacturer_id` and `hidden` back because an
  # association and a visibility scope read the columns, and commodities have
  # neither.
  READ_THROUGH = FACTS

  # The facts Commodity filters and sorts by. `description` is left out -- no
  # filter reaches it, and folding it into the fallback subquery would widen it
  # for no gain.
  FILTERABLE = %i[name commodity_type].freeze

  validates :environment, presence: true
  validates :version, presence: true
  validates :commodity_id, uniqueness: {scope: [:environment, :version]}

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
