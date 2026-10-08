# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_subscription do
    fleet
    started_at { Date.current }
    granted_via { "manual" }

    trait :seeded do
      granted_via { "contribution" }
      supporter_contribution
    end

    trait :closed do
      ended_at { Date.current }
    end
  end
end
