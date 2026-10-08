# frozen_string_literal: true

FactoryBot.define do
  factory :inventory do
    association :holder, factory: :user
    sequence(:name) { |n| "#{Faker::Commerce.department(max: 2)} #{n}" }
    description { Faker::Lorem.sentence }

    trait :with_location do
      location { Faker::Space.planet }
    end
  end
end
