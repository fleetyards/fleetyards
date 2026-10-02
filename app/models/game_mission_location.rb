# frozen_string_literal: true

# A place a mission can take place at.
# == Schema Information
#
# Table name: game_mission_locations
#
#  id              :uuid             not null, primary key
#  source          :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  game_mission_id :uuid             not null
#  location_id     :uuid             not null
#
# Indexes
#
#  index_game_mission_locations_on_game_mission_id  (game_mission_id)
#  index_game_mission_locations_on_location_id      (location_id)
#  index_game_mission_locations_uniqueness          (game_mission_id,location_id,source) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (game_mission_id => game_missions.id) ON DELETE => cascade
#  fk_rails_...  (location_id => locations.id) ON DELETE => cascade
#
class GameMissionLocation < ApplicationRecord
  # `template`: a location template one of the mission's slots can pick stands
  # for this place. `text`: the mission's title or description names it.
  SOURCES = %w[template text].freeze

  belongs_to :game_mission
  belongs_to :location

  validates :source, inclusion: {in: SOURCES}
  validates :location_id, uniqueness: {scope: [:game_mission_id, :source]}
end
