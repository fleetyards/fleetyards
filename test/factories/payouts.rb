# frozen_string_literal: true

FactoryBot.define do
  factory :payout_ledger do
    association :subject, factory: :tour

    trait :for_fleet_event do
      association :subject, factory: :fleet_event
    end

    trait :settled do
      status { "settled" }
      settled_at { Time.current }
    end
  end

  factory :payout_participant do
    payout_ledger
    association :user, factory: :user

    trait :guest do
      user { nil }
      sequence(:name) { |n| "Guest #{n}" }
    end
  end

  factory :payout_entry do
    payout_participant
    payout_ledger { payout_participant.payout_ledger }
    entry_type { "expense" }
    amount { 1000 }
    sequence(:description) { |n| "Entry #{n}" }

    trait :income do
      entry_type { "income" }
    end
  end

  factory :payout_transfer do
    payout_ledger
    association :from_participant, factory: :payout_participant
    association :to_participant, factory: :payout_participant
    amount { 500 }
  end
end
