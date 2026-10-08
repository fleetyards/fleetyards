# frozen_string_literal: true

# A place a mission can take place at.
class GameMissionLocation < ApplicationRecord
  # `template`: a location template one of the mission's slots can pick stands
  # for this place. `text`: the mission's title or description names it.
  SOURCES = %w[template text].freeze

  belongs_to :game_mission
  belongs_to :location

  validates :source, inclusion: {in: SOURCES}
  validates :location_id, uniqueness: {scope: [:game_mission_id, :source]}
end
