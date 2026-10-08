# frozen_string_literal: true

FactoryBot.define do
  factory :funding_goal do
    sequence(:title) { |n| "Funding goal ##{n}" }
    amount_cents { 10_000 }
    currency { "EUR" }
    effective_from { Date.current }

    trait :ended do
      ended_at { Date.current }
    end

    trait :server_costs do
      title { "Server costs" }
      description { "VPS and database hosting" }
    end
  end
end
