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
FactoryBot.define do
  factory :game_mission_location do
    game_mission
    location
    source { "template" }
  end
end
