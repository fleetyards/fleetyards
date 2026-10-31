# frozen_string_literal: true

# A place a mission can take place at.
class GameMissionLocation < ApplicationRecord
  # `template`: a location template one of the mission's slots can pick stands
  # for this place. `text`: the mission's title or description names it.
  # `offered`: the contract is offered there.
  SOURCES = %w[template text offered].freeze

  belongs_to :game_mission
  belongs_to :location

  # The system a linked location sits in, a system's own link included.
  SYSTEM_SQL = Arel.sql("COALESCE(locations.system_id, CASE WHEN locations.kind = 'system' THEN locations.id END)")

  scope :offered, -> { where(source: "offered") }

  scope :offered_in_system, ->(system_ids) {
    offered.joins(:location).where(
      "locations.system_id IN (:ids) OR (locations.kind = 'system' AND locations.id IN (:ids))",
      ids: Array.wrap(system_ids)
    )
  }

  validates :source, inclusion: {in: SOURCES}
  validates :location_id, uniqueness: {scope: [:game_mission_id, :source]}
end
