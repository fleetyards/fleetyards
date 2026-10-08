# frozen_string_literal: true

FactoryBot.define do
  factory :vehicle_loadout do
    name { Faker::Lorem.word }
    url { "https://erkul.games/loadout/#{SecureRandom.hex(8)}" }
    vehicle

    trait :active do
      active { true }
    end
  end
end
