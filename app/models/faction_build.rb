# frozen_string_literal: true

# What one build of the game says about a faction.
class FactionBuild < ApplicationRecord
  belongs_to :faction

  has_many :ladders,
    -> { order(:position) },
    class_name: "FactionLadder", inverse_of: :build,
    foreign_key: :faction_build_id, dependent: :destroy

  FACTS = %i[
    name description lawful alignment headquarters founded leadership area focus
  ].freeze

  validates :environment, presence: true
  validates :version, presence: true
  validates :faction_id, uniqueness: {scope: [:environment, :version]}

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
