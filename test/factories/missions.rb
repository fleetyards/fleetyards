# frozen_string_literal: true

FactoryBot.define do
  factory :mission do
    fleet
    association :created_by, factory: :user
    sequence(:title) { |n| "Mission #{n}" }
    description { Faker::Lorem.sentence }
    # A mission the fleet has been offered, which is what almost every test
    # means by one. The column defaults to draft for the create button's sake.
    status { Mission::STATUSES[:published] }

    trait :draft do
      status { Mission::STATUSES[:draft] }
    end

    trait :archived do
      archived_at { Time.current }
    end
  end

  factory :mission_team do
    mission
    sequence(:title) { |n| "Team #{n}" }
    description { Faker::Lorem.sentence }
    sequence(:position) { |n| n }
  end

  factory :mission_ship do
    mission_team
    sequence(:position) { |n| n }
    classification { "Combat" }

    trait :strict do
      classification { nil }
      association :model, factory: %i[model in_game]
    end

    trait :ranged do
      classification { "Combat" }
      min_size { "medium" }
    end
  end

  factory :mission_slot do
    title { "Pilot" }
    description { Faker::Lorem.sentence }
    sequence(:position) { |n| n }
    association :slottable, factory: :mission_team

    trait :for_team do
      association :slottable, factory: :mission_team
    end

    trait :for_ship do
      association :slottable, factory: :mission_ship
    end
  end
end
