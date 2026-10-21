# frozen_string_literal: true

FactoryBot.define do
  factory :game_mission_prerequisite do
    build factory: :game_mission_build
    kind { "crime_stat" }
    min { 0 }
    max { 2 }
    sequence(:position) { |n| n }

    trait :completed_missions do
      kind { "completed_missions" }
      min { nil }
      max { nil }
      count { 1 }
    end
  end
end
