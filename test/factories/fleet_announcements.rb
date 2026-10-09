# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_announcement do
    fleet
    association :author, factory: :user
    body { Faker::Lorem.sentence }
  end
end
