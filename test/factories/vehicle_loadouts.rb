# frozen_string_literal: true

FactoryBot.define do
  factory :vehicle_loadout do
    name { Faker::Lorem.word }
    url { "https://erkul.games/loadout/#{SecureRandom.hex(8)}" }
    vehicle { association :vehicle, model: association(:model, production_status: "flight-ready") }

    trait :active do
      active { true }
    end

    trait :fleetyards do
      kind { "fleetyards" }
      url { nil }
    end
  end
end
