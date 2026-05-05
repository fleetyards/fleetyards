# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_event do
    fleet
    association :created_by, factory: :user
    sequence(:title) { |n| "Event #{n}" }
    description { Faker::Lorem.sentence }
    starts_at { 1.day.from_now }
    timezone { "UTC" }
    visibility { "members" }
    category { "other" }

    trait :open do
      status { "open" }
    end

    trait :locked do
      status { "locked" }
    end

    trait :active do
      status { "active" }
    end

    trait :cancelled do
      status { "cancelled" }
    end
  end

  factory :fleet_event_team do
    fleet_event
    sequence(:title) { |n| "Team #{n}" }
    sequence(:position) { |n| n }
  end

  factory :fleet_event_ship do
    fleet_event_team
    sequence(:position) { |n| n }
    classification { "Combat" }

    trait :strict do
      classification { nil }
      association :model, in_game: true
    end
  end

  factory :fleet_event_slot do
    title { "Pilot" }
    sequence(:position) { |n| n }
    association :slottable, factory: :fleet_event_team

    trait :for_team do
      association :slottable, factory: :fleet_event_team
    end

    trait :for_ship do
      association :slottable, factory: :fleet_event_ship
    end
  end

  factory :fleet_event_signup do
    association :fleet_event_slot
    fleet_membership
    status { "confirmed" }
  end
end
