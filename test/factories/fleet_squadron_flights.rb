# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_squadron_flight do
    fleet_squadron
    sequence(:name) { |n| "Flight #{n}" }
  end
end
