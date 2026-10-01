FactoryBot.define do
  factory :game_mission_location do
    game_mission
    location
    source { "template" }
  end
end
