# frozen_string_literal: true

FactoryBot.define do
  factory :tour do
    association :created_by, factory: :user
    sequence(:title) { |n| "Tour #{n}" }
    description { Faker::Lorem.sentence }
    starts_at { 1.day.from_now }

    trait :settled do
      status { "settled" }
      settled_at { Time.current }
    end

    trait :cancelled do
      status { "cancelled" }
      cancelled_at { Time.current }
    end
  end
end
