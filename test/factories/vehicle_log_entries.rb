# frozen_string_literal: true

FactoryBot.define do
  factory :vehicle_log_entry do
    title { Faker::Lorem.sentence(word_count: 3) }
    body { Faker::Lorem.paragraph }
    logged_at { Time.current }
    vehicle

    trait :public do
      public { true }
    end
  end
end
