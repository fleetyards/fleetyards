# frozen_string_literal: true

# What one build of the game says about a place. A ptu build introduces places
# before live has them, which is what makes a place this side of the row
# rather than a column on it.
# == Schema Information
#
# Table name: location_builds
#
#  id                         :uuid             not null, primary key
#  always_shown               :boolean          default(FALSE), not null
#  description                :text
#  environment                :string           not null
#  game_type                  :string
#  kind                       :string
#  name                       :string
#  quantum_travel_destination :boolean          default(FALSE), not null
#  resources                  :jsonb            not null
#  shown_on_starmap           :boolean          default(FALSE), not null
#  shown_with_parent_only     :boolean          default(FALSE), not null
#  version                    :string           not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  location_id                :uuid             not null
#
# Indexes
#
#  index_location_builds_on_environment_and_name     (environment,name)
#  index_location_builds_on_environment_and_version  (environment,version)
#  index_location_builds_on_location_and_build       (location_id,environment,version) UNIQUE
#  index_location_builds_on_location_id              (location_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id) ON DELETE => cascade
#
class LocationBuild < ApplicationRecord
  belongs_to :location

  FACTS = %i[
    name description resources kind game_type
    shown_on_starmap shown_with_parent_only always_shown quantum_travel_destination
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
