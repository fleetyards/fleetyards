# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_alliance do
    association :requester, factory: :fleet
    association :addressee, factory: :fleet

    trait :accepted do
      aasm_state { "accepted" }
      accepted_at { Time.zone.now }
    end

    trait :declined do
      aasm_state { "declined" }
      declined_at { Time.zone.now }
    end

    trait :ignored do
      aasm_state { "ignored" }
      ignored_at { Time.zone.now }
    end
  end
end
