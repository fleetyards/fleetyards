# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_squadron_flight do
    fleet_squadron { association :fleet_squadron, flights_enabled: true }
    sequence(:name) { |n| "Flight #{n}" }
  end
end
