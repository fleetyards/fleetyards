# frozen_string_literal: true

FactoryBot.define do
  factory :supporter_contribution do
    sequence(:name) { |n| "Supporter #{n}" }
    amount_cents { 500 }
    currency { "EUR" }
    anonymous { false }
    recurring { false }
    started_at { Date.current }

    trait :anonymous do
      anonymous { true }
    end

    trait :recurring do
      recurring { true }
      ended_at { nil }
    end

    trait :patreon do
      source { "patreon" }
      sequence(:patreon_member_id) { |n| "member-#{n}" }
      recurring { true }
      anonymous { true }
    end

    trait :buymeacoffee do
      source { "buymeacoffee" }
    end

    trait :paypal do
      source { "paypal" }
    end

    trait :kofi do
      source { "kofi" }
      sequence(:kofi_transaction_id) { |n| "kofi-txn-#{n}" }
      recurring { false }
    end
  end
end
