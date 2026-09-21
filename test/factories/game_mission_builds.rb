# frozen_string_literal: true

FactoryBot.define do
  factory :game_mission_build do
    game_mission factory: [:game_mission, :without_build]
    environment { ScData::Source.environment }
    version { ScData::Source.version }

    sequence(:name) { |n| "Yellow Level Contract: Ambush An Amateur #{n}" }
    kind { "career" }
    org_name { "Foxwell Enforcement" }
    alignment { "lawful" }
    min_standing { "Neutral" }
    max_standing { "Elite Contractor" }
    released { true }
    reward_kinds { ["reputation"] }
  end
end
