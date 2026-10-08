# frozen_string_literal: true

# What one build of the game says about a place. A ptu build introduces places
# before live has them, which is what makes a place this side of the row
# rather than a column on it.
class LocationBuild < ApplicationRecord
  belongs_to :location

  FACTS = %i[
    name description resources kind body_type game_type
    shown_on_starmap shown_with_parent_only always_shown quantum_travel_destination
    facilities
  ].freeze

  READ_THROUGH = FACTS

  FILTERABLE = %i[
    name kind
    shown_on_starmap shown_with_parent_only always_shown quantum_travel_destination
  ].freeze

  validates :environment, presence: true
  validates :version, presence: true
  validates :location_id, uniqueness: {scope: [:environment, :version]}

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
